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

class _BrutalistSplashScreenState extends State<BrutalistSplashScreen> {
  final List<String> _logs = [];
  final Random _rnd = Random();
  late Timer _timer;
  int _step = 0;

  final List<String> _bootSequence = [
    'システム初期化中...',
    'メモリチェック... 正常確認 (ゼロコピーバッファ)',
    '推論カーネルロード完了',
    '音声解析エンジン (FFT/リアルタイムスペクトラム) 起動',
    'Edge-Transformer重みファイル展開中...',
    '量子化形式: 4-bit NF4',
    'アテンションヘッド数: 8',
    'レイヤー数: 6',
    '学習モデル重みの検証... 正常',
    'ユーザーインターフェース起動中...',
  ];

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_step < _bootSequence.length) {
          _logs.add('> ${_bootSequence[_step]}');
          HapticFeedback.lightImpact(); // バイブレーションで物理的な起動感を演出
          _step++;
        } else if (_step < _bootSequence.length + 10) {
          // メモリ番地のようなダミーログを高速で流す
          _logs.add('  0x${_rnd.nextInt(0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')} : MEM_OK');
          if (_step % 3 == 0) HapticFeedback.selectionClick();
          _step++;
        } else {
          timer.cancel();
          HapticFeedback.heavyImpact(); // 起動完了の強い振動
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionDuration: Duration.zero, // 瞬時に切り替える（無骨さ）
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var log in _logs)
              Text(
                log,
                style: const TextStyle(
                  color: Color(0xFF00FF00), // 古いターミナルの緑
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 8),
            // カーソル点滅
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value > 0.5 ? 1.0 : 0.0,
                  child: Container(
                    width: 10,
                    height: 14,
                    color: const Color(0xFF00FF00),
                  ),
                );
              },
              onEnd: () {
                setState(() {}); // ループさせるためのハック
              },
            ),
          ],
        ),
      ),
    );
  }
}
