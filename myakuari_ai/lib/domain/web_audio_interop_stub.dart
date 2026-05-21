import 'dart:async';
import 'web_audio_interop_base.dart';

class WebAudioInterop {
  bool get isRecording => false;

  void startScan(Duration timeout) {}
  void stopScan() {}
  AudioScanState getState() => const AudioScanState();

  Future<String> transcribeAudio(Duration timeout) async {
    return '';
  }

  static void openNewTab(String url) {}
}
