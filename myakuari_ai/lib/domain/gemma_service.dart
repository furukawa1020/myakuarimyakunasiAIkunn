import 'models/inference_models.dart';
import 'neural_narrative_engine.dart';

/// GemmaServiceのWeb対応版。
/// APIキー不要・ローカル完全実行。
/// NeuralNarrativeEngine（Pure Dart MLP）を使い、MLモデルの
/// 特徴ベクトルをニューラルネットで処理してテキストを生成する。
class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  final bool _initialized = true;
  bool get isReady => _initialized;
  Future<void> initialize() async {}

  Future<String> generateDeepAnalysis(
      InferenceInput input, int score, String label) async {
    // MLP推論（ローカル・APIキー不要）
    // 10次元特徴ベクトル → 16→8→4ニューロン → softmax → テキスト選択
    await Future.delayed(const Duration(milliseconds: 600)); // 推論演出

    return NeuralNarrativeEngine.generate(input, score);
  }
}
