import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'home_screen.dart';

class BrutalistSplashScreen extends StatefulWidget {
  const BrutalistSplashScreen({super.key});

  @override
  State<BrutalistSplashScreen> createState() => _BrutalistSplashScreenState();
}

class _BrutalistSplashScreenState extends State<BrutalistSplashScreen> with TickerProviderStateMixin {
  final List<HeartParticle> _particles = [];
  final Random _rnd = Random();
  late AnimationController _particleController;
  late AnimationController _titleController;
  late AnimationController _mainTitleController;

  late Animation<double> _myakuBounce;
  late Animation<double> _nashiBounce;
  late Animation<double> _aiKunBounce;
  late Animation<double> _aiKunScale;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();

    // 1. ハート粒子用のアニメーションループ
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
    _particleController.repeat();

    // 2. タイトル第1段階：「脈アリ！？脈ナシ！？」のバウンス
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _myakuBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    _nashiBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.3, 0.8, curve: Curves.bounceOut),
      ),
    );

    // 3. タイトル第2段階：「教えて！ＡＩ君！」のゲーム風バウンド
    _mainTitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _aiKunBounce = Tween<double>(begin: -300.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainTitleController,
        curve: const Interval(0.1, 0.7, curve: Curves.bounceOut),
      ),
    );

    _aiKunScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainTitleController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 演出シーケンス開始
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // 最初に「脈アリ！？脈ナシ！？」を開始
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    
    // 「教えて！ＡＩ君！」を開始
    HapticFeedback.mediumImpact();
    _mainTitleController.forward();

    // 4.0秒後にホームへ遷移
    await Future.delayed(const Duration(milliseconds: 2600));
    HapticFeedback.heavyImpact();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      // 毎フレーム一定確率で新しいハートを湧き出させる
      if (_particles.length < 50 && _rnd.nextDouble() < 0.25) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        _particles.add(
          HeartParticle(
            x: screenWidth / 2 + _rnd.nextDouble() * 120 - 60,
            y: screenHeight + 20,
            speed: _rnd.nextDouble() * 2.5 + 1.5,
            size: _rnd.nextDouble() * 0.8 + 0.4,
            angle: _rnd.nextDouble() * 0.4 - 0.2,
            alpha: 1.0,
            drift: _rnd.nextDouble() * 1.5 - 0.75,
            color: _rnd.nextBool()
                ? const Color(0xFFFF4E88) // ネオンピンク
                : const Color(0xFFFFB5DA), // パステルローズ
          ),
        );
      }

      // 粒子の座標と透明度更新
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.y -= p.speed;
        p.x += p.drift;
        p.alpha -= 0.008; // 徐々に消える
        p.angle += 0.01;

        if (p.y < -50 || p.alpha <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _titleController.dispose();
    _mainTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 深みのあるミッドナイトグラデーション背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF130524),
                  Color(0xFF280B3B),
                  Color(0xFF550C48),
                ],
              ),
            ),
          ),

          // 2. ハートカスタムペイント（背後で湧き出る）
          CustomPaint(
            painter: HeartPainter(_particles),
            child: Container(),
          ),

          // 3. メインの文字アニメーション
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 脈アリ！？ 脈ナシ！？
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _myakuBounce,
                      child: _buildStrokeText('脈アリ！？', const Color(0xFFFF2A7A), 28),
                    ),
                    const SizedBox(width: 24),
                    ScaleTransition(
                      scale: _nashiBounce,
                      child: _buildStrokeText('脈ナシ！？', const Color(0xFF00E5FF), 28),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 教えて！ＡＩ君！
                AnimatedBuilder(
                  animation: _mainTitleController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _aiKunBounce.value),
                      child: Transform.scale(
                        scale: _aiKunScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFB5DA).withOpacity(0.3), width: 1.5),
                        ),
                        child: _buildStrokeText('教えて！ＡＩ君！', const Color(0xFFFEE600), 46, outlineColor: const Color(0xFF5E095E)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Columbia Dating Engine Loaded',
                        style: TextStyle(
                          color: const Color(0xFFFFB5DA).withOpacity(0.6),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
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

  // 縁取り付きのゲームタイトル風テキストウィジェット
  Widget _buildStrokeText(String text, Color fillColor, double fontSize, {Color outlineColor = Colors.black}) {
    return Stack(
      children: [
        // 縁取り（太め）
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..color = outlineColor,
          ),
        ),
        // 内側の文字本体
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: fillColor,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: fillColor.withOpacity(0.5),
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HeartParticle {
  double x;
  double y;
  double speed;
  double size;
  double angle;
  double alpha;
  double drift;
  Color color;

  HeartParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.angle,
    required this.alpha,
    required this.drift,
    required this.color,
  });
}

class HeartPainter extends CustomPainter {
  final List<HeartParticle> particles;
  HeartPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);
      canvas.scale(p.size);

      final path = Path();
      // ハートのパス描画
      path.moveTo(0, -8);
      path.cubicTo(-12, -20, -24, -8, 0, 12);
      path.cubicTo(24, -8, 12, -20, 0, -8);
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant HeartPainter oldDelegate) => true;
}
