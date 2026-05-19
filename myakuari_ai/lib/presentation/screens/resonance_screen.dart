import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../domain/resonance_service.dart';
import '../../domain/models/inference_models.dart';
import '../../domain/neural_narrative_engine.dart';
import '../theme.dart';

class ResonanceScreen extends StatefulWidget {
  final InferenceResult result;

  const ResonanceScreen({super.key, required this.result});

  @override
  State<ResonanceScreen> createState() => _ResonanceScreenState();
}

class _ResonanceScreenState extends State<ResonanceScreen>
    with TickerProviderStateMixin {
  final _service = ResonanceService();
  late AnimationController _radarController;
  late AnimationController _pulseController;

  _Phase _phase = _Phase.storing;
  String? _userId;
  List<ResonanceMatch> _matches = [];
  String _statusText = 'UPLOADING DESPAIR_VECTOR...';

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _runResonanceScan();
  }

  Future<void> _runResonanceScan() async {
    // 1. ベクトルを計算してKVに保存
    final vector = NeuralNarrativeEngine.buildFeatureVector(widget.result.input);
    setState(() => _statusText = 'ENCODING 10-DIM DESPAIR VECTOR...');
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() => _statusText = 'TRANSMITTING TO CLOUDFLARE KV...');
    final uid = await _service.storeVector(
      vector: vector,
      score: widget.result.loveScore,
      label: widget.result.labelText,
      grade: widget.result.compatibilityGrade,
    );

    if (uid == null) {
      setState(() {
        _phase = _Phase.error;
        _statusText = 'NETWORK_ERROR: オフラインモードで代替マッチを表示';
        _matches = _generateOfflineMatches();
      });
      return;
    }

    _userId = uid;
    setState(() => _statusText = 'SCANNING FOR RESONANT ENTITIES...');
    await Future.delayed(const Duration(milliseconds: 800));

    // 2. コサイン類似度でTop5検索
    setState(() { _phase = _Phase.scanning; _statusText = 'COMPUTING COSINE SIMILARITY...'; });
    final matches = await _service.findMatches(uid);

    setState(() {
      _phase = _Phase.result;
      _matches = matches.isNotEmpty ? matches : _generateOfflineMatches();
      _statusText = matches.isEmpty
          ? 'NO_MATCH_FOUND: まだ登録者が少ないのだ。ハッシュタグで仲間を呼ぶのだ！'
          : '${matches.length}体の絶望共鳴個体を発見したのだ！';
    });
    if (_matches.isNotEmpty) {
      // ignore: deprecated_member_use
      _radarController.stop();
    }
  }

  // オフライン/マッチなし時のデモマッチ
  List<ResonanceMatch> _generateOfflineMatches() {
    final rng = math.Random();
    final score = widget.result.loveScore;
    return List.generate(3, (i) => ResonanceMatch(
      userId: 'DEMO_${(1000 + rng.nextInt(9000))}',
      score: (score + (rng.nextInt(20) - 10)).clamp(0, 100),
      label: widget.result.labelText,
      grade: widget.result.compatibilityGrade,
      syncRate: 70 + rng.nextInt(28),
    ));
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── ヘッダー ──────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white54),
                  ),
                  Text('RESONANCE_SCANNER',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFFF00FF), fontSize: 14, letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: 8),

              // ── スキャン中 or 結果 ─────────────────────────────────
              Expanded(
                child: _phase == _Phase.result
                    ? _buildResults()
                    : _buildScanning(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanning() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // レーダーアニメーション
        AnimatedBuilder(
          animation: _radarController,
          builder: (_, __) => CustomPaint(
            size: const Size(200, 200),
            painter: _RadarPainter(_radarController.value),
          ),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Text(
            _statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              color: Color.lerp(
                const Color(0xFFFF00FF),
                const Color(0xFF00FFFF),
                _pulseController.value,
              )!,
              fontSize: 12, letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF00FF).withOpacity(0.4)),
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFFFF00FF).withOpacity(0.05),
          ),
          child: Text(
            _statusText,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFFFF00FF), fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),

        Text('// 絶望ベクトルのコサイン類似度による共鳴個体スキャン結果',
          style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            itemCount: _matches.length,
            itemBuilder: (_, i) => _buildMatchCard(_matches[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(ResonanceMatch m, int rank) {
    final syncColor = m.syncRate >= 90
        ? const Color(0xFFFF4444)
        : m.syncRate >= 75
            ? const Color(0xFFFFD700)
            : const Color(0xFF00FFFF);

    final label = m.syncRate >= 90
        ? '🔴 CRITICAL SYNC'
        : m.syncRate >= 75
            ? '🟡 HIGH RESONANCE'
            : '🔵 PARTIAL MATCH';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: syncColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
        color: syncColor.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${rank + 1}  ${m.userId}',
                style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
              const Spacer(),
              Text(label,
                style: GoogleFonts.shareTechMono(color: syncColor, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('SYNC_RATE',
                style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: m.syncRate / 100.0,
                  backgroundColor: Colors.white10,
                  color: syncColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text('${m.syncRate}%',
                style: GoogleFonts.shareTechMono(
                  color: syncColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SCORE: ${m.score}pt  GRADE: ${m.grade}  LABEL: ${m.label}',
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            _getMatchComment(m.syncRate),
            style: GoogleFonts.shareTechMono(
              color: syncColor.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  String _getMatchComment(int rate) {
    if (rate >= 95) return '> 同じ理由で同じ結末を迎える絶望双子。運命的な出会いなのだ。';
    if (rate >= 85) return '> 「また会いたい」意欲と主導権の諦め方が完全一致。共に語り合えるのだ。';
    if (rate >= 75) return '> 行動パターンが酷似。悩みを共有できる高確率なのだ。';
    return '> 絶望の形が似ているのだ。話してみると楽になれるかもしれないのだ。';
  }
}

// ── フェーズ管理 ─────────────────────────────────────────────────
enum _Phase { storing, scanning, result, error }

// ── レーダースキャナーペインター ─────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double sweep;
  _RadarPainter(this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;

    final gridPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 同心円
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset(cx, cy), r * i / 4, gridPaint);
    }

    // 十字線
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), gridPaint);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), gridPaint);

    // スイープライン（緑）
    final angle = sweep * 2 * math.pi;
    final sweepPaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * math.cos(angle - math.pi / 2),
             cy + r * math.sin(angle - math.pi / 2)),
      sweepPaint,
    );

    // スイープの残像グラデーション
    for (int i = 1; i <= 8; i++) {
      final a = (sweep - i * 0.04) * 2 * math.pi;
      final fadePaint = Paint()
        ..color = const Color(0xFF00FF00).withOpacity((8 - i) / 50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(a - math.pi / 2),
               cy + r * math.sin(a - math.pi / 2)),
        fadePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.sweep != sweep;
}
