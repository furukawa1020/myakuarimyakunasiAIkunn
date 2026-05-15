import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/inference_models.dart';
import '../widgets/character_view.dart';
import '../theme.dart';
import '../../domain/bundled_voice_service.dart';
import '../../domain/gemma_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ResultScreen extends StatefulWidget {
  final InferenceResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String? _deepAnalysis;
  bool _isGenerating = false;
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _playVoice();
    _startDeepAnalysis();
  }

  Future<void> _startDeepAnalysis() async {
    setState(() => _isGenerating = true);
    final analysis = await GemmaService().generateDeepAnalysis(
      widget.result.input, 
      widget.result.loveScore, 
      widget.result.labelText
    );
    if (mounted) {
      setState(() {
        _deepAnalysis = analysis;
        _isGenerating = false;
      });
    }
  }

  Future<void> _playVoice() async {
    final tts = BundledVoiceService();
    final key = widget.result.label == Label.like ? 'result_good' : (widget.result.label == Label.neutral ? 'result_neutral' : 'result_bad');
    await tts.playNamed(key);
  }

  Future<void> _captureAndShare() async {
    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final xFile = XFile.fromData(pngBytes, mimeType: 'image/png', name: 'diagnosis_report.png');
      await Share.shareXFiles([xFile], text: '【恋愛診断AI君: SYSTEM_DIAGNOSTICS】\nスコア: ${widget.result.loveScore}\n判定: ${widget.result.labelText}\n#恋愛診断AI君 #ずんだもん');
    } catch (e) {
      debugPrint('Share Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color systemColor = widget.result.label == Label.like ? AppTheme.systemGreen : (widget.result.label == Label.neutral ? AppTheme.warningAmber : AppTheme.alertRed);
    CharacterState charState = widget.result.label == Label.like ? CharacterState.happy : (widget.result.label == Label.neutral ? CharacterState.thinking : CharacterState.sad);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RepaintBoundary(
        key: _shareKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(systemColor),
              _buildDiagnosticsSummary(systemColor),
              _buildFeatureImportanceMap(systemColor),
              _buildDialoguePanel(charState, systemColor),
              _buildStrategyLogs(systemColor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('REPORT_V2.0_SECURE', style: TextStyle(color: color, fontSize: 12, letterSpacing: 1.5)),
          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: color)),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsSummary(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANALYSIS_SUMMARY', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(widget.result.labelText, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.result.loveScore / 100,
                  backgroundColor: Colors.white12,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Text('${widget.result.loveScore}%', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('CONFIDENCE_LEVEL: ${widget.result.confidence.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFeatureImportanceMap(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEURAL_FEATURE_CONTRIBUTION (SHAP_VALUES)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          ...widget.result.featureImportance.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 12)),
                    Text('+${e.value.toStringAsFixed(1)}', style: TextStyle(color: color, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: e.value / 25,
                  backgroundColor: Colors.white12,
                  color: color.withOpacity(0.6),
                  minHeight: 2,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDialoguePanel(CharacterState state, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            height: 120,
            child: CharacterView(state: state),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _deepAnalysis ?? 'DECRYPTING_SIGNAL...',
                style: GoogleFonts.notoSansJp(fontSize: 14, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyLogs(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MITIGATION_STRATEGY_SEQUENCE', style: TextStyle(color: color, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 16),
          ...widget.result.nextActions.map((action) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('> EXECUTE: $action', style: const TextStyle(color: Colors.white, fontSize: 14)),
          )),
          if (widget.result.ikikokuWarning != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              color: AppTheme.alertRed.withOpacity(0.2),
              child: Text(widget.result.ikikokuWarning!, style: const TextStyle(color: AppTheme.alertRed, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
