import 'package:flutter/material.dart';

import 'wizard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Mascot overlay placeholder
          Positioned(
            right: -40,
            bottom: -20,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Image.asset(
              'assets/images/zundamon_base.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    '脈アリ！？\n脈ナシ！？',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF007F), // Neon Pink
                      height: 1.1,
                      shadows: [
                        Shadow(color: Color(0xFFFF007F), blurRadius: 20)
                      ],
                    ),
                  ),
                  const Text(
                    '教えて！AI君！',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FFFF), // Neon Cyan
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.5)),
                    ),
                    child: const Text(
                      '「5W1Hから特徴量を抽出し、端末内で確率推論・反事実解析・推論グラフ生成まで実行して、脈アリ度・根拠・次の一手をExplainableに返す、完全ローカル恋愛推論AIです。」',
                      style: TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WizardScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF007F),
                        elevation: 10,
                        shadowColor: const Color(0xFFFF007F).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '推論スタート',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // History navigation
                      },
                      child: const Text('履歴を見る', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
