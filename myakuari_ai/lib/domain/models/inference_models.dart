enum Label {
  like,
  neutral,
  nope,
}

extension LabelExtension on Label {
  String get text {
    switch (this) {
      case Label.like:
        return '脈アリ';
      case Label.neutral:
        return '五分';
      case Label.nope:
        return '脈ナシ';
    }
  }
}

class InferenceInput {
  // 5W1H
  final String who; // 相手カテゴリ + 関係性
  final String what; // 出来事
  final String when; // 時期 (今日/昨日/今週/先週/それ以前)
  final String where; // 文脈 (対面/LINE/通話/飲み/学校/職場/その他)
  final String why; // 自分の解釈
  final String how; // 流れ

  // Extra params
  final int contactFrequency; // 1-5
  final String initiative; // 相手/自分/半々
  final String concreteness; // YES/NO/止まる
  final String continuation; // 続いてる/途切れた/未実施
  final int evidenceLevel; // 1-5

  InferenceInput({
    required this.who,
    required this.what,
    required this.when,
    required this.where,
    required this.why,
    required this.how,
    required this.contactFrequency,
    required this.initiative,
    required this.concreteness,
    required this.continuation,
    required this.evidenceLevel,
  });

  bool get isComplete =>
      who.isNotEmpty && what.isNotEmpty && when.isNotEmpty && where.isNotEmpty && why.isNotEmpty && how.isNotEmpty;
}

class Factor {
  final String id;
  final String title;
  final String description;
  final int scoreImpact;
  final String reason;

  Factor({
    required this.id,
    required this.title,
    required this.description,
    required this.scoreImpact,
    required this.reason,
  });
}

class Counterfactual {
  final String description;
  final int newScore;
  final bool isImprovement;

  Counterfactual({
    required this.description,
    required this.newScore,
    required this.isImprovement,
  });
}

class GraphNode {
  final String label;
  final int? scoreValue;
  final bool isMain;
  GraphNode({required this.label, this.scoreValue, this.isMain = false});
}

class GraphEdge {
  final int sourceIndex;
  final int targetIndex;
  final int weight;
  GraphEdge({required this.sourceIndex, required this.targetIndex, required this.weight});
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  GraphData({required this.nodes, required this.edges});
}

class InferenceResult {
  final Label label;
  final String labelText;
  final int loveScore;
  final double confidence;
  final List<Factor> topFactors;
  final GraphData graph;
  final List<Counterfactual> counterfactuals;
  final List<String> nextActions; // [0]: 攻め, [1]: 様子見, [2]: 撤退
  final String spokenScript;

  InferenceResult({
    required this.label,
    required this.labelText,
    required this.loveScore,
    required this.confidence,
    required this.topFactors,
    required this.graph,
    required this.counterfactuals,
    required this.nextActions,
    required this.spokenScript,
  });
}
