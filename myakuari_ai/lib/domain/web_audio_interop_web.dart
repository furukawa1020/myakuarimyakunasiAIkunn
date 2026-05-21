import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'web_audio_interop_base.dart';

@JS('startAudioScan')
external void _jsStartAudioScan(int timeoutMs);

@JS('stopAudioScan')
external void _jsStopAudioScan();

@JS('getAudioState')
external String _jsGetAudioState();

@JS('openInNewTab')
external void _jsOpenInNewTab(String url);

class WebAudioInterop {
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  void startScan(Duration timeout) {
    _isRecording = true;
    try {
      _jsStartAudioScan(timeout.inMilliseconds);
    } catch (e) {
      _isRecording = false;
    }
  }

  void stopScan() {
    _isRecording = false;
    try {
      _jsStopAudioScan();
    } catch (_) {}
  }

  AudioScanState getState() {
    try {
      final raw = _jsGetAudioState();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AudioScanState.fromJson(map);
    } catch (_) {
      return const AudioScanState();
    }
  }

  Future<String> transcribeAudio(Duration timeout) async {
    startScan(timeout);
    await Future.delayed(timeout + const Duration(milliseconds: 500));
    final state = getState();
    stopScan();
    return state.transcript;
  }

  static void openNewTab(String url) {
    try {
      _jsOpenInNewTab(url);
    } catch (_) {}
  }
}
