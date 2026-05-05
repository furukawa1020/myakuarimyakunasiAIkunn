import 'models/inference_models.dart';

/// FlutterGemma を使ったオンデバイス LLM 制御クラス (Web用にスタブ化)
class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _initialized = true;
    } catch (e) {
      print('Gemma initialization failed: $e');
      _initialized = false;
    }
  }
      print('Gemma initialization failed: $e');
      _initialized = false;
    }
  }

  bool get isReady => _initialized;

  /// 診断結果をずんだもん口調で深層解析
  Future<String> generateDeepAnalysis(InferenceInput input, int score, String label) async {
    if (!_initialized) return 'AI準備中なのだ...、今は手動解析に切り替えるのだ。';

    final prompt = _buildPrompt(input, score, label);
    
    try {
      // 応答生成 (ストリーミングではなく一括取得) (Web版はスタブ)
      return 'Web版では生成AIは使えないのだ！でも君の恋は応援してるのだ！';
    } catch (e) {
      return 'AIが照れてるみたいで、今は解析できないのだ。エラー: $e';
    }
  }

  String _buildPrompt(InferenceInput input, int score, String label) {
    return """
君は最強の恋愛アドバイザー「ずんだもん」様なのだ。
以下の 5W1H データと診断スコア（100点満点）を元に、相手の心理を鋭く分析し、
具体的で少し生意気な、でも暖かいアドバイスを「ずんだもん口調（〜なのだ、〜なのだ！）」で生成するのだ。

【入力データ】
- 相手: ${input.who}
- 出来事: ${input.what}
- 状況: ${input.where}
- 診断スコア: ${score}点
- 結論: ${label}

【出力の制約】
1. なぜそのスコアになったかの理由を、日本語特有の「行間」から推測して書くのだ。
2. 次にどんな具体的なLINEを送るべきか、具体的なメッセージ案を一例出すのだ。
3. 文末は必ず「〜なのだ」や「〜なのだ！」にするのだ。
""";
  }
}
