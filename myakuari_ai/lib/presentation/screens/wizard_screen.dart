import 'package:flutter/material.dart';
import '../../domain/models/inference_models.dart';
import '../../domain/bundled_voice_service.dart';
import 'loading_screen.dart';
import '../widgets/character_view.dart';
import '../widgets/glass_card.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  BundledVoiceService? _tts;

  // 各質問ページのずんだもんセリフ
  static const List<String> _questionLines = [
    'まず、気になっている相手は誰なのだ！関係性を教えてほしいのだ！',
    'なるほどー。で、何があったのだ？詳しく教えてほしいのだ！',
    'ふむふむ。それはいつのことなのだ？',
    'どんな場面だったのだ？LINE？直接？',
    'どうしてそう感じたのだ？自分の解釈を教えてほしいのだ！',
    'なるほどなのだ！どんな流れで起きたのだ？',
  ];

  // Answers
  String _who = '';
  String _what = '';
  String _when = '';
  String _where = '';
  String _why = '';
  String _how = '';
  int _contactFrequency = 3;
  String _initiative = '';
  String _concreteness = '';
  String _continuation = '';
  int _evidenceLevel = 3;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _tts = BundledVoiceService();
      _speak(0);
    } catch (_) {}
  }

  Future<void> _speak(int pageIndex) async {
    if (_tts == null) return;
    try {
      await _tts!.playQuestion(pageIndex);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts?.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Done, submit
      final input = InferenceInput(
        who: _who.isEmpty ? '不明' : _who,
        what: _what.isEmpty ? '不明' : _what,
        when: _when.isEmpty ? '不明' : _when,
        where: _where.isEmpty ? '不明' : _where,
        why: _why.isEmpty ? '不明' : _why,
        how: _how.isEmpty ? '不明' : _how,
        contactFrequency: _contactFrequency,
        initiative: _initiative.isEmpty ? '半々' : _initiative,
        concreteness: _concreteness.isEmpty ? '止まる' : _concreteness,
        continuation: _continuation.isEmpty ? '途切れた' : _continuation,
        evidenceLevel: _evidenceLevel,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoadingScreen(input: input)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('質問 ${_currentPage + 1} / 6'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Mascot
          Positioned(
            right: -60,
            bottom: -20,
            height: MediaQuery.of(context).size.height * 0.5,
            child: const CharacterView(state: CharacterState.listening),
          ),
          
          SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentPage + 1) / 6,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FFFF)),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                    _speak(idx);
                  },
                    children: [
                      _buildTextQuestion('Who', '相手は誰？関係性は？', '例: 職場の同僚でよく話す仲', (val) => _who = val, _who),
                      _buildTextQuestion('What', '何があったの？', '例: ランチに誘われた', (val) => _what = val, _what),
                      _buildChoiceQuestion('When', 'いつの事？', ['今日', '昨日', '今週', '先週', 'それ以前'], (val) => _when = val, _when),
                      _buildChoiceQuestion('Where', 'どんな文脈？', ['対面', 'LINE', '通話', '飲み', '職場/学校', 'その他'], (val) => _where = val, _where),
                      _buildTextQuestion('Why', 'どうしてそう思った？（自分の解釈）', '例: 普段誘ってこないのに珍しい', (val) => _why = val, _why),
                      _buildTextQuestion('How', 'どんな流れだった？', '例: 趣味の話から自然な流れで', (val) => _how = val, _how),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextQuestion(String title, String desc, String hint, Function(String) onChanged, String initVal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(desc, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                TextField(
                  onChanged: onChanged,
                  controller: TextEditingController(text: initVal)..selection = TextSelection.collapsed(offset: initVal.length),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildNextBtn(initVal.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildChoiceQuestion(String title, String desc, List<String> choices, Function(String) onChanged, String currentVal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(desc, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: choices.map((c) {
                    final isSel = c == currentVal;
                    return ChoiceChip(
                      label: Text(c, style: TextStyle(fontSize: 16, color: isSel ? Colors.white : Colors.white70)),
                      selected: isSel,
                      selectedColor: const Color(0xFFFF007F),
                      backgroundColor: Colors.black.withOpacity(0.3),
                      onSelected: (sel) {
                        if (sel) {
                          setState(() => onChanged(c));
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildNextBtn(currentVal.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildSliderQuestion(String title, String desc, Function(double) onChanged, double currentVal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(desc, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 40),
                Slider(
                  value: currentVal,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: currentVal.toInt().toString(),
                  activeColor: const Color(0xFFFF007F),
                  inactiveColor: Colors.black.withOpacity(0.3),
                  onChanged: (val) {
                    setState(() => onChanged(val));
                  },
                ),
                Center(
                  child: Text(
                    currentVal.toInt().toString(),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFFF007F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildNextBtn(true), // Slider always has a value
        ],
      ),
    );
  }

  Widget _buildNextBtn(bool isReady) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF007F), // Neon pink
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isReady ? _nextPage : null,
        child: Text(_currentPage == 5 ? '解析開始' : '次へ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
