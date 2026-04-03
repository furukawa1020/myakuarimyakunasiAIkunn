import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'models/inference_models.dart';

// FFI 定義
typedef NativeRunRubyInference = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> script, ffi.Pointer<Utf8> input);
typedef DartRunRubyInference = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> script, ffi.Pointer<Utf8> input);

typedef NativeFreePointer = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef DartFreePointer = void Function(ffi.Pointer<Utf8> ptr);

/// Ruby (mruby) をネイティブ組み込みして実行するエンジン
class RubyInferenceEngine {
  static final RubyInferenceEngine _instance = RubyInferenceEngine._internal();
  factory RubyInferenceEngine() => _instance;
  RubyInferenceEngine._internal();

  ffi.DynamicLibrary? _dylib;
  DartRunRubyInference? _runInference;
  DartFreePointer? _freeResult;

  bool _initialized = false;
  String? _cachedScript;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Ruby スクリプトのロード
      _cachedScript = await rootBundle.loadString('assets/ml/inference_logic.rb');

      // 2. ネイティブライブラリのロード (CMake でビルドされる想定)
      // Android: libmruby_bridge.so, iOS: Framework/dylib
      // ※現在はビルド前のスタブとして例外をキャッチ
      _dylib = ffi.DynamicLibrary.open('libmruby_bridge.so');

      _runInference = _dylib!
          .lookupFunction<NativeRunRubyInference, DartRunRubyInference>(
              'run_ruby_inference');
      
      _freeResult = _dylib!
          .lookupFunction<NativeFreePointer, DartFreePointer>(
              'free_ruby_result');

      _initialized = true;
    } catch (e) {
      print('Ruby Native Engine failed to load: $e. Falling back to Dart-only mode.');
      _initialized = false;
    }
  }

  Future<InferenceResult?> analyze(InferenceInput input) async {
    if (!_initialized || _cachedScript == null) return null;

    final inputJson = jsonEncode({
      'who': input.who,
      'what': input.what,
      'when': input.when,
      'where': input.where,
      'why': input.why,
      'how': input.how,
      'contactFrequency': input.contactFrequency,
      'initiative': input.initiative,
      'concreteness': input.concreteness,
      'continuation': input.continuation,
      'evidenceLevel': input.evidenceLevel,
    });

    final scriptPtr = _cachedScript!.toNativeUtf8();
    final inputPtr = inputJson.toNativeUtf8();

    try {
      final resultPtr = _runInference!(scriptPtr, inputPtr);
      final resultJson = resultPtr.toDartString();
      
      // ネイティブ側で確保されたメモリを解放
      _freeResult!(resultPtr);

      final Map<String, dynamic> data = jsonDecode(resultJson);
      
      // InferenceResult へのマッピング (簡略化)
      return InferenceResult(
        label: _parseLabel(data['label']),
        labelText: data['label'],
        loveScore: data['score'],
        confidence: 0.9,
        compatibilityGrade: _calculateGrade(data['score']),
        radarData: {'Ruby解析': (data['score'] / 100.0)},
        topFactors: (data['details'] as List).map((d) => Factor(
            id: 'ruby', title: 'Ruby解析', description: d, scoreImpact: 10, reason: d
          )).toList(),
        graph: GraphData(nodes: [], edges: []),
        counterfactuals: [],
        nextActions: ['Rubyエンジン駆動中'],
        spokenScript: 'Rubyエンジンによる日本版チューニング済みの結果なのだ！　' + (data['details'] as List).join(' '),
      );
    } finally {
      malloc.free(scriptPtr);
      malloc.free(inputPtr);
    }
  }

  Label _parseLabel(String? label) {
    if (label == '脈アリ') return Label.like;
    if (label == '脈ナシ') return Label.nope;
    return Label.neutral;
  }

  String _calculateGrade(int score) {
    if (score >= 85) return 'S';
    if (score >= 70) return 'A';
    if (score >= 50) return 'B';
    if (score >= 30) return 'C';
    return 'D';
  }
}
