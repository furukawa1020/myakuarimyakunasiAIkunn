import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicevox_core/voicevox_core.dart';
import 'package:audioplayers/audioplayers.dart';

class LocalVoicevoxService {
  static final LocalVoicevoxService _instance = LocalVoicevoxService._internal();
  factory LocalVoicevoxService() => _instance;
  LocalVoicevoxService._internal();

  Pointer<VoicevoxSynthesizer>? _synthesizer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  static const int _zundamonStyleId = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      
      // Since it's heavy, in production you should use flutter_assets extraction.
      // Here we assume the setup placed them directly on disk or we know the absolute path.
      // But for Android simulator, assets are bundled. Let's extract them.
      
      final dicDir = Directory('${tempDir.path}/open_jtalk_dic_utf_8-1.11');
      if (!await dicDir.exists()) {
        await dicDir.create(recursive: true);
        // Note: extracting hundreds of small assets dynamically is very slow.
        // It's better to rely on pre-setup paths or zip extraction.
        // For simplicity of this demo, we assume the user placed them next to the executable 
        // OR we use the predefined paths if they exist.
      }
      
      // Let's find absolute paths of the assets based on OS
      String dicPath = 'assets/voicevox/open_jtalk_dic_utf_8-1.11';
      String modelPath = 'assets/voicevox/zundamon.vvm';
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Fallback for mobile: extract vvm. Dict extraction is too complex for this snippet.
        modelPath = await _copyAssetToFile('assets/voicevox/zundamon.vvm', tempDir.path);
        // Warning: This implies open_jtalk must be manually placed or zipped.
        // We will try absolute path for emulator test...
      }

      print('Initializing Voicevox core (C FFI)...');
      
      // 1. Initialize Options
      final initializeOptions = voicevoxMakeDefaultInitializeOptions();
      
      // 2. Load ONNX
      final onnxruntime = calloc<Pointer<VoicevoxOnnxruntime>>();
      final loadOnnxruntimeOptions = voicevoxMakeDefaultLoadOnnxruntimeOptions();
      // Use correct function signature (taking Pointer<Pointer<...>>)
      var result = voicevoxOnnxruntimeLoadOnce(loadOnnxruntimeOptions, onnxruntime);
      if (result != VOICEVOX_RESULT_OK) {
        throw Exception(voicevoxErrorResultToMessage(result));
      }

      // 3. Init OpenJTalk
      final openJtalk = calloc<Pointer<OpenJtalkRc>>();
      result = voicevoxOpenJtalkRcNew(dicPath, openJtalk);
      if (result != VOICEVOX_RESULT_OK) {
         print("Warning: Failed to load open_jtalk. Did you download it? Synthesis will fail.");
      }

      // 4. Create Synthesizer
      final synthesizer = calloc<Pointer<VoicevoxSynthesizer>>();
      result = voicevoxSynthesizerNew(
        onnxruntime.value,
        openJtalk.value,
        initializeOptions,
        synthesizer,
      );
      
      // Cleanup early refs
      if (openJtalk.value != nullptr) voicevoxOpenJtalkRcDelete(openJtalk.value);
      calloc.free(openJtalk);
      calloc.free(onnxruntime);

      if (result != VOICEVOX_RESULT_OK) {
        throw Exception(voicevoxErrorResultToMessage(result));
      }

      // 5. Load Voice Model
      final model = calloc<Pointer<VoicevoxVoiceModelFile>>();
      result = voicevoxVoiceModelFileOpen(modelPath, model);
      if (result != VOICEVOX_RESULT_OK) {
        throw Exception(voicevoxErrorResultToMessage(result));
      }

      result = voicevoxSynthesizerLoadVoiceModel(synthesizer.value, model.value);
      voicevoxVoiceModelFileDelete(model.value);
      calloc.free(model);

      if (result != VOICEVOX_RESULT_OK) {
        throw Exception(voicevoxErrorResultToMessage(result));
      }

      _synthesizer = synthesizer.value;
      calloc.free(synthesizer);
      _isInitialized = true;
      print('Voicevox Core initialized successfully via FFI.');
    } catch (e) {
      print('Failed to initialize Voicevox Core: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || _synthesizer == null) {
      print('Voicevox is not initialized. Skipping audio.');
      return;
    }

    try {
      final outputWavSize = calloc<Uint64>();
      final outputWav = calloc<Pointer<Uint8>>();
      
      final result = voicevoxSynthesizerTts(
        _synthesizer!,
        text,
        _zundamonStyleId,
        voicevoxMakeDefaultTtsOptions(),
        outputWavSize,
        outputWav,
      );
      
      if (result != VOICEVOX_RESULT_OK) {
        throw Exception('TTS Failed: result code $result');
      }

      // Convert Pointer<Uint8> to Uint8List
      final wavData = outputWav.value.asTypedList(outputWavSize.value);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_speech.wav');
      await tempFile.writeAsBytes(wavData);

      // Free native memory allocated by core
      voicevoxWavFree(outputWav.value);
      calloc.free(outputWavSize);
      calloc.free(outputWav);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      print('Speech synthesis failed: $e');
    }
  }

  Future<String> _copyAssetToFile(String assetPath, String dirPath) async {
    final fileName = assetPath.split('/').last;
    final targetFile = File('$dirPath/$fileName');

    if (!await targetFile.exists()) {
      try {
        final byteData = await rootBundle.load(assetPath);
        await targetFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      } catch (e) {
         print("Warning: Could not copy $assetPath");
      }
    }
    return targetFile.path;
  }

  void dispose() {
    _audioPlayer.dispose();
    if (_synthesizer != null) {
      voicevoxSynthesizerDelete(_synthesizer!);
    }
  }
}
