import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wizard_screen.dart';
import 'history_screen.dart';
import 'voice_scan_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import '../widgets/character_view.dart';
import '../widgets/terminal_overlay.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background: Grid & Dark Space ──
          Positioned.fill(
            child: Container(
              color: AppTheme.background,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),

          // ── Terminal Log Overlay ──
          const Positioned.fill(
            child: TerminalOverlay(),
          ),

          // ── Character (Right Bottom) ──
          Positioned(
            right: -20,
            bottom: 40,
            height: h * 0.45,
            child: const CharacterView(state: CharacterState.idle),
          ),

          // ── Main Content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Technical Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: AppTheme.systemGreen,
                        child: const Text(
                          'システム稼働中',
                          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '恋愛波形解析エンジン',
                        style: TextStyle(
                          color: AppTheme.systemGreen.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '脈アリ！？\n脈ナシ！？\n教えて！AI君',
                        style: GoogleFonts.dotGothic16(
                          fontSize: 42,
                          height: 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(color: AppTheme.systemGreen, blurRadius: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Description Block ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: w * 0.7,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.systemGreen.withOpacity(0.3)),
                      color: AppTheme.systemGreen.withOpacity(0.05),
                    ),
                    child: const Text(
                      '対象者のバイタルシグナルを検出しました。声の周波数変化と状況データを解析し、恋愛感情の脈あり度を予測します。システム待機中。',
                      style: TextStyle(color: AppTheme.systemGreen, fontSize: 11, height: 1.5),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Action Buttons ──
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const WizardScreen()));
                          },
                          child: const Text('テキスト入力で診断する'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.vibrate();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceScanScreen()));
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00FFFF)),
                            foregroundColor: const Color(0xFF00FFFF),
                          ),
                          child: const Text('🎙 音声で診断する（状況を話すだけ！）'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _SmallTerminalButton(
                              label: '過去の診断記録',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallTerminalButton(
                              label: 'システム設定',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                            ),
                          ),
                        ],
                      ),
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

class _SmallTerminalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallTerminalButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2F3F).withOpacity(0.2)
      ..strokeWidth = 1;

    const double step = 40;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
