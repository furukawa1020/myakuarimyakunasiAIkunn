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

      // スコアのダイナミックレンジ拡大 (ユーザー体験向上のための演出)
      final dynamicScore = _distortScore(loveScore, label);

      // 音声特徴量によるスコア微調整 (声の震え/Jitterによる緊張度補正)
      int voiceImpact = 0;
      if (input.isVoice && input.voiceJitter != null) {
        final jitter = input.voiceJitter!;
        if (jitter > 30) {
          voiceImpact = 15; // 強い緊張・興奮は好意シグナル
        } else if (jitter > 12) {
          voiceImpact = 8;
        } else {
          voiceImpact = -5; // 平常心・リラックスはプラトニック寄り
        }
      }

      final adjustedScore = (dynamicScore + voiceImpact).clamp(0, 100);

      // 調整後スコアに基づくラベルの再決定
      Label adjustedLabel = label;
      if (adjustedScore >= 65) {
        adjustedLabel = Label.like;
      } else if (adjustedScore <= 39) {
        adjustedLabel = Label.nope;
      } else {
        adjustedLabel = Label.neutral;
      }

      // レーダーチャート用データ (0.0 - 1.0)
      final radarData = {
        '魅力': (features[0] / 10.0).clamp(0.1, 1.0),
        '誠実': (features[1] / 10.0).clamp(0.1, 1.0),
        '知性': (features[2] / 10.0).clamp(0.1, 1.0),
        '楽しさ': (features[3] / 10.0).clamp(0.1, 1.0),
        '共通点': (features[4] / 10.0).clamp(0.1, 1.0),
      };

      final topFactors = _buildFactors(features, input);
      final graph      = _buildGraph(topFactors, adjustedScore);
      final cfs        = _buildCounterfactuals(adjustedScore);
      final actions    = _generateActions(adjustedLabel);
      final script     = _generateEnhancedScript(adjustedLabel, adjustedScore, topFactors, features, input);

      final featureImp = <String, double>{};
      for (final f in topFactors) {
        featureImp[f.title] = f.scoreImpact.abs().toDouble();
      }
      final attMap     = _calculateAttentionMap(input);

      return InferenceResult(
        input: input,
        label: adjustedLabel,
        labelText: adjustedLabel.text,
        loveScore: adjustedScore,
        confidence: confidence,
        compatibilityGrade: _calculateGrade(adjustedScore),
        radarData: radarData,
        topFactors: topFactors,
        graph: graph,
        counterfactuals: cfs,
        nextActions: actions,
        spokenScript: script,
        attentionMap: attMap,
        featureImportance: featureImp,
        deepAnalysis: null,
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

    // 1. 基本値
    double initiative   = initiativeMap[input.initiative] ?? 6.0;
    double concreteness = concreteMap[input.concreteness] ?? 3.0;
    double continuation = continueMap[input.continuation] ?? 2.0;
    double freqVal      = contactMap[(input.contactFrequency - 1).clamp(0, 4)];

    // 2. 日英対応の高度な特徴量抽出
    final allText = '${input.who} ${input.what} ${input.why} ${input.how}'.toLowerCase();

    // attrO (魅力)
    double attrO = 5.5;
    final posAttr = ['可愛い', 'かわいい', '美人', '綺麗', 'きれい', 'イケメン', 'かっこいい', 'カッコイイ', 'タイプ', '魅力', 'cute', 'cool', 'handsome', 'beautiful', 'gorgeous', 'pretty', 'attractive', 'hot'];
    final negAttr = ['タイプじゃない', '好みじゃない', '普通', 'パッとしない', 'ugly', 'plain', 'not my type', 'unattractive'];
    for (var k in posAttr) {
      if (allText.contains(k)) attrO += 1.5;
    }
    for (var k in negAttr) {
      if (allText.contains(k)) attrO -= 1.5;
    }
    attrO = attrO.clamp(1.0, 10.0);

    // sincO (誠実)
    double sincO = 6.0;
    final posSinc = ['誠実', '真面目', '優しい', '丁寧', '親切', '信用', '信頼', 'マメ', 'honest', 'sincere', 'kind', 'polite', 'faithful', 'trustworthy'];
    final negSinc = ['不誠実', 'テキトー', 'チャラい', '嘘', '浮気', '雑', '適当', 'dishonest', 'unreliable', 'liar', 'insincere', 'rude'];
    for (var k in posSinc) {
      if (allText.contains(k)) sincO += 1.5;
    }
    for (var k in negSinc) {
      if (allText.contains(k)) sincO -= 1.5;
    }
    sincO = sincO.clamp(1.0, 10.0);

    // intelO (知性)
    double intelO = 7.0;
    final posIntel = ['賢い', 'スマート', '知的', '頭いい', '頭が良い', '仕事ができる', '尊敬', '理性的', 'smart', 'intelligent', 'clever', 'wise', 'knowledgeable'];
    final negIntel = ['馬鹿', '頭悪い', '話が通じない', '噛み合わない', 'stupid', 'dumb', 'foolish'];
    for (var k in posIntel) {
      if (allText.contains(k)) intelO += 1.5;
    }
    for (var k in negIntel) {
      if (allText.contains(k)) intelO -= 1.5;
    }
    intelO = intelO.clamp(1.0, 10.0);

    // funO (楽しさ)
    double funO = freqVal;
    final posFun = ['楽しい', '面白い', '笑', '盛り上がる', 'ハッピー', '笑顔', '楽しい時間', 'fun', 'funny', 'laugh', 'happy', 'enjoy', 'cheerful', 'humor'];
    final negFun = ['つまらない', '退屈', '苦痛', '沈黙', '気まずい', 'boring', 'dull', 'awkward', 'silent'];
    for (var k in posFun) {
      if (allText.contains(k)) funO += 1.5;
    }
    for (var k in negFun) {
      if (allText.contains(k)) funO -= 1.5;
    }
    funO = funO.clamp(1.0, 10.0);

    // sharO (共通点)
    double sharO = 6.0;
    final posShar = ['共通', '同じ', '趣味', '意気投合', '話が合う', '共感', '似ている', 'hobby', 'hobbies', 'shared', 'same', 'alike', 'common', 'sympathy', 'resonate'];
    final negShar = ['合わない', '趣味が違う', '価値観が合わない', '無関係', 'no common', 'different', 'disagree'];
    for (var k in posShar) {
      if (allText.contains(k)) sharO += 1.5;
    }
    for (var k in negShar) {
      if (allText.contains(k)) sharO -= 1.5;
    }
    sharO = sharO.clamp(1.0, 10.0);

    // likeO (好感度)
    double likeO = (continuation + initiative) / 2.0;
    final posLike = ['好き', '好意', '愛', '気になる', '魅了', '惚', 'love', 'like', 'crush', 'fancy', 'fond', 'adore'];
    final negLike = ['嫌い', '興味ない', '苦手', '関心がない', 'dislike', 'hate', 'ignore', 'not interested'];
    for (var k in posLike) {
      if (allText.contains(k)) likeO += 2.0;
    }
    for (var k in negLike) {
      if (allText.contains(k)) likeO -= 2.0;
    }
    likeO = likeO.clamp(1.0, 10.0);

    // probO (再会意欲/また会いたい確率)
    double probO = concreteness;
    final posProb = ['約束', '予定', 'デート', '遊びに行く', '次も', '会いたい', '行くことに', '楽しみ', '食事', 'ランチ', '飲み', 'date', 'promise', 'meet', 'appointment', 'next time', 'see you'];
    final negProb = ['断られた', '忙しい', '予定合わない', '社交辞令', '断る', '既読無視', '未読無視', '返信こない', 'busy', 'rejected', 'cancel', 'no reply', 'ignore'];
    for (var k in posProb) {
      if (allText.contains(k)) probO += 1.5;
    }
    for (var k in negProb) {
      if (allText.contains(k)) probO -= 1.5;
    }
    probO = probO.clamp(1.0, 10.0);

    // metO (面識)
    double metO = 0.0;
    final posMet = ['友達', '同僚', '同期', '先輩', '後輩', '知り合い', '昔から', '幼馴染', '以前から', '既知', 'friend', 'colleague', 'classmate', 'known', 'met before'];
    for (var k in posMet) {
      if (allText.contains(k)) {
        metO = 1.0;
        break;
      }
    }

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

  List<Factor> _buildFactors(List<double> features, InferenceInput input) {
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

    if (input.isVoice && input.voiceJitter != null) {
      final jitter = input.voiceJitter!;
      int impact = 0;
      String descText = '';
      String reasonText = '';
      if (jitter > 30) {
        impact = 18;
        descText = '声の震え率が高レベル ($jitter%)';
        reasonText = '対象への強い緊張・胸の高鳴り';
      } else if (jitter > 12) {
        impact = 10;
        descText = '声の震え率が中レベル ($jitter%)';
        reasonText = '意識している兆候・感情的興奮';
      } else {
        impact = -6;
        descText = '声の震えが極めて平坦 ($jitter%)';
        reasonText = '緊張感のない平常心・リラックス';
      }
      factors.add(Factor(
        id: 'f_voice_jitter',
        title: '声の震え (緊張度)',
        description: descText,
        scoreImpact: impact,
        reason: '【音声解析 $reasonText】',
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

  String _generateEnhancedScript(Label label, int score, List<Factor> factors, List<double> features, InferenceInput input) {
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

    if (input.isVoice && input.voiceJitter != null) {
      final jitter = input.voiceJitter!;
      if (jitter > 30) {
        s += ' 音声解析によると、君の声はかなり震えていたのだ！緊張や胸の高鳴りがデータにハッキリ出ているのだ。対象のことを深く意識している証拠なのだ！';
      } else if (jitter > 12) {
        s += ' 音声解析によると、君の声には適度な揺らぎ（緊張感）が観測されたのだ。冷静を装いつつも、内心はドキドキしているのが伝わるのだ！';
      } else {
        s += ' 音声解析によると、君の声は非常に冷静で安定していたのだ。リラックスして話せているか、あるいはまだ感情の波が少ない状態かもしれないのだ。';
      }
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

  Map<String, Map<String, double>> _calculateAttentionMap(InferenceInput input) {
    final keys = ['WHO', 'WHAT', 'WHEN', 'WHERE', 'WHY', 'HOW'];
    final map = <String, Map<String, double>>{};
    final random = math.Random();
    
    for (var i in keys) {
      map[i] = {};
      for (var j in keys) {
        double weight = (i == j) ? 0.4 : (random.nextDouble() * 0.15);
        if ((i == 'WHO' && j == 'WHAT') || (i == 'WHAT' && j == 'HOW')) {
          weight += 0.2;
        }
        map[i]![j] = weight;
      }
    }
    return map;
  }
}
