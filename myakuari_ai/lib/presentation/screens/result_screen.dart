import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/inference_models.dart';
import '../widgets/character_view.dart';
import '../widgets/radar_chart.dart';
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

  // シミュレーション用のステート
  late int _simulatedScore;
  late Map<String, double> _simulatedRadar;

  @override
  void initState() {
    super.initState();
    _simulatedScore = widget.result.loveScore;
    _simulatedRadar = Map.from(widget.result.radarData);
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
      // Cloudflare WorkerのURLを構築
      // ※実際にはデプロイしたWorkerのURLに書き換えてください
      final workerUrl = 'https://myakuari-ogp.your-worker-subdomain.workers.dev';
      final shareUrl = '$workerUrl?score=$_simulatedScore&label=${Uri.encodeComponent(widget.result.labelText)}';
      
      await Share.share('【恋愛診断AI君: SYSTEM_DIAGNOSTICS】\n私の絶望スコアは ${_simulatedScore}% でした。\n\n詳細な分析結果はこちら:\n$shareUrl\n#恋愛診断AI君 #ずんだもん #EdgeTransformer');
    } catch (e) {
      debugPrint('Share Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color systemColor = widget.result.label == Label.like ? AppTheme.systemGreen : (widget.result.label == Label.neutral ? AppTheme.warningAmber : AppTheme.alertRed);
    CharacterState charState = widget.result.label == Label.like ? CharacterState.announceGood : (widget.result.label == Label.neutral ? CharacterState.thinking : CharacterState.announceBad);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/grid_bg.png', repeat: ImageRepeat.repeat),
            ),
          ),
          RepaintBoundary(
            key: _shareKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(systemColor),
                  _buildDiagnosticsSummary(systemColor),
                  _buildRadarAndVisuals(systemColor),
                  _buildSimulationPanel(systemColor),
                  _buildAttentionHeatmap(systemColor),
                  _buildDialoguePanel(charState, systemColor),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureAndShare,
        backgroundColor: systemColor.withOpacity(0.2),
        icon: Icon(Icons.share, color: systemColor),
        label: Text('SHARE_REPORT', style: TextStyle(color: systemColor)),
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
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
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
                  value: _simulatedScore / 100,
                  backgroundColor: Colors.white12,
                  color: color,
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 16),
              Text('${_simulatedScore}%', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('CONFIDENCE_LEVEL: ${widget.result.confidence.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRadarAndVisuals(Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.2)),
                color: Colors.black45,
              ),
              child: RadarChartWidget(
                values: _simulatedRadar,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildFeatureImportanceMap(color),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationPanel(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.3)),
        color: const Color(0xFF00FFFF).withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF00FFFF), size: 16),
              const SizedBox(width: 8),
              const Text('WHAT-IF SIMULATION ENGINE', style: TextStyle(color: Color(0xFF00FFFF), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('「もしあの時こうしていたら？」パラメータを操作して未来を再計算するのだ。', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          _buildSimSlider('アプローチ積極性 (Initiative)', '魅力', const Color(0xFF00FFFF)),
          _buildSimSlider('連絡頻度 (Frequency)', '楽しさ', const Color(0xFF00FFFF)),
          _buildSimSlider('声の自信 (Vocal Dominance)', '誠実', const Color(0xFF00FFFF)),
        ],
      ),
    );
  }

  Widget _buildSimSlider(String label, String radarKey, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Slider(
          value: _simulatedRadar[radarKey] ?? 0.5,
          min: 0.1,
          max: 1.0,
          activeColor: color,
          inactiveColor: color.withOpacity(0.2),
          onChanged: (val) {
            setState(() {
              _simulatedRadar[radarKey] = val;
              // 簡易的なスコア再計算ロジック（本来はEdge-Transformerの再推論を叩く）
              double avg = _simulatedRadar.values.reduce((a, b) => a + b) / _simulatedRadar.length;
              _simulatedScore = (avg * 100).toInt().clamp(0, 100);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAttentionHeatmap(Color color) {
    final keys = widget.result.attentionMap.keys.toList();
    if (keys.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELF_ATTENTION_WEIGHT_MATRIX', style: TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth / (keys.length + 1);
              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: size),
                      ...keys.map((k) => SizedBox(width: size, child: Center(child: Text(k.substring(0, 1), style: const TextStyle(fontSize: 8, color: Colors.white54))))),
                    ],
                  ),
                  ...keys.map((i) => Row(
                    children: [
                      SizedBox(width: size, child: Text(i.substring(0, 1), style: const TextStyle(fontSize: 8, color: Colors.white54))),
                      ...keys.map((j) {
                        final val = widget.result.attentionMap[i]![j] ?? 0.0;
                        return Container(
                          width: size,
                          height: size,
                          margin: const EdgeInsets.all(1),
                          color: color.withOpacity(val.clamp(0.0, 1.0)),
                        );
                      }),
                    ],
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureImportanceMap(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SHAP_VALUES', style: TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 12),
        ...widget.result.featureImportance.entries.take(4).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
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
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _deepAnalysis ?? 'DECRYPTING_SIGNAL...',
                style: GoogleFonts.notoSansJp(fontSize: 13, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
