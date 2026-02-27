import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voicevox Engine (HTTP) を使ったリモートTTSサービス。
/// PC上でVoicevox Engineを起動し、同一Wi-Fi内のAndroid実機から接続して使う。
class RemoteVoicevoxService {
  static const int _zundamonStyleId = 3;
  static const String _defaultBaseUrl = 'http://10.0.2.2:50021';

  final AudioPlayer _audioPlayer = AudioPlayer();
  String _baseUrl = _defaultBaseUrl;
  bool _isInitialized = false;

  static final RemoteVoicevoxService _instance = RemoteVoicevoxService._internal();
  factory RemoteVoicevoxService() => _instance;
  RemoteVoicevoxService._internal();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('voicevox_server_url') ?? _defaultBaseUrl;
    _isInitialized = true;
  }

  /// サーバーURLを更新して保存する
  Future<void> setServerUrl(String url) async {
    _baseUrl = url.trimRight().replaceAll(RegExp(r'/$'), ''); // 末尾のスラッシュを除去
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voicevox_server_url', _baseUrl);
  }

  String get serverUrl => _baseUrl;

  /// 接続テスト — サーバーが生きているかどうか確認する
  Future<bool> ping() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/version'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    try {
      // Step 1: audio_query を生成
      final queryRes = await http.post(
        Uri.parse('$_baseUrl/audio_query').replace(
          queryParameters: {'text': text, 'speaker': _zundamonStyleId.toString()},
        ),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (queryRes.statusCode != 200) return;

      // Step 2: 音声合成
      final synthRes = await http.post(
        Uri.parse('$_baseUrl/synthesis').replace(
          queryParameters: {'speaker': _zundamonStyleId.toString()},
        ),
        headers: {'Content-Type': 'application/json'},
        body: queryRes.body,
      ).timeout(const Duration(seconds: 15));

      if (synthRes.statusCode != 200) return;

      // Step 3: WAVデータを一時ファイルに書いて再生
      final tmpDir = await getTemporaryDirectory();
      final wavFile = File('${tmpDir.path}/tts_remote.wav');
      await wavFile.writeAsBytes(synthRes.bodyBytes);

      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(wavFile.path));
    } catch (e) {
      // 接続失敗やタイムアウトは静かに無視
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
