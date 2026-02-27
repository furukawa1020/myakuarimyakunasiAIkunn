import 'package:flutter/material.dart';
import '../../domain/models/inference_models.dart';
import '../widgets/character_view.dart';
import 'home_screen.dart';
import '../../domain/voicevox_service.dart';

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
    final tts = LocalVoicevoxService();
    // In a real app we would call initialize() during splash screen.
    await tts.initialize(); 
    await tts.speak(widget.result.spokenScript);
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
      appBar: AppBar(
        title: const Text('恋愛推論結果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
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
              color: const Color(0xFF121212),
            ),
          ),
          
          // キャラクター (固定配置)
          Positioned(
            right: -60,
            bottom: -20,
            height: MediaQuery.of(context).size.height * 0.4,
            child: CharacterView(state: charState),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreSection(),
                  const SizedBox(height: 32),
                  _buildFactorsSection(),
                  const SizedBox(height: 32),
                  // _buildGraphSection(), // 軽量版では一旦リストで代用するか、CustomPaintを使う
                  _buildCounterfactualSection(),
                  const SizedBox(height: 32),
                  _buildActionsSection(),
                  const SizedBox(height: 200), // キャラの被り防止の余白
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    Color labelColor = Colors.white;
    if (widget.result.label == Label.like) labelColor = const Color(0xFFFF007F);
    if (widget.result.label == Label.neutral) labelColor = const Color(0xFF00FFFF);
    if (widget.result.label == Label.nope) labelColor = Colors.blueGrey;

    return Center(
      child: Column(
        children: [
          Text(
            widget.result.labelText,
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: labelColor,
              shadows: [Shadow(color: labelColor.withOpacity(0.5), blurRadius: 20)],
            ),
          ),
          Text(
            'SCORE: ${widget.result.loveScore}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '推論自信度: ${(widget.result.confidence * 100).toInt()}%',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '【要因トップ5】',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FFFF)),
        ),
        const SizedBox(height: 16),
        ...widget.result.topFactors.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF1E1E1E),
              child: ListTile(
                leading: Text(
                  '${f.scoreImpact > 0 ? '+' : ''}${f.scoreImpact}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: f.scoreImpact > 0 ? const Color(0xFFFF007F) : Colors.blue,
                  ),
                ),
                title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${f.description}\n[根拠: ${f.reason}]'),
              ),
            )),
      ],
    );
  }

  Widget _buildCounterfactualSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '【反事実シミュレーション (What-if)】',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00FFFF)),
        ),
        const SizedBox(height: 16),
        ...widget.result.counterfactuals.map((cf) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: cf.isImprovement ? const Color(0xFFFF007F) : Colors.blueGrey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(cf.isImprovement ? Icons.trending_up : Icons.trending_down,
                      color: cf.isImprovement ? const Color(0xFFFF007F) : Colors.blueGrey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cf.description, style: const TextStyle(fontSize: 16)),
                        Text('予想スコア: ${widget.result.loveScore} → ${cf.newScore}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
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
          '【次の一手】',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FFFF)),
        ),
        const SizedBox(height: 16),
        ...widget.result.nextActions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👉', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(action, style: const TextStyle(fontSize: 18))),
                ],
              ),
            )),
      ],
    );
  }
}
