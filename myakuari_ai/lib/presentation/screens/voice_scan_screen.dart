import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'wizard_screen.dart';
import '../theme.dart';

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
    
    _logTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      setState(() {
        if (_logStep < _scanSequence.length) {
          _logs.add('> ${_scanSequence[_logStep]}');
          HapticFeedback.mediumImpact(); // ログが出るたびに振動
          _logStep++;
        } else {
          timer.cancel();
          HapticFeedback.heavyImpact();
          // 数秒後にWizardScreenへ遷移
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WizardScreen()));
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _logTimer.cancel();
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
