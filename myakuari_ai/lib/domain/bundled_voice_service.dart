import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

/// アプリに同梱済みのWAVファイルをランダム選択して再生する。
/// ネット接続不要・Voicevox Engine起動不要。
class BundledVoiceService {
  static final BundledVoiceService _instance = BundledVoiceService._internal();
  factory BundledVoiceService() => _instance;
  BundledVoiceService._internal();

  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();

  /// カテゴリ→バリエーションリストのマッピング
  static const Map<String, List<String>> _variants = {
    // ホーム
    'home': ['home_1', 'home_2', 'home_3'],

    // ウィザード質問
    'q_who':   ['q_who_1',   'q_who_2',   'q_who_3'],
    'q_what':  ['q_what_1',  'q_what_2',  'q_what_3'],
    'q_when':  ['q_when_1',  'q_when_2',  'q_when_3'],
    'q_where': ['q_where_1', 'q_where_2', 'q_where_3'],
    'q_why':   ['q_why_1',   'q_why_2',   'q_why_3'],
    'q_how':   ['q_how_1',   'q_how_2',   'q_how_3'],

    // 回答後
    'thanks': ['thanks_1', 'thanks_2', 'thanks_3'],

    // ローディング
    'loading': ['loading_1', 'loading_2', 'loading_3', 'loading_4'],

    // 脈アリ
    'result_good':    ['result_good_1',    'result_good_2',    'result_good_3',    'result_good_4'],

    // 脈ナシ
    'result_bad':     ['result_bad_1',     'result_bad_2',     'result_bad_3'],

    // 中立
    'result_neutral': ['result_neutral_1', 'result_neutral_2', 'result_neutral_3'],
  };

  /// ウィザードページ番号→カテゴリキー
  static const List<String> _questionKeys = [
    'q_who', 'q_what', 'q_when', 'q_where', 'q_why', 'q_how',
  ];

  String _pick(String category) {
    final list = _variants[category];
    if (list == null || list.isEmpty) return category;
    return list[_rng.nextInt(list.length)];
  }

  Future<void> playQuestion(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= _questionKeys.length) return;
    await _play(_pick(_questionKeys[pageIndex]));
  }

  Future<void> playNamed(String category) async {
    await _play(_pick(category));
  }

  Future<void> _play(String key) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$key.wav'));
    } catch (_) {
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
