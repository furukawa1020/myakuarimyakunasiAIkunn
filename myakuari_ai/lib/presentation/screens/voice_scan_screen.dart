import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'wizard_screen.dart';
import '../theme.dart';
import '../../domain/web_audio_interop.dart';
import 'loading_screen.dart';
import '../../domain/models/inference_models.dart';

class VoiceScanScreen extends StatefulWidget {
  const VoiceScanScreen({super.key});

  @override
  State<VoiceScanScreen> createState() => _VoiceScanScreenState();
}

class _VoiceScanScreenState extends State<VoiceScanScreen> {
  final WebAudioInterop _audio = WebAudioInterop();
  Timer? _pollTimer;
  AudioScanState _audioState = const AudioScanState();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _audio.startScan(const Duration(seconds: 10));
    // 80ms間隔でJSブリッジから本物のデータをポーリング
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _poll());
  }

  void _poll() {
    if (!mounted || _done) return;
    final s = _audio.getState();
    setState(() => _audioState = s);

    // 音声が途切れて確定テキストがある場合は自動遷移
    if (!s.recording && s.transcript.isNotEmpty) {
      _finish(s.transcript);
    }
  }

  void _finish(String text) {
    if (_done) return;
    _done = true;
    _pollTimer?.cancel();
    _audio.stopScan();
    HapticFeedback.heavyImpact();
    
    // 音声テキストと音響特徴量からInferenceInputを自動構築
    final input = _parseInputFromText(text, _audioState);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoadingScreen(input: input),
        ),
      );
    }
  }

  InferenceInput _parseInputFromText(String text, AudioScanState s) {
    final lowerText = text.toLowerCase();

    // 1. Who (関係性)
    String who = '相手';
    if (lowerText.contains('先輩') || lowerText.contains('senpai')) {
      who = '先輩';
    } else if (lowerText.contains('後輩') || lowerText.contains('kouhai')) {
      who = '後輩';
    } else if (lowerText.contains('同僚') || lowerText.contains('colleague') || lowerText.contains('同期')) {
      who = '同僚';
    } else if (lowerText.contains('友達') || lowerText.contains('friend')) {
      who = '友達';
    } else if (lowerText.contains('好きな人') || lowerText.contains('crush') || lowerText.contains('彼') || lowerText.contains('彼女')) {
      who = '気になる人';
    }

    // 2. Where (文脈・場所)
    String where = 'LINE';
    if (lowerText.contains('職場') || lowerText.contains('学校') || lowerText.contains('office') || lowerText.contains('school')) {
      where = '職場/学校';
    } else if (lowerText.contains('飲み') || lowerText.contains('居酒屋') || lowerText.contains('bar') || lowerText.contains('drinking')) {
      where = '飲み会';
    } else if (lowerText.contains('カフェ') || lowerText.contains('食事') || lowerText.contains('デート') || lowerText.contains('cafe') || lowerText.contains('dinner')) {
      where = '対面でのデート';
    }

    // 3. When (時期)
    String when = '今日';
    if (lowerText.contains('昨日') || lowerText.contains('yesterday')) {
      when = '昨日';
    } else if (lowerText.contains('先週') || lowerText.contains('last week')) {
      when = '先週';
    } else if (lowerText.contains('最近') || lowerText.contains('recently')) {
      when = '今週';
    }

    // 4. Initiative (主導権)
    String initiative = '半々';
    if (lowerText.contains('誘われた') || lowerText.contains('きた') || lowerText.contains('返ってきた') || lowerText.contains('invited me') || lowerText.contains('asked me out')) {
      initiative = '相手';
    } else if (lowerText.contains('誘った') || lowerText.contains('送った') || lowerText.contains('話しかけた') || lowerText.contains('i invited') || lowerText.contains('i asked')) {
      initiative = '自分';
    }

    // 5. Concreteness (具体性)
    String concreteness = '未定';
    if (lowerText.contains('約束') || lowerText.contains('行くことに') || lowerText.contains('決まった') || lowerText.contains('promised') || lowerText.contains('decided to go')) {
      concreteness = 'YES';
    } else if (lowerText.contains('流れた') || lowerText.contains('断られた') || lowerText.contains('忙しい') || lowerText.contains('canceled') || lowerText.contains('busy')) {
      concreteness = '止まる';
    }

    // 6. Continuation (継続性)
    String continuation = '普通';
    if (lowerText.contains('毎日') || lowerText.contains('続いてる') || lowerText.contains('ずっとながれてる') || lowerText.contains('everyday') || lowerText.contains('keep talking')) {
      continuation = '続いてる';
    } else if (lowerText.contains('途切れた') || lowerText.contains('既読無視') || lowerText.contains('未読無視') || lowerText.contains('こない') || lowerText.contains('no reply') || lowerText.contains('ignored')) {
      continuation = '途切れた';
    }

    // 7. Contact Frequency (連絡頻度)
    int contactFrequency = 3;
    if (lowerText.contains('毎日') || lowerText.contains('常に') || lowerText.contains('always') || lowerText.contains('constantly')) {
      contactFrequency = 5;
    } else if (lowerText.contains('よく') || lowerText.contains('頻繁に') || lowerText.contains('often')) {
      contactFrequency = 4;
    } else if (lowerText.contains('たまに') || lowerText.contains('sometimes')) {
      contactFrequency = 2;
    } else if (lowerText.contains('ほとんどない') || lowerText.contains('めったに') || lowerText.contains('rarely')) {
      contactFrequency = 1;
    }

    return InferenceInput(
      who: who,
      what: text.isNotEmpty ? text : '音声での近況報告',
      when: when,
      where: where,
      why: '音声から自動解析された心理状態および発言データ',
      how: text,
      contactFrequency: contactFrequency,
      initiative: initiative,
      concreteness: concreteness,
      continuation: continuation,
      evidenceLevel: 4,
      voiceRms: s.rms,
      voiceJitter: s.jitter,
      voiceDominantFreqHz: s.dominantFreqHz,
      isVoice: true,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _audio.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _audioState;
    final spectrum = s.spectrum.isEmpty ? List.filled(16, 0) : s.spectrum;
    final hasVoice = s.rms > 5;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ヘッダー ────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.recording ? const Color(0xFF00FF00) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.recording ? 'マイク入力：認識中...' : '待機中',
                    style: const TextStyle(
                      color: Color(0xFF00FF00), fontSize: 12,
                      fontFamily: 'monospace', letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── リアルFFTスペクトラム（本物のWeb Audio AnalyserNodeデータ）──
              const Text(
                '周波数スペクトラム解析 (本物のマイク波形 / 16バンド)',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(16, (i) {
                    final v = spectrum[i].clamp(0, 255);
                    final h = (v / 255.0) * 80;
                    final color = Color.lerp(
                      const Color(0xFF00FFFF),
                      const Color(0xFF00FF00),
                      i / 15.0,
                    )!;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          height: h.clamp(2, 80),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: hasVoice ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)] : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // ── リアル音声メトリクス ─────────────────────────────
              Row(
                children: [
                  _MetricBox(label: '音量', value: '${s.rms}', unit: '/100', color: const Color(0xFF00FFFF)),
                  const SizedBox(width: 12),
                  _MetricBox(label: '声の震え', value: '${s.jitter}', unit: 'ZCR%', color: const Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  _MetricBox(label: '基本周波数', value: '${s.dominantFreqHz}', unit: 'Hz', color: const Color(0xFFFF6B6B)),
                ],
              ),
              const SizedBox(height: 24),

              // ── リアルタイム文字起こし ───────────────────────────
              const Text(
                'リアルタイム文字起こし結果',
                style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withOpacity(0.03),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 確定済みテキスト
                      Text(
                        s.transcript,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 14,
                          fontFamily: 'monospace', height: 1.6,
                        ),
                      ),
                      // 認識中テキスト（薄い色でリアルタイム表示）
                      if (s.interimTranscript.isNotEmpty)
                        Text(
                          s.interimTranscript,
                          style: const TextStyle(
                            color: Color(0xFF00FFFF), fontSize: 14,
                            fontFamily: 'monospace', height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      // プレースホルダー
                      if (s.transcript.isEmpty && s.interimTranscript.isEmpty)
                        const Text(
                          '状況を声に出してください...',
                          style: TextStyle(color: Colors.white24, fontSize: 13, fontFamily: 'monospace'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 完了ボタン ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finish(s.fullTranscript),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFFF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text(
                    '診断を開始する  ▶',
                    style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricBox({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(4),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontFamily: 'monospace', letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            Text(unit, style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
