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

  bool get isReady => _initialized;

  Future<String> generateDeepAnalysis(InferenceInput input, int score, String label) async {
    if (!_initialized) return 'AI準備中なのだ...、今は手動解析に切り替えるのだ。';
    
    try {
      return 'Web版では生成AIは使えないのだ！でも君の恋は応援してるのだ！';
    } catch (e) {
      return 'AIが照れてるみたいで、今は解析できないのだ。エラー: $e';
    }
  }
}
