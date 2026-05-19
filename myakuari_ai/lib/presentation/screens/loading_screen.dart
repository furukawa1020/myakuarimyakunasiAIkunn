import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/inference_models.dart';
import '../../domain/inference_engine.dart';
import '../widgets/character_view.dart';
import 'result_screen.dart';
import '../../domain/ml_inference_engine.dart';
import '../theme.dart';

class LoadingScreen extends StatefulWidget {
  final InferenceInput input;

  const LoadingScreen({super.key, required this.input});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = '信号解読中...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _processInference();
  }

  Future<void> _processInference() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() { _statusMessage = 'ニューラルモデル展開中...'; _progress = 0.3; });
    
    await MLInferenceEngine.instance.load();

    if (mounted) setState(() { _statusMessage = '特徴ベクトルの抽出中...'; _progress = 0.6; });
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) setState(() { _statusMessage = 'ハイブリッド診断実行中...'; _progress = 0.9; });

    final InferenceResult result = await InferenceEngine.analyze(widget.input);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 180,
              child: CharacterView(state: CharacterState.thinking),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 240,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white10,
                    color: AppTheme.systemGreen,
                    minHeight: 2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: GoogleFonts.dotGothic16(
                      fontSize: 14, 
                      color: AppTheme.systemGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
