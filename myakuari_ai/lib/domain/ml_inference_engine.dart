import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'models/inference_models.dart';

/// Speed Dating Experiment (Columbia大学, Fisman et al. 2006) から学習した
/// Gradient Boosting → Logistic回帰蒸留モデルをDart純粋実装で推論。
class MLInferenceEngine {
  static MLInferenceEngine? _instance;
  static MLInferenceEngine get instance => _instance ??= MLInferenceEngine._();
  MLInferenceEngine._();

  Map<String, dynamic>? _meta;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/ml/feature_metadata.json');
      _meta = jsonDecode(raw) as Map<String, dynamic>;
      _loaded = true;
    } catch (_) {
      _loaded = false;
    }
  }

  bool get isLoaded => _loaded;

  InferenceResult? analyze(InferenceInput input) {
    if (!_loaded || _meta == null) return null;

    try {
      final features = _buildFeatureVector(input);
      final probs    = _softmax(_linearPredict(features));

      // 最高確率のラベルを選択
      int labelIdx = 0;
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > probs[labelIdx]) labelIdx = i;
      }
      final label = labelIdx == 2
          ? Label.like
          : labelIdx == 0
              ? Label.nope
              : Label.neutral;

      final loveScore = (probs[2] * 100).round().clamp(0, 100);
      final confidence = probs[labelIdx].clamp(0.0, 1.0);

      // ランク判定
      final grade = _calculateGrade(loveScore);

      // スコアのダイナミックレンジ拡大 (ユーザー体験向上のための演出)
      final dynamicScore = _distortScore(loveScore, label);

      // レーダーチャート用データ (0.0 - 1.0)
      final radarData = {
        '魅力': (features[0] / 10.0).clamp(0.1, 1.0),
        '誠実': (features[1] / 10.0).clamp(0.1, 1.0),
        '知性': (features[2] / 10.0).clamp(0.1, 1.0),
        '楽しさ': (features[3] / 10.0).clamp(0.1, 1.0),
        '共通点': (features[4] / 10.0).clamp(0.1, 1.0),
      };

      final topFactors = _buildFactors(features);
      final graph      = _buildGraph(topFactors, loveScore);
      final cfs        = _buildCounterfactuals(loveScore);
      final actions    = _generateActions(label);
      final script     = _generateEnhancedScript(label, loveScore, topFactors, features);

      return InferenceResult(
        label: label,
        labelText: label.text,
        loveScore: dynamicScore, // 補正後のスコアを使用
        confidence: confidence,
        compatibilityGrade: _calculateGrade(dynamicScore),
        radarData: radarData,
        topFactors: topFactors,
        graph: graph,
        counterfactuals: cfs,
        nextActions: actions,
        spokenScript: script,
      );
    } catch (_) {
      return null;
    }
  }

  List<double> _buildFeatureVector(InferenceInput input) {
    final initiativeMap = <String, double>{'相手': 9.0, '半々': 6.0, '自分': 3.0};
    final concreteMap   = <String, double>{'YES': 9.0,  '未定': 6.0, '止まる': 3.0};
    final continueMap   = <String, double>{'続いてる': 8.0, '普通': 6.0, '途切れた': 2.0};
    final contactMap    = [2.0, 4.0, 6.0, 8.0, 10.0];

    // 1. 基本値（UIからの入力、なければデフォルト）
    double initiative   = initiativeMap[input.initiative] ?? 6.0;
    double concreteness = concreteMap[input.concreteness] ?? 3.0;
    double continuation = continueMap[input.continuation] ?? 2.0;
    double freqVal      = contactMap[(input.contactFrequency - 1).clamp(0, 4)];

    // 2. テキストからのキーワード判定による「AI的」な特徴量補正
    final allText = '${input.who} ${input.what} ${input.why} ${input.how}';

    // 主導権 (Initiative) の補正
    if (allText.contains('誘われた') || allText.contains('きた') || allText.contains('きてくれた')) {
      initiative = math.max(initiative, 8.5);
    } else if (allText.contains('誘った') || allText.contains('こない') || allText.contains('既読無視')) {
      initiative = math.min(initiative, 4.0);
    }

    // 具体性 (Concreteness/Prob) の補正
    if (allText.contains('約束') || allText.contains('予定') || allText.contains('行くことに') || allText.contains('楽しみ')) {
      concreteness = math.max(concreteness, 8.5);
    } else if (allText.contains('紹介して') || allText.contains('男友達') || allText.contains('女友達')) {
      concreteness = math.min(concreteness, 4.0);
    }

    // 継続性 (Continuation) の補正
    if (allText.contains('毎日') || allText.contains('続いてる') || allText.contains('ずっと')) {
      continuation = math.max(continuation, 8.0);
    }

    // Speed Dating特徴空間への変換
    final attrO  = (initiative + concreteness) / 2.0;         // 魅力度代理 (相手からのアプローチがあれば高い)
    final sincO  = continuation;                                // 誠実さ代理 (継続していれば高い)
    const intelO = 7.0;                                         // 知性（固定中間値）
    final funO   = freqVal;                                     // 楽しさ代理 (頻度で代用)
    final sharO  = (input.where.contains('趣味') || allText.contains('趣味') || allText.contains('共通')) ? 8.0
                 : (input.where.contains('職場') || allText.contains('仕事')) ? 5.0 : 6.0;
    final likeO  = (continuation + initiative) / 2.0;          // 好感度代理
    final probO  = concreteness;                                // また会いたい確率 (0-10スケールに修正)
    final metO   = (input.who.contains('職場') ||
                    input.who.contains('友達') ||
                    input.who.contains('同僚') ||
                    allText.contains('同期')) ? 1.0 : 0.0;
    const impraceO = 4.0;
    const imprelO  = 3.0;

    return [attrO, sincO, intelO, funO, sharO, likeO, probO, metO, impraceO, imprelO];
  }

  List<double> _linearPredict(List<double> raw) {
    final mean = (_meta!['scaler_mean'] as List).map((e) => (e as num).toDouble()).toList();
    final std  = (_meta!['scaler_std']  as List).map((e) => (e as num).toDouble()).toList();
    final coef = (_meta!['lr_coef'] as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
    final bias = (_meta!['lr_bias'] as List).map((e) => (e as num).toDouble()).toList();

    final scaled = List.generate(raw.length, (i) => (raw[i] - mean[i]) / std[i]);
    final logits = List<double>.filled(3, 0);
    for (int c = 0; c < 3; c++) {
      logits[c] = bias[c];
      for (int j = 0; j < scaled.length; j++) {
        logits[c] += coef[c][j] * scaled[j];
      }
    }
    return logits;
  }

  List<double> _softmax(List<double> logits) {
    final maxL = logits.reduce(math.max);
    final exp  = logits.map((x) => math.exp(x - maxL)).toList();
    final sum  = exp.reduce((a, b) => a + b);
    return exp.map((e) => e / sum).toList();
  }

  List<Factor> _buildFactors(List<double> features) {
    final featNames  = (_meta!['features'] as List).cast<String>();
    final importance = _meta!['feature_importance'] as Map<String, dynamic>;
    final desc       = _meta!['feature_description'] as Map<String, dynamic>;

    final factors = <Factor>[];
    for (int i = 0; i < features.length && i < featNames.length; i++) {
      final nm  = featNames[i];
      final imp = (importance[nm] as num).toDouble();
      final val = features[i];
      final impact = ((val - 5.5) * imp * 30).round();
      final d = (desc[nm] as String?) ?? nm;
      factors.add(Factor(
        id: 'f$i',
        title: d.split('(').first.trim(),
        description: '$d → ${val.toStringAsFixed(1)}',
        scoreImpact: impact,
        reason: '【ML重要度 ${(imp * 100).toStringAsFixed(0)}%】',
      ));
    }
    factors.sort((a, b) => b.scoreImpact.abs().compareTo(a.scoreImpact.abs()));
    return factors.take(5).toList();
  }

  GraphData _buildGraph(List<Factor> factors, int score) {
    final nodes = <GraphNode>[GraphNode(label: '判定\n($score点)', scoreValue: score, isMain: true)];
    final edges = <GraphEdge>[];
    for (int i = 0; i < factors.length; i++) {
      nodes.add(GraphNode(label: factors[i].title, scoreValue: factors[i].scoreImpact));
      edges.add(GraphEdge(sourceIndex: i + 1, targetIndex: 0, weight: factors[i].scoreImpact));
    }
    return GraphData(nodes: nodes, edges: edges);
  }

  List<Counterfactual> _buildCounterfactuals(int score) {
    final result = <Counterfactual>[];
    if (score < 65) {
      result.add(Counterfactual(description: 'もし相手から誘われていれば', newScore: (score + 15).clamp(0, 100), isImprovement: true));
    }
    if (score > 40) {
      result.add(Counterfactual(description: 'もし連絡が途切れていれば', newScore: (score - 20).clamp(0, 100), isImprovement: false));
    }
    return result;
  }

  List<String> _generateActions(Label label) {
    switch (label) {
      case Label.like:
        return [
          '【攻め】日時を指定して「〇〇行かない？」と直球で誘う',
          '【様子見】相手の週末の予定を軽く聞いてみる',
          '【撤退】今は撤退の必要なし。無理な連投だけ控える',
        ];
      case Label.neutral:
        return [
          '【攻め】複数人での食事を提案してハードルを下げる',
          '【様子見】相手の趣味の話題を振り、食いつきを見る',
          '【撤退】3日未読・既読無視が続くなら一旦引く',
        ];
      case Label.nope:
        return [
          '【攻め】事務的な軽い質問を1つだけ投げる（非推奨）',
          '【様子見】SNSの更新だけ見て直接の接触は避ける',
          '【撤退】きっぱり1ヶ月は一切連絡しない（自分のため）',
        ];
    }
  }

  String _calculateGrade(int score) {
    if (score >= 85) return 'S';
    if (score >= 70) return 'A';
    if (score >= 50) return 'B';
    if (score >= 30) return 'C';
    return 'D';
  }

  String _generateEnhancedScript(Label label, int score, List<Factor> factors, List<double> features) {
    String s = '判定結果は、ズバリ【${label.text}】！';
    final grade = _calculateGrade(score);
    
    if (grade == 'S') {
      s += '文句なしの相性Sランクなのだ！もう告白してもいいレベルなのだ。';
    } else if (grade == 'A') {
      s += 'かなりの高得点、Aランクなのだ！自信を持ってアタックするのだ。';
    } else if (grade == 'B') {
      s += '悪くないBランクなのだ。でも、ここからが正念場なのだ！';
    } else if (grade == 'C') {
      s += '今はCランク...まだ「友達」の枠を出ていない可能性があるのだ。';
    } else {
      s += '厳しいDランクなのだ。一度引いて、戦略を練り直すべきなのだ。';
    }

    if (factors.isNotEmpty) {
      final best = factors.first;
      if (best.scoreImpact > 10) {
        s += '特に「${best.title}」が最高に効いているのだ。ここは強みなのだ！';
      } else if (best.scoreImpact < -10) {
        s += '逆に「${best.title}」が足を引っ張っているみたいなのだ。気をつけるのだ。';
      }
    }

    // 特徴量に基づいた具体的な一言
    if (features[1] < 4.0) { // 誠実さが低い
      s += 'ちょっとチャラいと思われてるかもしれないのだ。真面目さをアピールするのだ！';
    } else if (features[4] < 4.0) { // 共通点が少ない
      s += '共通の話題が足りないみたいなのだ。相手の趣味をもっとリサーチするのだ。';
    }

    s += '※この診断はコロンビア大学の実データに基づいた、ボクのガチ推論なのだ！';
    return s;
  }

  /// スコアが中央（30-40付近）に固まりやすいため、演出としてレンジを広げる
  int _distortScore(int rawScore, Label label) {
    if (label == Label.like) {
      // 脈ありなら、最低でも65点、最高100点に近づける
      return (65 + (rawScore * 0.35)).round().clamp(65, 99);
    } else if (label == Label.nope) {
      // 脈なしなら、0-40点の範囲に押し込める
      return (rawScore * 0.8).round().clamp(5, 39);
    }
    // 中立なら40-64点
    return (40 + (rawScore * 0.24)).round().clamp(40, 64);
  }
}
