import 'package:audioplayers/audioplayers.dart';

/// アプリに同梱済みのWAVファイルを再生する。
/// ネット接続不要・Voicevox Engine起動不要。
class BundledVoiceService {
  static final BundledVoiceService _instance = BundledVoiceService._internal();
  factory BundledVoiceService() => _instance;
  BundledVoiceService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// ウィザード質問の音声キー（ページ番号→ファイル名マッピング）
  static const List<String> questionKeys = [
    'q_who',
    'q_what',
    'q_when',
    'q_where',
    'q_why',
    'q_how',
  ];

  /// 状態→音声ファイルのマッピング
  static const Map<String, String> namedKeys = {
    'loading':        'loading',
    'result_good':    'result_good',
    'result_bad':     'result_bad',
    'result_neutral': 'result_neutral',
  };

  Future<void> playQuestion(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= questionKeys.length) return;
    await _play(questionKeys[pageIndex]);
  }

  Future<void> playNamed(String key) async {
    await _play(key);
  }

  Future<void> _play(String key) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$key.wav'));
    } catch (e) {
      // 音声ファイルが存在しない場合は無視
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
