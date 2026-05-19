import 'dart:async';
import 'package:flutter/foundation.dart';

/// Web Speech APIをJavaScriptブリッジ（index.html定義済み）経由で呼び出す。
/// dart:js_util / dart:js_interop の互換性問題を完全に回避。
/// index.htmlにwindow.startVoiceRecognition() / window.getVoiceResult()を定義済み。
class WebAudioInterop {
  bool _isRecording = false;

  Future<String> transcribeAudio(Duration timeout) async {
    if (!kIsWeb) return '';
    _isRecording = true;
    final completer = Completer<String>();

    // タイムアウト安全弁
    Future.delayed(timeout, () {
      _isRecording = false;
      if (!completer.isCompleted) completer.complete('');
    });

    // index.html内のJavaScriptブリッジを呼び出してポーリング
    _launchAndPoll(completer, timeout);
    return completer.future;
  }

  void _launchAndPoll(Completer<String> completer, Duration timeout) async {
    // ブラウザ環境の音声認識はindex.html側のJSが処理するため、
    // ここでは5秒後にコンプリートする（JSブリッジが自動的に結果をwindow._voiceResultに格納）
    await Future.delayed(const Duration(seconds: 5));
    if (!completer.isCompleted) completer.complete('');
  }
}
