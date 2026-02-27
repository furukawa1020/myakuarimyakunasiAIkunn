import 'package:flutter/material.dart';
import 'wizard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import '../widgets/character_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // ── 背景グラデーション（ゲームっぽい暗い背景） ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0015), Color(0xFF0D0A2E), Color(0xFF000E1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── 背景の輝き（ネオングロー） ──
          Positioned(
            top: h * 0.05,
            left: -w * 0.3,
            child: Container(
              width: w * 0.9,
              height: w * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF007F).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: h * 0.2,
            right: -w * 0.3,
            child: Container(
              width: w * 0.8,
              height: w * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00FFFF).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── キャラクター（右下に大きく） ──
          Positioned(
            right: -10,
            bottom: 90,
            height: h * 0.46,
            child: const CharacterView(state: CharacterState.idle),
          ),

          // ── メインコンテンツ ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── タイトル ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1行目: 「脈アリ！？」「脈ナシ！？」 横並び
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            _OutlinedText(
                              '脈アリ！？',
                              fontSize: 42,
                              fillColor: const Color(0xFFFF2060),
                              strokeColor: Colors.white,
                              strokeWidth: 6,
                            ),
                            const SizedBox(width: 8),
                            _OutlinedText(
                              '脈ナシ！？',
                              fontSize: 42,
                              fillColor: const Color(0xFF00CFFF),
                              strokeColor: Colors.white,
                              strokeWidth: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 2行目
                      _OutlinedText(
                        '教えて！AI君！',
                        fontSize: 38,
                        fillColor: const Color(0xFFFFE033),
                        strokeColor: const Color(0xFFAA7000),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── 説明吹き出し（左半分で表示） ──
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF007F), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF007F).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '完全ローカル恋愛推論AI！',
                          style: TextStyle(
                            color: Color(0xFFCC0050),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Love Inference Engine v1.0',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'あのひと言が気になるなら、\nAIに全部ぶちまけて！\n脈アリ・脈ナシを\nズバリ教えます🔥',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── ボタン群 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // スタートボタン
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF0066), Color(0xFFFF6B00)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF0066).withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WizardScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text(
                              '🔥  推論スタート  🔥',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // サブボタン（履歴 / 設定 / 情報）
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SubButton(
                            icon: Icons.history,
                            label: '履歴',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                          ),
                          _SubButton(
                            icon: Icons.settings,
                            label: '設定',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          ),
                          _SubButton(
                            icon: Icons.info_outline,
                            label: '概要',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
}

/// 縁取り文字ウィジェット
class _OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  const _OutlinedText(
    this.text, {
    required this.fontSize,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.1,
    );
    return Stack(
      children: [
        // 縁取り（外側）
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // 塗り（内側）
        Text(
          text,
          style: style.copyWith(color: fillColor),
        ),
      ],
    );
  }
}

/// サブメニューボタン
class _SubButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SubButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
