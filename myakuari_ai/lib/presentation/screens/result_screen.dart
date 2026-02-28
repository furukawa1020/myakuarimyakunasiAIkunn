import 'package:flutter/material.dart';
import '../../domain/models/inference_models.dart';
import '../widgets/character_view.dart';
import 'home_screen.dart';
import '../../domain/bundled_voice_service.dart';
import '../widgets/glass_card.dart';

import '../widgets/radar_chart.dart';

class ResultScreen extends StatefulWidget {
  final InferenceResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _playVoice();
  }

  Future<void> _playVoice() async {
    final tts = BundledVoiceService();
    final key = widget.result.label == Label.like
        ? 'result_good'
        : widget.result.label == Label.neutral
            ? 'result_neutral'
            : 'result_bad';
    await tts.playNamed(key);
  }

  @override
  Widget build(BuildContext context) {
    CharacterState charState;
    if (widget.result.label == Label.like) {
      charState = CharacterState.announceGood;
    } else if (widget.result.label == Label.neutral) {
      charState = CharacterState.announceNeutral;
    } else {
      charState = CharacterState.announceBad;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('恋愛診断レポート', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, size: 28),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.result.loveScore >= 70
                      ? [const Color(0xFF2D002D), const Color(0xFF160026), const Color(0xFF0A0015)]
                      : widget.result.loveScore >= 40
                          ? [const Color(0xFF00152D), const Color(0xFF000E1A), const Color(0xFF0A0015)]
                          : [const Color(0xFF151515), const Color(0xFF0A0A0A), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // キャラクター (固定配置)
          Positioned(
            right: -40,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: CharacterView(state: charState),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildMainDiagnosticSection(),
                  const SizedBox(height: 32),
                  _buildFactorsSection(),
                  const SizedBox(height: 32),
                  _buildActionsSection(),
                  const SizedBox(height: 250), // キャラの被り防止
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final scoreColor = widget.result.loveScore >= 50 ? const Color(0xFFFF007F) : const Color(0xFF00FFFF);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '総合判定: ${widget.result.labelText}',
                style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [scoreColor, scoreColor.withOpacity(0.6)],
                ).createShader(bounds),
                child: Text(
                  'Love Score: ${widget.result.loveScore}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
          _buildGradeBadge(),
        ],
      ),
    );
  }

  Widget _buildGradeBadge() {
    final grade = widget.result.compatibilityGrade;
    Color color;
    switch (grade) {
      case 'S': color = const Color(0xFFFF00FF); break;
      case 'A': color = const Color(0xFFFF007F); break;
      case 'B': color = const Color(0xFF00FFFF); break;
      case 'C': color = const Color(0xFF00FF00); break;
      case 'D': color = const Color(0xFFFF4500); break;
      default:  color = const Color(0xFFFFD700);
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.8), blurRadius: 20, spreadRadius: 3),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        grade,
        style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _buildMainDiagnosticSection() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: RadarChartWidget(
                values: widget.result.radarData,
                color: widget.result.label == Label.like ? const Color(0xFFFF007F) : const Color(0xFF00FFFF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'ずんだもんのアドバイス',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00FFFF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.result.spokenScript,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '【推論根拠: 主要要因】',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF007F)),
        ),
        const SizedBox(height: 16),
        ...widget.result.topFactors.take(3).map((f) => GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${f.scoreImpact > 0 ? '+' : ''}${f.scoreImpact}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: f.scoreImpact > 0 ? const Color(0xFFFF007F) : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(f.reason, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '【戦略アドバイス】',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00FFFF)),
        ),
        const SizedBox(height: 16),
        ...widget.result.nextActions.map((action) => GlassCard(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF00FFFF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(action, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }
}
