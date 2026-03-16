import 'bundled_voice_service.dart';

/// プラットフォーム抽象化のためのラッパー。
/// 実際には現在 BundledVoiceService で完結しているため、Web対応のために型定義を整理する。
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final BundledVoiceService _bundled = BundledVoiceService();

  Future<void> playHome() => _bundled.playNamed('home');
  Future<void> playQuestion(int idx) => _bundled.playQuestion(idx);
  Future<void> playThanks() => _bundled.playNamed('thanks');
  Future<void> playResult(String label) => _bundled.playNamed('result_$label');
  
  void dispose() {
    _bundled.dispose();
  }
}
