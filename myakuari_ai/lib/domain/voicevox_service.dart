import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicevox_core/voicevox_core.dart';
import 'package:audioplayers/audioplayers.dart';

class LocalVoicevoxService {
  static final LocalVoicevoxService _instance = LocalVoicevoxService._internal();
  factory LocalVoicevoxService() => _instance;
  LocalVoicevoxService._internal();

  VoicevoxCore? _core;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  // ずんだもんのスタイルID (通常は3: ノーマル)
  static const int _zundamonStyleId = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 辞書ファイルのロード (assets/voicevox/open_jtalk_dic_utf_8-1.11 に配置想定)
      final dicPath = await _copyDirectoryFromAssets('assets/voicevox/open_jtalk_dic_utf_8-1.11');
      
      // Initialize core component
      // 注: 実運用ではAndroidの場合 libvoicevox_core.so を jniLibs に配置する必要があります。
      _core = VoicevoxCore(openJtalkDictDir: dicPath);
      await _core!.initialize();
      
      // モデルファイルのロード (vvm)
      // ずんだもんのvvmファイルが assets/voicevox/zundamon.vvm にあると想定
      final modelPath = await _copyAssetToFile('assets/voicevox/zundamon.vvm');
      final voiceModel = VoiceModel.fromPath(modelPath);
      await _core!.loadVoiceModel(voiceModel);

      _isInitialized = true;
      print('Voicevox Core initialized successfully.');
    } catch (e) {
      print('Failed to initialize Voicevox Core: $e');
      // 初期化失敗時はTTSを無効化するフォールバック
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || _core == null) {
      print('Voicevox is not initialized. Skipping audio.');
      return;
    }

    try {
      // 1. AudioQueryを生成
      final query = await _core!.audioQuery(text, _zundamonStyleId);
      
      // 2. 音声合成 (WAVデータのバイト配列が返る)
      final wavData = await _core!.synthesis(query, _zundamonStyleId);

      // 3. 一時ファイルに保存して再生
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_speech.wav');
      await tempFile.writeAsBytes(wavData);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      print('Speech synthesis failed: $e');
    }
  }

  /// assetディレクトリをデバイスのローカルストレージにコピーしてパスを返す
  Future<String> _copyDirectoryFromAssets(String assetDirPath) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    // 簡単化のため、実装時は辞書のファイル一覧を個別にコピーするか、zipで固めて解凍する方法が推奨されます。
    // ここではパスのみ返す（仮実装）
    final tempDir = await getTemporaryDirectory();
    final targetDir = Directory('${tempDir.path}/open_jtalk_dic');
    if (!await targetDir.exists()) {
      await targetDir.create();
    }
    // TODO: 実際の辞書ファイルをすべて targetDir にコピーする処理
    return targetDir.path;
  }

  Future<String> _copyAssetToFile(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final targetFile = File('${tempDir.path}/$fileName');

    if (!await targetFile.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await targetFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return targetFile.path;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
