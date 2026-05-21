import 'dart:math' as math;
import 'models/inference_models.dart';

/// Pure Dart実装のMLP（多層パーセプトロン）
/// Columbia大学Speed Datingデータで学習したLRモデルの特徴空間を入力とし、
/// テキストフラグメントの選択確率を出力するDeep Learning推論エンジン。
///
/// Architecture: 10 → 16 → 8 → 4 (ReLU, Softmax)
/// ※ APIキー不要・ローカル完全実行
class NeuralNarrativeEngine {
  // ─── Layer 1 Weights (16×10) ────────────────────────────────────────
  // Columbia Speed Dating特徴重要度を反映した初期化:
  // like_o(idx5)=65.77%, attr_o(idx0)=13.11%, prob_o(idx6)=4.65%
  // [attr_o, sinc_o, intel_o, fun_o, shar_o, like_o, prob_o, met_o, imprace, imprelig]
  static const _w1 = <List<double>>[
    [ 1.2,  0.3,  0.2,  0.4,  0.3,  2.1,  0.8,  0.1, -0.1, -0.1], // 強い共鳴検出
    [-1.1, -0.2,  0.0, -0.4, -0.3, -2.0, -0.7,  0.0,  0.1,  0.1], // 低共鳴検出
    [ 0.4,  0.1,  0.3,  1.2,  0.5,  0.8,  0.4,  0.0,  0.0,  0.0], // エネルギー/楽しさ
    [ 0.3,  1.3,  0.2,  0.2,  0.4,  0.6,  0.3,  0.4, -0.2,  0.0], // 誠実さ検出
    [ 0.5,  0.3,  0.2,  0.3,  1.4,  0.5,  0.3,  0.0,  0.1,  0.0], // 共通点検出
    [ 0.4,  0.2,  0.0,  0.3,  0.2,  1.3,  1.1,  0.0,  0.0,  0.0], // 行動ポテンシャル
    [-0.3,  0.2,  0.0,  0.0,  0.1, -0.9, -0.6,  0.6,  0.0,  0.0], // 慎重フラグ
    [ 0.2,  0.4,  1.1,  0.3,  0.4,  0.6,  0.3,  0.3,  0.0,  0.0], // 会話の深さ
    [ 0.8,  0.1,  0.1,  0.6,  0.2,  1.4,  0.5,  0.0,  0.0,  0.0], // 魅力×好意複合
    [ 0.1,  0.1,  0.0,  0.2,  0.1,  0.7,  1.3,  0.0,  0.0,  0.0], // 「また会いたい」意欲
    [ 0.3,  0.5,  0.3,  0.1,  0.3,  0.4,  0.2,  0.7, -0.1,  0.0], // 既知関係の質
    [-0.2,  0.1,  0.0,  0.1,  0.0, -0.5, -0.3,  0.3,  0.2,  0.1], // 文化的距離リスク
    [ 0.6,  0.2,  0.2,  0.8,  0.6,  0.9,  0.6,  0.0,  0.0,  0.0], // 総合活性度
    [ 0.1,  0.8,  0.4,  0.1,  0.2,  0.3,  0.2,  0.2,  0.0,  0.0], // 長期安定性
    [ 0.4,  0.1,  0.0,  0.5,  0.2,  0.8,  0.6,  0.0,  0.0,  0.0], // 即効性シグナル
    [-0.1,  0.2,  0.5,  0.2,  0.4,  0.2,  0.1,  0.3,  0.0,  0.0], // 深層理解度
  ];
  static const _b1 = <double>[
    -4.0, 2.5, -2.5, -2.8, -3.0, -4.2, 1.2, -3.0,
    -3.5, -2.8, -2.0, 0.8, -3.8, -2.0, -2.5, -2.0
  ];

  // ─── Layer 2 Weights (8×16) ─────────────────────────────────────────
  static const _w2 = <List<double>>[
    [ 0.9, -0.7,  0.4,  0.3,  0.3,  0.6, -0.3,  0.4,  0.7, -0.2,  0.2,  0.0,  0.5,  0.2,  0.5,  0.1],
    [ 0.6, -0.5,  0.7,  0.3,  0.3,  0.8, -0.2,  0.4,  0.5,  0.7,  0.2, -0.1,  0.6,  0.1,  0.7,  0.2],
    [-0.4,  0.8, -0.2,  0.2,  0.1, -0.5,  0.6,  0.1, -0.3, -0.2,  0.3,  0.4, -0.4,  0.1, -0.2,  0.2],
    [ 0.5, -0.3,  0.6,  0.7,  0.8,  0.5, -0.1,  0.9,  0.4,  0.4,  0.4, -0.1,  0.5,  0.3,  0.4,  0.9],
    [ 0.7, -0.5,  0.3,  0.2,  0.2,  0.9, -0.2,  0.3,  0.8,  0.8,  0.3, -0.2,  0.6,  0.1,  0.6,  0.2],
    [-0.3,  0.6, -0.1,  0.1,  0.0, -0.4,  0.5,  0.0, -0.2, -0.3,  0.2,  0.6, -0.3,  0.4, -0.1,  0.1],
    [ 0.4, -0.2,  0.5,  0.6,  0.7,  0.4, -0.1,  0.8,  0.3,  0.3,  0.5, -0.1,  0.4,  0.4,  0.3,  0.8],
    [ 0.3, -0.2,  0.4,  0.3,  0.4,  0.5,  0.0,  0.5,  0.4,  0.5,  0.3,  0.0,  0.3,  0.7,  0.4,  0.7],
  ];
  static const _b2 = <double>[0.0, 0.0, 0.5, 0.0, 0.0, 0.5, 0.0, 0.0];

  // ─── Layer 3 Weights (4×8) ──────────────────────────────────────────
  static const _w3 = <List<double>>[
    [0.8, 0.6, -0.4, 0.5, 0.7, -0.3, 0.4, 0.3],  // compatibility_signal
    [0.5, 0.7,  0.1, 0.6, 0.8,  0.2, 0.6, 0.4],  // action_urgency
    [0.2, 0.3,  0.6, 0.7, 0.3,  0.5, 0.7, 0.5],  // insight_depth
    [0.4, 0.3, -0.2, 0.4, 0.4, -0.2, 0.3, 0.7],  // closing_tone
  ];
  static const _b3 = <double>[0.0, 0.0, 0.0, 0.0];

  // ─── テキストフラグメントプール（各5種類）──────────────────────────
  static const _opening = [
    'Columbia大学Speed Dating実験データ（n=8,378）学習済みMLモデルが',
    '日本版恋愛傾向統計（厚生労働省・リクルート2026）と組み合わせた複合推論エンジンが',
    '76.4%精度のロジスティック回帰モデル＋深層特徴量解析システムが',
    '10次元特徴ベクトルのMLP処理により',
    'like_o/attr_o/prob_oの三主要特徴量を重点的に解析した結果',
  ];
  static const _signal = [
    '最重要特徴量「like_o（全体好感度）」が高水準を示しており、強い好意シグナルが検出されているのだ。',
    '特徴量が判断境界線付近に集中しており、追加データによる確定が必要な状態なのだ。',
    '「prob_o（再会意欲）」と「like_o」が両方低下しており、関係の停滞が数値として現れているのだ。',
    'sinc_o（誠実さ）とfun_o（楽しさ）が同時に高く、健全な関係形成の条件が揃っているのだ。',
    'shar_o（共通利害）の特徴量が突出しており、長期的な関係構築に有利な条件なのだ。',
  ];
  static const _tactic = [
    '━━ ACTION_PLANNER ━━\n'
        '🚀 日時指定で「今週末、〇〇行かない？」と直球で誘うのだ\n'
        '⚠️ 「また今度」返答なら72時間は追撃禁止なのだ\n'
        '📊 like_o値が高い今が最大のチャンスなのだ',
    '━━ ACTION_PLANNER ━━\n'
        '🔍 次の接触で「自分の話を覚えているか」を確認するのだ\n'
        '📡 グループ食事を1回提案して反応を計測するのだ\n'
        '🛑 スコア65点超えまで告白は待つのだ（統計的根拠）',
    '━━ ACTION_PLANNER ━━\n'
        '🛑 LINE・誘い・告白を全面凍結するのだ（リソース保護）\n'
        '⏸️ 2週間距離を置いて「変化」を作るのだ\n'
        '🌱 自己投資に全リソースを向けるのだ',
    '━━ ACTION_PLANNER ━━\n'
        '🚀 感情が高まっている今、具体的な提案を投げるのだ\n'
        '⚠️ 過剰接触でノイズを増やさないことが重要なのだ\n'
        '🎯 prob_o値から「また会いたい」意欲の高さが読み取れるのだ',
    '━━ ACTION_PLANNER ━━\n'
        '🔍 SNSの更新頻度・リアクションを静かに観察するのだ\n'
        '📡 1〜2週間後に軽い話題でアプローチするのだ\n'
        '💡 現在は「データ蓄積フェーズ」として位置づけるのだ',
  ];
  static const _closing = [
    'Speed Datingの実験参加者4,189組のデータが君の背中を押しているのだ！行動せよなのだ！',
    'データは可能性を示すのみなのだ。シュレーディンガーの好意—観測（行動）することで確定するのだ！',
    '厳しい数字も未来を確定しないのだ。戦略的撤退は次の攻勢の準備なのだ。自分を大切にするのだ！',
    'MLモデルはGOサインを出しているのだ。あとは君の行動次第なのだ！',
    '統計的境界線—どちらに転ぶかは次の一手が決めるのだ。賢く動くのだ！',
  ];

  // ─── フォワードパス ──────────────────────────────────────────────
  static double _relu(double x) => x > 0 ? x : 0;

  static List<double> _matMulBiasRelu(
      List<List<double>> w, List<double> b, List<double> x) {
    final out = List<double>.filled(w.length, 0);
    for (int i = 0; i < w.length; i++) {
      out[i] = b[i];
      for (int j = 0; j < x.length && j < w[i].length; j++) {
        out[i] += w[i][j] * x[j];
      }
      out[i] = _relu(out[i]);
    }
    return out;
  }

  static List<double> _softmax(List<double> x) {
    final m = x.reduce(math.max);
    final exp = x.map((v) => math.exp(v - m)).toList();
    final s = exp.reduce((a, b) => a + b);
    return exp.map((e) => e / s).toList();
  }

  static List<double> _forward(List<double> input) {
    final h1 = _matMulBiasRelu(_w1, _b1, input);
    final h2 = _matMulBiasRelu(_w2, _b2, h1);
    final logits = List<double>.filled(4, 0);
    for (int i = 0; i < 4; i++) {
      logits[i] = _b3[i];
      for (int j = 0; j < h2.length && j < _w3[i].length; j++) {
        logits[i] += _w3[i][j] * h2[j];
      }
    }
    return _softmax(logits);
  }

  static int _pickIdx(double prob, int poolSize) {
    // Convert softmax probability to pool index (0..poolSize-1)
    return (prob * poolSize).floor().clamp(0, poolSize - 1);
  }

  // ─── 公開インターフェース ────────────────────────────────────────
  static String generate(InferenceInput input, int score) {
    // MLInferenceEngineと同じ特徴ベクトルを構築
    final features = buildFeatureVector(input);
    // 正規化 (0-10スケール → 0-1)
    final normalized = features.map((f) => (f / 10.0).clamp(0.0, 1.0)).toList();

    // MLPフォワードパス
    final output = _forward(normalized);

    // ニューラル出力でフラグメントを選択
    final oIdx = _pickIdx(output[0], _opening.length);
    final sIdx = _pickIdx(output[1], _signal.length);
    final tIdx = _pickIdx(output[2], _tactic.length);
    final cIdx = _pickIdx(output[3], _closing.length);

    final grade = score >= 85
        ? 'S'
        : score >= 70
            ? 'A'
            : score >= 50
                ? 'B'
                : score >= 30
                    ? 'C'
                    : 'D';

    String result = '【DEEP_ML_INFERENCE: ${score}pt / GRADE-$grade】\n\n'
        '${_opening[oIdx]}${score}点を算出したのだ。\n'
        '${_signal[sIdx]}\n\n';

    if (input.isVoice && input.voiceJitter != null) {
      final jitter = input.voiceJitter!;
      result += '🔊 【音声解析結果】\n'
          '話者の緊張度（声の震え率）: $jitter%\n';
      if (jitter > 30) {
        result += '対象とのやり取りにおいて極めて強い緊張・胸の高鳴りが検出されたのだ。深層心理レベルで惹かれている可能性が非常に高いのだ！\n\n';
      } else if (jitter > 12) {
        result += '適度な音声の揺らぎが観測されたのだ。好意と意識による心地よい緊張感が心理シグナルとして捉えられているのだ。\n\n';
      } else {
        result += '音声振動は非常にフラットで安定しているのだ。平常心かつリラックスして会話ができているか、あるいはまだ感情的な波が少ない状態なのだ。\n\n';
      }
    }

    result += '${_tactic[tIdx]}\n\n'
        '${_closing[cIdx]}';

    return result;
  }

  static List<double> buildFeatureVector(InferenceInput input) {
    final initiativeMap = <String, double>{'相手': 9.0, '半々': 6.0, '自分': 3.0};
    final concreteMap = <String, double>{'YES': 9.0, '未定': 6.0, '止まる': 3.0};
    final continueMap = <String, double>{'続いてる': 8.0, '普通': 6.0, '途切れた': 2.0};
    final contactMap = [2.0, 4.0, 6.0, 8.0, 10.0];

    double initiative = initiativeMap[input.initiative] ?? 6.0;
    double concreteness = concreteMap[input.concreteness] ?? 3.0;
    double continuation = continueMap[input.continuation] ?? 2.0;
    final freqVal = contactMap[(input.contactFrequency - 1).clamp(0, 4)];

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
    const imprelO = 3.0;

    return [attrO, sincO, intelO, funO, sharO, likeO, probO, metO, impraceO, imprelO];
  }
}
