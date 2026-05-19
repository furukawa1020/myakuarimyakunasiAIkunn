import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'wizard_screen.dart';
import '../theme.dart';
import '../../domain/audio_signal_processor.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceScanScreen extends StatefulWidget {
  const VoiceScanScreen({super.key});

  @override
  State<VoiceScanScreen> createState() => _VoiceScanScreenState();
}

class _VoiceScanScreenState extends State<VoiceScanScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  final List<String> _logs = [];
  int _logStep = 0;
  String _transcribedText = '';
  final stt.SpeechToText _speech = stt.SpeechToText();

  final AudioSignalProcessor _audioProcessor = AudioSignalProcessor();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _startRealAudioScan();
  }

  Future<void> _startRealAudioScan() async {
    _addLog('MIC_ACTIVE: PORT 0x01');
    _addLog('REQUESTING HARDWARE PERMISSION...');
    
    // 文字起こしの初期化と開始
    bool sttAvailable = await _speech.initialize(
      onStatus: (status) => debugPrint('STT Status: $status'),
      onError: (errorNotification) => debugPrint('STT Error: $errorNotification'),
    );
    
    if (sttAvailable) {
      _addLog('SPEECH-TO-TEXT ENGINE INITIALIZED.');
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _transcribedText = result.recognizedWords;
          }
        },
        localeId: 'ja_JP',
      );
    }
    
    // 実際の音声キャプチャとFFT解析を実行 (約1秒)
    final features = await _audioProcessor.analyzeVoiceSentiment();
    
    // 音声認識が完了するまで少し待つ（最大3秒）
    if (sttAvailable) {
      _addLog('TRANSCRIBING VOCAL DATA...');
      await Future.delayed(const Duration(seconds: 2));
      _speech.stop();
      if (_transcribedText.isNotEmpty) {
        _addLog('TRANSCRIPTION SUCCESS: [${_transcribedText.length} chars]');
      } else {
        _addLog('NO CLEAR WORDS DETECTED.');
      }
    }

    _addLog('AUDIO STREAM CAPTURED (16kHz PCM).');
    _addLog('EXTRACTING MEL-FREQUENCY CEPSTRAL COEFFICIENTS...');
    await Future.delayed(const Duration(milliseconds: 300));
    
    _addLog('ANALYZING VOCAL JITTER...');
    await Future.delayed(const Duration(milliseconds: 300));
    _addLog('JITTER = ${features['Vocal_Jitter']?.toStringAsFixed(4)}');
    
    _addLog('ANALYZING VOCAL DOMINANCE...');
    await Future.delayed(const Duration(milliseconds: 300));
    _addLog('DOMINANCE = ${features['Vocal_Dominance']?.toStringAsFixed(4)}');
    
    _addLog('ENERGY PEAK = ${features['Energy_Peak']?.toStringAsFixed(4)}');
    
    await Future.delayed(const Duration(milliseconds: 300));
    _addLog('ACOUSTIC PROFILE LOCKED.');
    _addLog('ROUTING TO TEXT CONTEXT PROCESSOR...');
    
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WizardScreen(initialText: _transcribedText.isNotEmpty ? _transcribedText : null)),
      );
    }
  }

  void _addLog(String log) {
    if (!mounted) return;
    setState(() {
      _logs.add('> $log');
      _logStep++;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACOUSTIC_SCANNER_v2.1',
                style: TextStyle(color: Color(0xFF00FFFF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 40),
              
              // 擬似的なオシロスコープ波形
              Center(
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.3)),
                    color: const Color(0xFF00FFFF).withOpacity(0.05),
                  ),
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WavePainter(_waveController.value, _logStep),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'PLEASE SPEAK YOUR SITUATION ALOUD\n(状況を声に出してください)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // ターミナルログ
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Color(0xFF00FF00),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final int intensity;

  WavePainter(this.animationValue, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final midY = size.height / 2;
    
    // intensityに応じて波形の激しさが変わる
    final amp = 10.0 + (intensity * 5.0);

    path.moveTo(0, midY);
    for (double i = 0; i < size.width; i++) {
      final x = i;
      final y = midY + math.sin((i / 20) + (animationValue * 2 * math.pi)) * amp * math.sin(i / size.width * math.pi);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
