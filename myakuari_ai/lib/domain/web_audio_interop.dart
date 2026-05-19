import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Flutterプラグインの制約（Windowsシンボリックリンク問題）を回避するため、
/// ブラウザのネイティブAPI（Web Speech API & Web Audio API）を直接ハッキング（JS Interop）するクラス
class WebAudioInterop {
  dynamic _speechRecognition;
  bool _isRecording = false;

  WebAudioInterop() {
    if (kIsWeb) {
      // Chrome/Safariのネイティブ音声認識エンジンを直接フック
      if (js_util.hasProperty(html.window, 'SpeechRecognition')) {
        _speechRecognition = js_util.callConstructor(js_util.getProperty(html.window, 'SpeechRecognition'), []);
      } else if (js_util.hasProperty(html.window, 'webkitSpeechRecognition')) {
        _speechRecognition = js_util.callConstructor(js_util.getProperty(html.window, 'webkitSpeechRecognition'), []);
      }
    }
  }

  /// 音声認識を開始し、結果のテキストを返す
  Future<String> transcribeAudio(Duration timeout) async {
    if (_speechRecognition == null) return "音声認識APIがブラウザでサポートされていません";

    Completer<String> completer = Completer<String>();
    _isRecording = true;

    js_util.setProperty(_speechRecognition, 'lang', 'ja-JP');
    js_util.setProperty(_speechRecognition, 'interimResults', false);
    js_util.setProperty(_speechRecognition, 'maxAlternatives', 1);

    // コールバックの設定
    js_util.setProperty(_speechRecognition, 'onresult', js_util.allowInterop((event) {
      if (!_isRecording) return;
      _isRecording = false;
      
      final results = js_util.getProperty(event, 'results');
      final firstResult = js_util.getProperty(results, '0');
      final firstAlternative = js_util.getProperty(firstResult, '0');
      final transcript = js_util.getProperty(firstAlternative, 'transcript');
      
      if (!completer.isCompleted) completer.complete(transcript.toString());
    }));

    js_util.setProperty(_speechRecognition, 'onerror', js_util.allowInterop((event) {
      _isRecording = false;
      if (!completer.isCompleted) completer.complete("ERROR: 音声を検出できませんでした");
    }));

    js_util.setProperty(_speechRecognition, 'onend', js_util.allowInterop((event) {
      _isRecording = false;
      if (!completer.isCompleted) completer.complete("");
    }));

    // 録音開始
    try {
      js_util.callMethod(_speechRecognition, 'start', []);
    } catch (e) {
      return "ERROR: マイクアクセス拒否";
    }

    // タイムアウト処理
    Future.delayed(timeout, () {
      if (_isRecording) {
        _isRecording = false;
        js_util.callMethod(_speechRecognition, 'stop', []);
        if (!completer.isCompleted) completer.complete("タイムアウト");
      }
    });

    return completer.future;
  }
}
