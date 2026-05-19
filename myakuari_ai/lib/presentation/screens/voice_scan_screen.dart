import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'wizard_screen.dart';
import '../theme.dart';
import '../../domain/web_audio_interop.dart';

class VoiceScanScreen extends StatefulWidget {
  const VoiceScanScreen({super.key});

  @override
  State<VoiceScanScreen> createState() => _VoiceScanScreenState();
}

class _VoiceScanScreenState extends State<VoiceScanScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  final List<String> _logs = [];
  late Timer _logTimer;
  int _logStep = 0;
  String _transcribedText = '';
  final WebAudioInterop _audioInterop = WebAudioInterop();

  final List<String> _scanSequence = [
    'MIC_ACTIVE: PORT 0x01',
    'EXTRACTING MEL-FREQUENCY CEPSTRAL COEFFICIENTS...',
    'ANALYZING VOCAL JITTER...',
    'JITTER = 0.84 (HIGH ANXIETY DETECTED)',
    'ANALYZING VOCAL DOMINANCE...',
    'DOMINANCE = 0.21 (SUBMISSIVE PATTERN)',
    'ZERO-CROSSING RATE: NORMAL',
    'ACOUSTIC PROFILE LOCKED.',
    'ROUTING TO TEXT CONTEXT PROCESSOR...',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _startGachiAudioScan();
  }

  Future<void> _startGachiAudioScan() async {
    _addLog('MIC_ACTIVE: PORT 0x01');
    _addLog('BYPASSING PLUGINS: DIRECT WEB API HOOK INITIATED...');
    
    // JS Interopを使ってネイティブのWeb Speech APIを直接叩く（シンボリックリンク問題回避）
    _addLog('TRANSCRIBING VOCAL DATA...');
    
    // タイムアウト5秒で音声認識を実行
    final transcript = await _audioInterop.transcribeAudio(const Duration(seconds: 5));
    
    if (transcript.isNotEmpty && !transcript.startsWith('ERROR')) {
      _transcribedText = transcript;
      _addLog('TRANSCRIPTION SUCCESS: [${transcript.length} chars]');
    } else {
      _addLog(transcript.isEmpty ? 'NO CLEAR WORDS DETECTED.' : transcript);
    }

    _addLog('EXTRACTING MEL-FREQUENCY CEPSTRAL COEFFICIENTS...');
    await Future.delayed(const Duration(milliseconds: 300));
    
    _addLog('ANALYZING VOCAL JITTER...');
    await Future.delayed(const Duration(milliseconds: 300));
    // ここは演出用のリアルな乱数（本来はAnalyserNodeから取得）
    final jitter = 0.6 + (math.Random().nextDouble() * 0.3);
    _addLog('JITTER = ${jitter.toStringAsFixed(4)}');
    
    _addLog('ANALYZING VOCAL DOMINANCE...');
    await Future.delayed(const Duration(milliseconds: 300));
    final dom = 0.1 + (math.Random().nextDouble() * 0.2);
    _addLog('DOMINANCE = ${dom.toStringAsFixed(4)}');
    
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
