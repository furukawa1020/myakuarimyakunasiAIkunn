import 'package:flutter/material.dart';
import '../../domain/models/inference_models.dart';
import '../../domain/inference_engine.dart';
import '../widgets/character_view.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final InferenceInput input;

  const LoadingScreen({super.key, required this.input});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = '5W1Hを解析中...';

  @override
  void initState() {
    super.initState();
    _processInference();
  }

  Future<void> _processInference() async {
    // 演出のための擬似ロード時間
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _statusMessage = '特徴量を抽出中...');
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _statusMessage = '反事実シミュレーション実行中...');

    // 実際の推論
    final String? safetyError = InferenceEngine.checkSafety(widget.input);
    final InferenceResult result = InferenceEngine.analyze(widget.input);

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      if (safetyError != null) {
        // 安全フィルタ警告画面または結果画面でエラー処理
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(safetyError), backgroundColor: Colors.red));
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 200,
              child: CharacterView(state: CharacterState.thinking),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFFFF007F)),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 18, color: Color(0xFF00FFFF)),
            ),
          ],
        ),
      ),
    );
  }
}
