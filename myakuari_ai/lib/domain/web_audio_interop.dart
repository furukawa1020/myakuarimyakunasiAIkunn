import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// dart:js_interop の @JS アノテーションで index.html の関数を直接バインド
import 'dart:js_interop';

@JS('startAudioScan')
external void _jsStartAudioScan(int timeoutMs);

@JS('stopAudioScan')
external void _jsStopAudioScan();

@JS('getAudioState')
external String _jsGetAudioState();

/// リアルタイム音声解析の状態スナップショット
class AudioScanState {
  final bool recording;
  final String transcript;        // 確定済みテキスト
  final String interimTranscript; // 認識中（リアルタイム）
  final int rms;                  // 音量 0-100
  final int jitter;               // 声の揺れ(ZCR) 0-100
  final int dominantFreqHz;       // 主要周波数 Hz
  final List<int> spectrum;       // FFT 16バンド 0-255

  const AudioScanState({
    this.recording = false,
    this.transcript = '',
    this.interimTranscript = '',
    this.rms = 0,
    this.jitter = 0,
    this.dominantFreqHz = 0,
    this.spectrum = const [],
  });

  factory AudioScanState.fromJson(Map<String, dynamic> j) => AudioScanState(
    recording:          j['recording'] as bool? ?? false,
    transcript:         j['transcript'] as String? ?? '',
    interimTranscript:  j['interimTranscript'] as String? ?? '',
    rms:                (j['rms'] as num?)?.toInt() ?? 0,
    jitter:             (j['jitter'] as num?)?.toInt() ?? 0,
    dominantFreqHz:     (j['dominantFreqHz'] as num?)?.toInt() ?? 0,
    spectrum:           (j['spectrum'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
  );

  String get fullTranscript => interimTranscript.isNotEmpty
      ? '$transcript $interimTranscript'
      : transcript;
}

/// Web Audio API + Web Speech API を index.html のJSブリッジ経由で操作する
class WebAudioInterop {
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// マイクを起動して音声スキャンを開始
  void startScan(Duration timeout) {
    if (!kIsWeb) return;
    _isRecording = true;
    try {
      _jsStartAudioScan(timeout.inMilliseconds);
    } catch (e) {
      _isRecording = false;
    }
  }

  /// スキャンを停止
  void stopScan() {
    if (!kIsWeb) return;
    _isRecording = false;
    try {
      _jsStopAudioScan();
    } catch (_) {}
  }

  /// 現在の音声解析状態をポーリング（80ms間隔のJSループ結果を読む）
  AudioScanState getState() {
    if (!kIsWeb) return const AudioScanState();
    try {
      final raw = _jsGetAudioState();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AudioScanState.fromJson(map);
    } catch (_) {
      return const AudioScanState();
    }
  }

  /// [timeout] 後に確定した文字起こしテキストを返す（旧API互換）
  Future<String> transcribeAudio(Duration timeout) async {
    startScan(timeout);
    await Future.delayed(timeout + const Duration(milliseconds: 500));
    final state = getState();
    stopScan();
    return state.transcript;
  }
}
