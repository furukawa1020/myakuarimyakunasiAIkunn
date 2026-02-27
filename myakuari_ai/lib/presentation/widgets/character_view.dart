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

class CharacterView extends ConsumerStatefulWidget {
  final CharacterState state;

  const CharacterView({super.key, required this.state});

  @override
  ConsumerState<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends ConsumerState<CharacterView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _updateAnimation(widget.state);
  }

  @override
  void didUpdateWidget(covariant CharacterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation(widget.state);
    }
  }

  void _updateAnimation(CharacterState state) {
    _controller.stop();
    switch (state) {
      case CharacterState.thinking:
        _controller.repeat(reverse: true, period: const Duration(milliseconds: 500));
        break;
      case CharacterState.announceGood:
        _controller.repeat(reverse: true, period: const Duration(milliseconds: 300));
        break;
      default:
        _controller.reset();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 状態に応じたエフェクト（画像の切り抜きや色調変更のベース）
    ColorFilter? filter;
    double scale = 1.0;
    double rotation = 0.0;
    double dy = 0.0;
    String imagePath = 'assets/images/char/char_0.png';

    switch (widget.state) {
      case CharacterState.announceBad:
      case CharacterState.down:
        // 悲しい
        imagePath = 'assets/images/char/char_2.png';
        filter = const ColorFilter.mode(Colors.grey, BlendMode.saturation);
        break;
      case CharacterState.announceGood:
      case CharacterState.listening:
        // 嬉しい・身を乗り出す
        imagePath = 'assets/images/char/char_3.png';
        scale = 1.05;
        break;
      case CharacterState.announceNeutral:
      case CharacterState.question:
        // 疑問・中立
        imagePath = 'assets/images/char/char_1.png';
        break;
      case CharacterState.thinking:
      case CharacterState.closing:
      case CharacterState.idle:
      default:
        // 待機・思考
        imagePath = 'assets/images/char/char_0.png';
        break;
    }

    Widget image = Image.asset(
      imagePath,
      fit: BoxFit.contain,
    );

    if (filter != null) {
      image = ColorFiltered(colorFilter: filter, child: image);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.state == CharacterState.thinking) {
          dy = _controller.value * -10.0; // 少し浮く
        } else if (widget.state == CharacterState.announceGood) {
          dy = _controller.value * -20.0; // 大きくジャンプ
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: image,
    );
  }
}
