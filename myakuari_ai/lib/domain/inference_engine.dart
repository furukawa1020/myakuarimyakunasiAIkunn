import 'dart:math';

import 'models/inference_models.dart';

class InferenceEngine {
  static const int _baseScore = 50;
  static const List<String> _dangerKeywords = [
    '尾行', '監視', '特定', '家に行く', '待ち伏せ', '殺す', '殴る', '死', 'ストーキング', 'ハッキング'
  ];

  /// 入力文字列に危険なキーワードが含まれているかチェックし安全フィルタにかける
  static String? checkSafety(InferenceInput input) {
    final allText = '${input.what} ${input.why} ${input.how} ${input.who} ${input.where}';
    for (final kw in _dangerKeywords) {
      if (allText.contains(kw)) {
        return '【安全警告】監視、尾行、脅迫などの行為を助長することはできません。入力を修正してください。';
      }
    }
    return null;
  }

  /// メインの推論処理
  static InferenceResult analyze(InferenceInput input) {
    // 1. 特徴量（Factors）の抽出
    List<Factor> factors = _extractFactors(input);

    // 2. 基本スコア計算と証拠度補正
    int rawScore = _baseScore;
    for (var f in factors) {
      rawScore += f.scoreImpact;
    }
    
    // 確証度合（Evidence）によるスコアの縮退（50へ寄せる）
    // 証拠度1の場合、(score - 50) * 0.6 になるようにする
    double evidenceMultiplier = 0.6 + (input.evidenceLevel - 1) * 0.1; // 1->0.6, 5->1.0
    int adjustedScore = 50 + ((rawScore - 50) * evidenceMultiplier).round();
    
    // クリップ
    int finalScore = max(0, min(100, adjustedScore));

    // 3. 判定ラベルの計算
    Label label = _determineLabel(finalScore);

    // 4. 信頼度 (Confidence)
    double confidence = _calculateConfidence(input);

    // 5. 上位要因の抽出 (Top 5)
    factors.sort((a, b) => b.scoreImpact.abs().compareTo(a.scoreImpact.abs()));
    List<Factor> topFactors = factors.take(5).toList();

    // 6. 推論グラフ生成
    GraphData graph = _buildGraph(topFactors, finalScore);

    // 7. 反事実 (Counterfactuals)生成
    List<Counterfactual> counterfactuals = _buildCounterfactuals(factors, finalScore, evidenceMultiplier);

    // 8. 次の一手 (ActionPlanner)
    List<String> nextActions = _generateNextActions(label, input);

    // 9. 音声スクリプト (SpokenScript)
    String script = _generateSpokenScript(label, finalScore, topFactors.isNotEmpty ? topFactors.first : null, nextActions.first);

    return InferenceResult(
      label: label,
      labelText: label.text,
      loveScore: finalScore,
      confidence: confidence,
      topFactors: topFactors,
      graph: graph,
      counterfactuals: counterfactuals,
      nextActions: nextActions,
      spokenScript: script,
    );
  }

  static List<Factor> _extractFactors(InferenceInput input) {
    List<Factor> factors = [];

    // 主導権
    if (input.initiative == '相手') {
      factors.add(Factor(id: 'f1', title: '相手主導の誘い', description: '相手からアクションや誘いがある', scoreImpact: 18, reason: '【行動】相手から動いている'));
    } else if (input.initiative == '自分') {
      factors.add(Factor(id: 'f2', title: '自分主導の誘い', description: '常に自分から動かないと何も起きない', scoreImpact: -10, reason: '【行動】相手の受動性が高い'));
    }

    // 具体化
    if (input.concreteness == 'YES') {
      factors.add(Factor(id: 'f3', title: '具体的な約束', description: '日程や内容が具体化している', scoreImpact: 20, reason: '【確定】「会う」確度が高い'));
    } else if (input.concreteness == '止まる') {
      factors.add(Factor(id: 'f4', title: '具体化回避', description: '「またね」「そのうち」で止まる', scoreImpact: -15, reason: '【停滞】コミットを避けている'));
    }

    // 連絡頻度
    if (input.contactFrequency >= 4) {
      factors.add(Factor(id: 'f5', title: '連絡頻度 高', description: '頻繁に連絡を取り合っている', scoreImpact: 10, reason: '【接触】マインドシェア確保'));
    } else if (input.contactFrequency <= 2) {
      factors.add(Factor(id: 'f6', title: '連絡頻度 低', description: '返信が遅い、または反応が薄い', scoreImpact: -12, reason: '【接触】優先度が低い可能性'));
    }

    // 継続性
    if (input.continuation == '続いてる') {
      factors.add(Factor(id: 'f7', title: '継続的な関係', description: 'やりとりが切れずに継続している', scoreImpact: 14, reason: '【持続】関係性の維持'));
    } else if (input.continuation == '途切れた') {
      factors.add(Factor(id: 'f8', title: '音信不通/途切れ', description: '連絡が途絶えている期間がある', scoreImpact: -25, reason: '【断絶】関心の喪失'));
    }

    // フリーテキストの簡易キーワードマッチ(ダミー的に機能させる)
    if (input.where.contains('飲み') || input.where.contains('居酒屋')) {
      factors.add(Factor(id: 'f9', title: '飲みの場依存', description: 'お酒の席での出来事のウェイトが高い', scoreImpact: -6, reason: '【文脈】酔いによるノイズ'));
    }
    if (input.who.contains('友達') || input.how.contains('みんなで')) {
      factors.add(Factor(id: 'f10', title: '友達アピール', description: '「みんなで」など友達の枠を強調された', scoreImpact: -8, reason: '【関係】グループの1人扱い'));
    }
    if (input.what.contains('質問') || input.how.contains('聞かれた')) {
      factors.add(Factor(id: 'f11', title: '相手からの質問', description: 'あなたに対して質問をしてくる', scoreImpact: 8, reason: '【関心】パーソナルな興味'));
    }

    return factors;
  }

  static Label _determineLabel(int score) {
    if (score <= 39) return Label.nope;
    if (score <= 64) return Label.neutral;
    return Label.like;
  }

  static double _calculateConfidence(InferenceInput input) {
    double conf = 1.0;
    // Completeness penalty
    if (input.what.isEmpty || input.why.isEmpty || input.how.isEmpty) {
      conf -= 0.3;
    }
    // Evidence penalty
    if (input.evidenceLevel <= 2) {
      conf -= 0.2;
    }
    // Contradiction checks
    if (input.initiative == '相手' && input.continuation == '途切れた') {
      conf -= 0.2; // 矛盾
    }
    return max(0.1, conf);
  }

  static GraphData _buildGraph(List<Factor> topFactors, int finalScore) {
    List<GraphNode> nodes = [];
    List<GraphEdge> edges = [];

    // 中心ノード (Result)
    nodes.add(GraphNode(label: '判定\n($finalScore点)', scoreValue: finalScore, isMain: true));
    int resultNodeIndex = 0;

    // 要因ノードとエッジ
    for (int i = 0; i < topFactors.length; i++) {
      nodes.add(GraphNode(label: topFactors[i].title, scoreValue: topFactors[i].scoreImpact));
      int nodeIndex = nodes.length - 1;
      edges.add(GraphEdge(sourceIndex: nodeIndex, targetIndex: resultNodeIndex, weight: topFactors[i].scoreImpact));
    }

    return GraphData(nodes: nodes, edges: edges);
  }

  static List<Counterfactual> _buildCounterfactuals(List<Factor> activeFactors, int currentScore, double evidenceMultiplier) {
    List<Counterfactual> cfList = [];
    
    // 最も悪影響の要因を探す(マイナスが一番大きいもの)
    var worstFactor = activeFactors.where((f) => f.scoreImpact < 0)
        .fold<Factor?>(null, (prev, element) => prev == null ? element : (prev.scoreImpact < element.scoreImpact ? prev : element));
        
    if (worstFactor != null) {
      // これが無かったら？（改善）
      int newScore = currentScore - (worstFactor.scoreImpact * evidenceMultiplier).round();
      newScore = max(0, min(100, newScore));
      cfList.add(Counterfactual(
        description: 'もし「${worstFactor.title}」が解消されれば',
        newScore: newScore,
        isImprovement: true,
      ));
    } else {
      // マイナス要因がない場合はプラス要因を追加するシミュレーション
      int newScore = currentScore + (15 * evidenceMultiplier).round();
      cfList.add(Counterfactual(
        description: 'もし「具体的なデートの約束」ができれば',
        newScore: max(0, min(100, newScore)),
        isImprovement: true,
      ));
    }

    // 最も良い影響の要因を探す(プラスが一番大きいもの)
    var bestFactor = activeFactors.where((f) => f.scoreImpact > 0)
        .fold<Factor?>(null, (prev, element) => prev == null ? element : (prev.scoreImpact > element.scoreImpact ? prev : element));
        
    if (bestFactor != null) {
      // これが無かったら？（悪化）
      int newScore = currentScore - (bestFactor.scoreImpact * evidenceMultiplier).round();
      newScore = max(0, min(100, newScore));
      cfList.add(Counterfactual(
        description: 'もし「${bestFactor.title}」が勘違いだった場合',
        newScore: newScore,
        isImprovement: false,
      ));
    }

    return cfList;
  }

  static List<String> _generateNextActions(Label label, InferenceInput input) {
    // 攻め / 様子見 / 撤退
    switch (label) {
      case Label.like:
        return [
          '【攻め】直球で「〇〇行かない？」と日時指定で誘う',
          '【様子見】相手の休日の予定を軽く聞いてみる',
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
          '【攻め】(非推奨) 業務連絡や事務的な軽い質問を1つだけ投げる',
          '【様子見】SNSの更新だけはチェックし、直接の接触は避ける',
          '【撤退】きっぱり1ヶ月は一切連絡しない（自分のため）',
        ];
    }
  }

  static String _generateSpokenScript(Label label, int score, Factor? topFactor, String action) {
    String out = '判定は${label.text}！スコアは$score点なのだ。';
    if (topFactor != null) {
      out += '決め手は「${topFactor.title}」の影響が大きいのだ。';
    }
    out += '次の一手のオススメは、$action、なのだ！';
    out += '※あくまで独自の推論による結論なのだ。参考程度にお願いするのだ。';
    return out;
  }
}
