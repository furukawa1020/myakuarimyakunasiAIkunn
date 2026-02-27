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

      final topFactors = _buildFactors(features);
      final graph      = _buildGraph(topFactors, loveScore);
      final cfs        = _buildCounterfactuals(loveScore);
      final actions    = _generateActions(label);
      final script     = _generateScript(label, loveScore, topFactors);

      return InferenceResult(
        label: label,
        labelText: label.text,
        loveScore: loveScore,
        confidence: confidence,
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

    final initiative   = initiativeMap[input.initiative] ?? 5.0;
    final concreteness = concreteMap[input.concreteness] ?? 5.0;
    final continuation = continueMap[input.continuation] ?? 5.0;
    final freqVal      = contactMap[(input.contactFrequency - 1).clamp(0, 4)];

    // Speed Dating特徴空間への変換
    final attrO  = (initiative + concreteness) / 2.0;         // 魅力度代理
    final sincO  = continuation;                                // 誠実さ代理
    const intelO = 6.5;                                         // 知性（固定中間値）
    final funO   = freqVal;                                     // 楽しさ代理
    final sharO  = input.where.contains('趣味') ? 8.0
                 : input.where.contains('職場') ? 5.0 : 6.0;   // 共通趣味代理
    final likeO  = (continuation + initiative) / 2.0;          // 好感度代理
    final probO  = concreteness * 10.0;                         // また会いたい確率
    final metO   = (input.who.contains('職場') ||
                    input.who.contains('友達') ||
                    input.who.contains('同僚')) ? 1.0 : 0.5;   // 以前に会ったか
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

  String _generateScript(Label label, int score, List<Factor> factors) {
    String s = '判定は${label.text}！スコアは$score点なのだ。';
    if (factors.isNotEmpty) s += '決め手は「${factors.first.title}」なのだ。';
    s += '※コロンビア大学の速習デートデータをもとにした推論なのだ！';
    return s;
  }
}
