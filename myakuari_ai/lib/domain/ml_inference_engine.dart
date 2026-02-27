import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'models/inference_models.dart';

/// Speed Dating Experiment (Columbia大学, Fisman et al. 2006) から学習した
/// Gradient Boosting → Logistic回帰蒸留モデルをDart純粋実装で推論。
///
/// モデルの入力は10次元のfloatベクトル。
/// Dartでsoftmax付き行列演算を実行してクラス確率を得る。
class MLInferenceEngine {
  static MLInferenceEngine? _instance;
  static MLInferenceEngine get instance => _instance ??= MLInferenceEngine._();
  MLInferenceEngine._();

  Map<String, dynamic>? _meta;
  bool _loaded = false;

  /// アセットからモデルメタデータをロード
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/ml/feature_metadata.json');
      _meta = jsonDecode(raw) as Map<String, dynamic>;
      _loaded = true;
    } catch (e) {
      // モデルが読み込めない場合はルールベースにフォールバック
      _loaded = false;
    }
  }

  bool get isLoaded => _loaded;

  /// InferenceInput → MLで推論 → InferenceResult
  InferenceResult? analyze(InferenceInput input) {
    if (!_loaded || _meta == null) return null;

    try {
      final features = _buildFeatureVector(input);
      final probs = _softmax(_linearPredict(features));

      final labelIdx = probs.indexed.reduce((a, b) => a.$2 >= b.$2 ? a : b).$1;
      final label = labelIdx == 2
          ? Label.like
          : labelIdx == 0
              ? Label.nope
              : Label.neutral;

      final loveScore = (probs[2] * 100).round().clamp(0, 100);
      final confidence = probs[labelIdx].clamp(0.0, 1.0);

      final topFactors = _buildFactors(features, probs);
      final graph      = _buildGraph(topFactors, loveScore);
      final cfs        = _buildCounterfactuals(features, probs, loveScore);
      final actions    = _generateActions(label, input);
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
    } catch (e) {
      return null;
    }
  }

  // ── 特徴量ベクトル構築 ──────────────────────────────────────────────────
  // アプリの5W1H入力をモデルの10次元ベクトルに変換
  // Speed Datingの特徴空間に合わせてスケールを調整
  List<double> _buildFeatureVector(InferenceInput input) {
    // 各値は 1〜10 または 0〜100 のスケール
    final initiative = <String, double>{'相手': 9.0, '半々': 6.0, '自分': 3.0};
    final concreteness = <String, double>{'YES': 9.0, '未定': 6.0, '止まる': 3.0};
    final continuation = <String, double>{'続いてる': 8.0, '普通': 6.0, '途切れた': 2.0};
    final contactMap = [2.0, 4.0, 6.0, 8.0, 10.0];

    // attr_o  : 魅力度 → 主導権 + 約束の具体化から推定
    final attrO = ((initiative[input.initiative] ?? 5.0) +
            (concreteness[input.concreteness] ?? 5.0)) /
        2.0;

    // sinc_o  : 誠実さ → 継続性から推定
    final sincO = continuation[input.continuation] ?? 5.0;

    // intel_o : 知性/会話 → 固定中間値（入力なし）
    const intelO = 6.5;

    // fun_o   : 楽しさ → 連絡頻度から
    final freqIdx = (input.contactFrequency - 1).clamp(0, 4);
    final funO = contactMap[freqIdx];

    // shar_o  : 共通の趣味 → Whereテキストから簡易推定
    final sharO = input.where.contains('趣味') || input.where.contains('共通')
        ? 8.0
        : input.where.contains('仕事') || input.where.contains('職場')
            ? 5.0
            : 6.0;

    // like_o  : 好感度 → 継続+主導から推定
    final likeO = ((continuation[input.continuation] ?? 5.0) +
            (initiative[input.initiative] ?? 5.0)) /
        2.0;

    // prob_o  : また会いたい確率 (0-100) → 具体化×10
    final probO = (concreteness[input.concreteness] ?? 5.0) * 10.0;

    // met_o   : 以前に会ったか → っぱり判定困難なので知人=1, 初対面=0
    final metO = input.who.contains('職場') ||
            input.who.contains('同僚') ||
            input.who.contains('友達') ||
            input.who.contains('クラス')
        ? 1.0
        : 0.5;

    // imprace / imprelig : こだわり度 → 低=5 (中立)
    const impraceO = 4.0;
    const imprelO  = 3.0;

    return [attrO, sincO, intelO, funO, sharO, likeO, probO, metO, impraceO, imprelO];
  }

  // ── スケーリング + 線形予測 ────────────────────────────────────────────
  List<double> _linearPredict(List<double> raw) {
    final mean = (_meta!['scaler_mean'] as List).cast<double>();
    final std  = (_meta!['scaler_std']  as List).cast<double>();
    final coef = (_meta!['lr_coef'] as List)
        .map((row) => (row as List).cast<double>())
        .toList();
    final bias = (_meta!['lr_bias'] as List).cast<double>();

    // 標準化
    final scaled = List.generate(raw.length, (i) => (raw[i] - mean[i]) / std[i]);

    // 行列演算: logits = W^T * x + b
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
    final maxL = logits.reduce(max);
    final exp  = logits.map((x) => math.exp(x - maxL)).toList();
    final sum  = exp.reduce((a, b) => a + b);
    return exp.map((e) => e / sum).toList();
  }

  // ── 根拠生成 ─────────────────────────────────────────────────────────
  List<Factor> _buildFactors(List<double> features, List<double> probs) {
    final featNames = (_meta!['features'] as List).cast<String>();
    final importance = _meta!['feature_importance'] as Map<String, dynamic>;

    final factors = <Factor>[];
    for (int i = 0; i < features.length && i < featNames.length; i++) {
      final nm  = featNames[i];
      final imp = (importance[nm] as num).toDouble();
      final val = features[i];
      final mid = 5.5;
      final impact = ((val - mid) * imp * 30).round();
      final desc = _meta!['feature_description'][nm] as String? ?? nm;

      factors.add(Factor(
        id: 'f$i',
        title: desc.split('(').first.trim(),
        description: '$desc: ${val.toStringAsFixed(1)}',
        scoreImpact: impact,
        reason: '【ML重要度 ${(imp * 100).toStringAsFixed(0)}%】',
      ));
    }

    factors.sort((a, b) => b.scoreImpact.abs().compareTo(a.scoreImpact.abs()));
    return factors.take(5).toList();
  }

  GraphData _buildGraph(List<Factor> factors, int score) {
    final nodes = <GraphNode>[
      GraphNode(label: '判定\n($score点)', scoreValue: score, isMain: true),
    ];
    final edges = <GraphEdge>[];
    for (int i = 0; i < factors.length; i++) {
      nodes.add(GraphNode(label: factors[i].title, scoreValue: factors[i].scoreImpact));
      edges.add(GraphEdge(sourceIndex: i + 1, targetIndex: 0, weight: factors[i].scoreImpact));
    }
    return GraphData(nodes: nodes, edges: edges);
  }

  List<Counterfactual> _buildCounterfactuals(
      List<double> features, List<double> probs, int score) {
    final result = <Counterfactual>[];
    if (score < 65) {
      result.add(Counterfactual(
        description: 'もし相手からの誘いがあれば',
        newScore: (score + 15).clamp(0, 100),
        isImprovement: true,
      ));
    }
    if (score > 40) {
      result.add(Counterfactual(
        description: 'もし連絡が途切れてしまえば',
        newScore: (score - 20).clamp(0, 100),
        isImprovement: false,
      ));
    }
    return result;
  }

  List<String> _generateActions(Label label, InferenceInput input) {
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
          '【攻め】(非推奨) 事務的な軽い質問を1つだけ投げる',
          '【様子見】SNSの更新だけ見て直接の接触は避ける',
          '【撤退】きっぱり1ヶ月は一切連絡しない（自分のため）',
        ];
    }
  }

  String _generateScript(Label label, int score, List<Factor> factors) {
    String s = '判定は${label.text}！スコアは$score点なのだ。';
    if (factors.isNotEmpty) {
      s += '決め手は「${factors.first.title}」なのだ。';
    }
    s += '※コロンビア大学の速習デートデータをもとにした推論なのだ！参考程度にしてほしいのだ。';
    return s;
  }
}

// dart:math をimport忘れ防止
// ignore: library_prefixes
import 'dart:math' as math;
