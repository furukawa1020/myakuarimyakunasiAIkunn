import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CharacterState {
  idle,
  listening,
  thinking,
  announceGood,
  announceNeutral,
  announceBad,
  question,
  down,
  closing,
}

/// 状態ごとにコロコロ切り替わるスプライトのリスト
const Map<CharacterState, List<String>> _spriteSequences = {
  CharacterState.announceGood: [
    'assets/images/char/char_9.png',   // 超嬉しい
    'assets/images/char/char_3.png',   // 笑顔
    'assets/images/char/char_10.png',  // 喜び
    'assets/images/char/char_9.png',   // 超嬉しい（戻る）
  ],
  CharacterState.announceBad: [
    'assets/images/char/char_8.png',   // しょんぼり
    'assets/images/char/char_2.png',   // 落ち込み
    'assets/images/char/char_8.png',   // しょんぼり
    'assets/images/char/char_11.png',  // 沈む
  ],
  CharacterState.announceNeutral: [
    'assets/images/char/char_1.png',   // 普通
    'assets/images/char/char_4.png',   // 考え中
    'assets/images/char/char_1.png',   // 普通
    'assets/images/char/char_0.png',   // 待機
  ],
  CharacterState.thinking: [
    'assets/images/char/char_5.png',   // 考え中
    'assets/images/char/char_4.png',   // 疑問
    'assets/images/char/char_5.png',   // 考え中
    'assets/images/char/char_7.png',   // 別の考え
  ],
  CharacterState.listening: [
    'assets/images/char/char_10.png',  // 聞く
    'assets/images/char/char_3.png',   // 前のめり
    'assets/images/char/char_10.png',  // 聞く
    'assets/images/char/char_6.png',   // うなずき
  ],
  CharacterState.idle: [
    'assets/images/char/char_0.png',   // 待機
    'assets/images/char/char_1.png',   // ちょっと動く
    'assets/images/char/char_0.png',   // 待機
  ],
  CharacterState.question: [
    'assets/images/char/char_4.png',   // 疑問
    'assets/images/char/char_1.png',   // 普通
    'assets/images/char/char_4.png',   // 疑問
  ],
  CharacterState.down: [
    'assets/images/char/char_8.png',
    'assets/images/char/char_11.png',
    'assets/images/char/char_8.png',
  ],
  CharacterState.closing: [
    'assets/images/char/char_11.png',
    'assets/images/char/char_0.png',
  ],
};

/// 状態ごとの切り替え間隔
const Map<CharacterState, Duration> _switchIntervals = {
  CharacterState.announceGood:    Duration(milliseconds: 350),
  CharacterState.announceBad:     Duration(milliseconds: 700),
  CharacterState.announceNeutral: Duration(milliseconds: 900),
  CharacterState.thinking:        Duration(milliseconds: 500),
  CharacterState.listening:       Duration(milliseconds: 600),
  CharacterState.idle:            Duration(milliseconds: 2000),
  CharacterState.question:        Duration(milliseconds: 800),
  CharacterState.down:            Duration(milliseconds: 800),
  CharacterState.closing:         Duration(milliseconds: 1200),
};

class CharacterView extends ConsumerStatefulWidget {
  final CharacterState state;

  const CharacterView({super.key, required this.state});

  @override
  ConsumerState<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends ConsumerState<CharacterView> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  Timer? _spriteTimer;
  int _spriteIndex = 0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _startAnimation(widget.state);
  }

  @override
  void didUpdateWidget(covariant CharacterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _stopAnimation();
      _spriteIndex = 0;
      _startAnimation(widget.state);
    }
  }

  void _startAnimation(CharacterState state) {
    // バウンスアニメーション
    _bounceController.stop();
    switch (state) {
      case CharacterState.announceGood:
        _bounceController.repeat(reverse: true, period: const Duration(milliseconds: 300));
        break;
      case CharacterState.thinking:
        _bounceController.repeat(reverse: true, period: const Duration(milliseconds: 600));
        break;
      default:
        _bounceController.reset();
    }

    // スプライト切り替えタイマー
    final interval = _switchIntervals[state] ?? const Duration(seconds: 1);
    final sprites = _spriteSequences[state] ?? ['assets/images/char/char_0.png'];
    _spriteTimer = Timer.periodic(interval, (_) {
      if (mounted) {
        setState(() {
          _spriteIndex = (_spriteIndex + 1) % sprites.length;
        });
      }
    });
  }

  void _stopAnimation() {
    _spriteTimer?.cancel();
    _spriteTimer = null;
    _bounceController.stop();
    _bounceController.reset();
  }

  @override
  void dispose() {
    _spriteTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sprites = _spriteSequences[widget.state] ?? ['assets/images/char/char_0.png'];
    final safeIndex = _spriteIndex.clamp(0, sprites.length - 1);
    final imagePath = sprites[safeIndex];

    ColorFilter? filter;
    if (widget.state == CharacterState.announceBad || widget.state == CharacterState.down) {
      filter = const ColorFilter.mode(Colors.grey, BlendMode.saturation);
    }

    Widget image = Image.asset(
      imagePath,
      fit: BoxFit.contain,
      gaplessPlayback: true, // スプライト切替時にちらつかない
    );

    if (filter != null) {
      image = ColorFiltered(colorFilter: filter, child: image);
    }

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        double dy = 0;
        double scaleBonus = 0;
        if (widget.state == CharacterState.announceGood) {
          dy = _bounceController.value * -18.0; // ジャンプ
          scaleBonus = _bounceController.value * 0.05;
        } else if (widget.state == CharacterState.thinking) {
          dy = _bounceController.value * -6.0; // 浮く
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: 1.0 + scaleBonus,
            child: child,
          ),
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: image,
      ),
    );
  }
}
