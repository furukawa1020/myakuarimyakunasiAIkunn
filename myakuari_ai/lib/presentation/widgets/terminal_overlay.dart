import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class TerminalOverlay extends StatefulWidget {
  const TerminalOverlay({super.key});

  @override
  State<TerminalOverlay> createState() => _TerminalOverlayState();
}

class _TerminalOverlayState extends State<TerminalOverlay> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  final List<String> _logTemplates = [
    "[INFO] Initializing ONNX session with WASM backend...",
    "[DEBUG] Feature Vector Extracting: Layer 2 active.",
    "[SYSTEM] Entropy check: 0.82 (High variance detected)",
    "[NETWORK] Signal-to-Noise Ratio: 12.4dB",
    "[ML] Gradient Boosting decision path: [4, 12, 7, 21]",
    "[INFO] Memory usage: 124MB / 1024MB",
    "[DEBUG] Homeostasis level stable at 0.45",
    "[WARN] High emotional latency detected in target entity.",
    "[SYSTEM] Latency: 22ms | Throughput: 1.2k req/sec",
    "[ML] Running SHAP values calculation...",
    "[INFO] Tokenizing input sequence: L7-Standard",
    "0x${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')} ACCESS_GRANTED",
    "0x${Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')} DATA_STREAM_SYNC",
  ];

  @override
  void initState() {
    super.initState();
    _startLogging();
  }

  void _startLogging() {
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _logs.add(_logTemplates[Random().nextInt(_logTemplates.length)]);
          if (_logs.length > 50) _logs.removeAt(0);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.3,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            return Text(
              _logs[index],
              style: const TextStyle(
                color: AppTheme.systemGreen,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            );
          },
        ),
      ),
    );
  }
}
