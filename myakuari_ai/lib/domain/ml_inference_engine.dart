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

      // 音響特徴量（震え/音量）はすでに特徴ベクトル構築 (_buildFeatureVector) 内で
      // 直接融合されているため、ここでの後加算処理 (voiceImpact) による重複加算は行いません。
      final adjustedScore = dynamicScore.clamp(0, 100);

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
    return buildFeatureVector(input);
  }

  /// 入力文と言語検知、および音響特徴量から10次元特徴ベクトルを精確に構築し直接融合する。
  /// (attrO, sincO, intelO, funO, sharO, likeO, probO, metO, impraceO, imprelO)
  static List<double> buildFeatureVector(InferenceInput input) {
    final initiativeMap = <String, double>{'相手': 9.0, '半々': 6.0, '自分': 3.0};
    final concreteMap   = <String, double>{'YES': 9.0,  '未定': 6.0, '止まる': 3.0};
    final continueMap   = <String, double>{'続いてる': 8.0, '普通': 6.0, '途切れた': 2.0};
    final contactMap    = [2.0, 4.0, 6.0, 8.0, 10.0];

    double initiative   = initiativeMap[input.initiative] ?? 6.0;
    double concreteness = concreteMap[input.concreteness] ?? 3.0;
    double continuation = continueMap[input.continuation] ?? 2.0;
    double freqVal      = contactMap[(input.contactFrequency - 1).clamp(0, 4)];

    final allText = '${input.who} ${input.what} ${input.why} ${input.how}'.toLowerCase();

    // attrO (魅力, baseline: 5.5)
    double attrO = 5.5;
    final posAttrJa = ['可愛い', 'かわいい', '美人', '綺麗', 'きれい', 'イケメン', 'かっこいい', 'カッコイイ', 'タイプ', '魅力', '素敵', '華やか', 'オーラ'];
    final negAttrJa = ['タイプじゃない', '好みじゃない', '普通', 'パッとしない', '地味'];
    final posAttrEn = ['cute', 'cool', 'handsome', 'beautiful', 'gorgeous', 'pretty', 'attractive', 'hot', 'charming', 'stunning'];
    final negAttrEn = ['ugly', 'plain', 'not my type', 'unattractive', 'boring look'];

    if (input.isEnglish) {
      for (var k in posAttrEn) {
        if (allText.contains(k)) attrO += 1.5;
      }
      for (var k in negAttrEn) {
        if (allText.contains(k)) attrO -= 1.5;
      }
    } else {
      for (var k in posAttrJa) {
        if (allText.contains(k)) attrO += 1.5;
      }
      for (var k in negAttrJa) {
        if (allText.contains(k)) attrO -= 1.5;
      }
    }
    attrO = attrO.clamp(1.0, 10.0);

    // sincO (誠実, baseline: 6.0)
    double sincO = 6.0;
    final posSincJa = ['誠実', '真面目', '優しい', '丁寧', '親切', '信用', '信頼', 'マメ', '温かい', '気遣い'];
    final negSincJa = ['不誠実', 'テキトー', 'チャラい', '嘘', '浮気', '雑', '適当', 'いい加減', 'ルーズ'];
    final posSincEn = ['honest', 'sincere', 'kind', 'polite', 'faithful', 'trustworthy', 'caring', 'sweet', 'thoughtful'];
    final negSincEn = ['dishonest', 'unreliable', 'liar', 'insincere', 'rude', 'cheat', 'shady', 'careless'];

    if (input.isEnglish) {
      for (var k in posSincEn) {
        if (allText.contains(k)) sincO += 1.5;
      }
      for (var k in negSincEn) {
        if (allText.contains(k)) sincO -= 1.5;
      }
    } else {
      for (var k in posSincJa) {
        if (allText.contains(k)) sincO += 1.5;
      }
      for (var k in negSincJa) {
        if (allText.contains(k)) sincO -= 1.5;
      }
    }
    sincO = sincO.clamp(1.0, 10.0);

    // intelO (知性, baseline: 7.0)
    double intelO = 7.0;
    final posIntelJa = ['賢い', 'スマート', '知的', '頭いい', '頭が良い', '仕事ができる', '尊敬', '理性的', '物知り', '博学'];
    final negIntelJa = ['馬鹿', '頭悪い', '話が通じない', '噛み合わない', '無知', '幼稚'];
    final posIntelEn = ['smart', 'intelligent', 'clever', 'wise', 'knowledgeable', 'capable', 'respectable', 'rational'];
    final negIntelEn = ['stupid', 'dumb', 'foolish', 'ignorant', 'childish'];

    if (input.isEnglish) {
      for (var k in posIntelEn) {
        if (allText.contains(k)) intelO += 1.5;
      }
      for (var k in negIntelEn) {
        if (allText.contains(k)) intelO -= 1.5;
      }
    } else {
      for (var k in posIntelJa) {
        if (allText.contains(k)) intelO += 1.5;
      }
      for (var k in negIntelJa) {
        if (allText.contains(k)) intelO -= 1.5;
      }
    }
    intelO = intelO.clamp(1.0, 10.0);

    // funO (楽しさ, baseline: freqVal)
    double funO = freqVal;
    final posFunJa = ['楽しい', '面白い', '笑', '盛り上がる', 'ハッピー', '笑顔', '楽しい時間', '愉快', '爆笑'];
    final negFunJa = ['つまらない', '退屈', '苦痛', '沈黙', '気まずい', 'つまらん', 'しんどい'];
    final posFunEn = ['fun', 'funny', 'laugh', 'happy', 'enjoy', 'cheerful', 'humor', 'hilarious', 'good time'];
    final negFunEn = ['boring', 'dull', 'awkward', 'silent', 'painful', 'dry'];

    if (input.isEnglish) {
      for (var k in posFunEn) {
        if (allText.contains(k)) funO += 1.5;
      }
      for (var k in negFunEn) {
        if (allText.contains(k)) funO -= 1.5;
      }
    } else {
      for (var k in posFunJa) {
        if (allText.contains(k)) funO += 1.5;
      }
      for (var k in negFunJa) {
        if (allText.contains(k)) funO -= 1.5;
      }
    }
    // RMS (音量) の直接融合
    if (input.isVoice && input.voiceRms != null) {
      final rms = input.voiceRms!;
      if (rms > 60) {
        funO += 2.0;
      } else if (rms > 20) {
        funO += 1.0;
      }
    }
    funO = funO.clamp(1.0, 10.0);

    // sharO (共通点, baseline: 6.0)
    double sharO = 6.0;
    // 間接表現「落ち着く」「気が合う」も sharO にマッピングする
    final posSharJa = ['共通', '同じ', '趣味', '意気投合', '話が合う', '共感', '似ている', '波長', '相性', '落ち着く', '気が合う', '気があった'];
    final negSharJa = ['合わない', '趣味が違う', '価値観が合わない', '無関係', '話合わない'];
    final posSharEn = ['hobby', 'hobbies', 'shared', 'same', 'alike', 'common', 'sympathy', 'resonate', 'chemistry', 'comfortable', 'relax', 'harmony'];
    final negSharEn = ['no common', 'different', 'disagree', 'clash', 'no chemistry'];

    if (input.isEnglish) {
      for (var k in posSharEn) {
        if (allText.contains(k)) sharO += 1.5;
      }
      for (var k in negSharEn) {
        if (allText.contains(k)) sharO -= 1.5;
      }
    } else {
      for (var k in posSharJa) {
        if (allText.contains(k)) sharO += 1.5;
      }
      for (var k in negSharJa) {
        if (allText.contains(k)) sharO -= 1.5;
      }
    }
    sharO = sharO.clamp(1.0, 10.0);

    // likeO (好感度, baseline: (continuation + initiative) / 2.0)
    double likeO = (continuation + initiative) / 2.0;
    // 間接表現「お世話」「一緒にいて楽」「居心地」「親しみ」
    final posLikeIndirectJa = ['お世話', '一緒にいて楽', '居心地', '親しみ', '楽ちん', '落ち着く', '安らぐ'];
    final posLikeDirectJa = ['好き', '好意', '愛', '気になる', '魅了', '惚', '恋', '一目惚れ', '惹かれる'];
    final negLikeJa = ['嫌い', '興味ない', '苦手', '関心がない', '無視', '避ける'];
    
    final posLikeIndirectEn = ['comfortable', 'at ease', 'get along', 'feel good', 'chilled', 'friendly'];
    final posLikeDirectEn = ['love', 'like', 'crush', 'fancy', 'fond', 'adore', 'attracted', 'fall for'];
    final negLikeEn = ['dislike', 'hate', 'ignore', 'not interested', 'avoid', 'cold'];

    if (input.isEnglish) {
      for (var k in posLikeDirectEn) {
        if (allText.contains(k)) likeO += 2.5;
      }
      for (var k in posLikeIndirectEn) {
        if (allText.contains(k)) likeO += 1.5;
      }
      for (var k in negLikeEn) {
        if (allText.contains(k)) likeO -= 2.0;
      }
    } else {
      for (var k in posLikeDirectJa) {
        if (allText.contains(k)) likeO += 2.5;
      }
      for (var k in posLikeIndirectJa) {
        if (allText.contains(k)) likeO += 1.5;
      }
      for (var k in negLikeJa) {
        if (allText.contains(k)) likeO -= 2.0;
      }
    }

    // Jitter (声の震え) の直接融合（実際に音声が検出された場合のみ適用）
    if (input.isVoice && input.voiceJitter != null && input.voiceRms != null && input.voiceRms! > 5) {
      final jitter = input.voiceJitter!;
      if (jitter > 30) {
        likeO += 4.0;
      } else if (jitter > 12) {
        likeO += 2.0;
      } else {
        likeO -= 0.5; // ペナルティを緩和
      }
    }
    likeO = likeO.clamp(1.0, 10.0);

    // probO (再会意欲/また会いたい確率, baseline: concreteness)
    double probO = concreteness;
    final posProbJa = ['約束', '予定', 'デート', '遊びに行く', '次も', '会いたい', '行くことに', '楽しみ', '食事', 'ランチ', '飲み', '遊びに', '会う予定'];
    final negProbJa = ['断られた', '忙しい', '予定合わない', '社交辞令', '断る', '既読無視', '未読無視', '返信こない', '流れた', 'キャンセル'];
    final posProbEn = ['date', 'promise', 'meet', 'appointment', 'next time', 'see you', 'hang out', 'dinner', 'lunch', 'excited', 'plan to'];
    final negProbEn = ['busy', 'rejected', 'cancel', 'no reply', 'ignore', 'ghosted', 'cannot go', 'declined'];

    if (input.isEnglish) {
      for (var k in posProbEn) {
        if (allText.contains(k)) probO += 1.5;
      }
      for (var k in negProbEn) {
        if (allText.contains(k)) probO -= 1.5;
      }
    } else {
      for (var k in posProbJa) {
        if (allText.contains(k)) probO += 1.5;
      }
      for (var k in negProbJa) {
        if (allText.contains(k)) probO -= 1.5;
      }
    }
    // RMS (音量) の直接融合
    if (input.isVoice && input.voiceRms != null) {
      final rms = input.voiceRms!;
      if (rms > 60) {
        probO += 1.5;
      } else if (rms > 20) {
        probO += 0.5;
      }
    }
    probO = probO.clamp(1.0, 10.0);

    // metO (面識)
    double metO = 0.0;
    final posMetJa = ['友達', '同僚', '同期', '先輩', '後輩', '知り合い', '昔から', '幼馴染', '以前から', '既知', 'クラスメイト', '部活'];
    final posMetEn = ['friend', 'colleague', 'classmate', 'known', 'met before', 'acquaintance', 'childhood friend'];

    if (input.isEnglish) {
      for (var k in posMetEn) {
        if (allText.contains(k)) {
          metO = 1.0;
          break;
        }
      }
    } else {
      for (var k in posMetJa) {
        if (allText.contains(k)) {
          metO = 1.0;
          break;
        }
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
    
    // エンタメアプリとしての調整: リアルデータ（コロンビア大）は厳しすぎるため、少し前向きなバイアスをかける
    logits[0] -= 1.0; // Nopeの確率を下げる
    logits[2] += 0.8; // Likeの確率を少し上げる

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
        impact = -3;
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
    
    // 言語自動検知と言語別解説の追加
    if (input.isEnglish) {
      s += ' 言語検知システムが英語入力を認識したのだ。英語特有の直接的でストレートな感情表現（Direct Attraction Sign）を重視し、コロンビア大学モデルの基準へと精確にマッピングして推論したのだ！';
    } else {
      s += ' 言語検知システムが日本語入力を認識したのだ。日本語特有の「お世話」「落ち着く」といった奥ゆかしい間接的表現（Indirect Affinity Sign）を読み解き、コロンビア大学のSpeed Dating特徴空間へと適切にマッピングして判定したのだ！';
    }

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
      return (60 + (rawScore * 0.4)).round().clamp(60, 99);
    } else if (label == Label.nope) {
      // 脈なしなら、厳しすぎないよう10-45点の範囲に緩和
      return (15 + rawScore * 0.6).round().clamp(10, 45);
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
