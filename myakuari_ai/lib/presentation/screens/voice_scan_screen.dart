import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isManuallyEditing = false;

  @override
  void initState() {
    super.initState();
    // タイムアウトなし（ユーザーがボタンを押すまで録音継続）
    _audio.startScan(const Duration(hours: 1));
    // 100ms間隔でJSブリッジから本物のデータをポーリング
    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _poll());
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isManuallyEditing = true;
        });
      }
    });
  }

  void _poll() {
    if (!mounted || _done) return;
    final s = _audio.getState();

    // ユーザーが直接編集していない場合のみ音声認識結果をテキストボックスに反映
    if (!_focusNode.hasFocus && s.transcript.isNotEmpty && s.transcript != _textController.text) {
      _textController.text = s.transcript;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    setState(() => _audioState = s);
  }

  void _finish(String text) {
    if (_done) return;
    _done = true;
    _pollTimer?.cancel();
    _audio.stopScan();
    HapticFeedback.heavyImpact();

    // 手動入力されたテキストを優先、なければ音声認識されたテキストを使用
    final finalSpeechText = _textController.text.isNotEmpty ? _textController.text : text;

    // 音声テキストと音響特徴量からInferenceInputを自動構築
    final input = _parseInputFromText(finalSpeechText, _audioState);
    
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

    // Detect if the speech is English or Japanese by matching Japanese character sets
    final hasJapanese = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
    final isEnglish = !hasJapanese && text.isNotEmpty;

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
      what: text.isNotEmpty ? text : (isEnglish ? 'Acoustic update report' : '音声での近況報告'),
      when: when,
      where: where,
      why: isEnglish 
          ? 'Psychological status and utterance data auto-analyzed from voice' 
          : '音声から自動解析された心理状態および発言データ',
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
      isEnglish: isEnglish,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _audio.stopScan();
    _textController.dispose();
    _focusNode.dispose();
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

              // ── 警告/エラー表示 ────────────────────────────────────
              if (!s.supported)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'お使いのブラウザは音声文字起こしに対応していません。キーボードで状況を入力するか、PCのChromeまたはiPhoneのSafariブラウザをご利用ください。',
                          style: TextStyle(color: Colors.amber, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              else if (s.speechError == 'not-allowed')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mic_off_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'マイクの使用許可が拒否されています。ブラウザの設定でマイクへのアクセスを許可するか、下の入力欄に状況をキーボードで入力してください。',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              else if (s.speechError.isNotEmpty && s.speechError != 'aborted')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '音声認識中にエラーが発生しました（エラー: ${s.speechError}）。別のブラウザを試すか、下の入力欄からキーボード入力をお願いします。',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── リアルタイム文字起こし ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'リアルタイム文字起こし結果',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  ),
                  if (_textController.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        _audio.stopScan();
                        _audio.startScan(const Duration(hours: 1));
                        setState(() {
                          _textController.clear();
                          _isManuallyEditing = false;
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 12, color: Color(0xFF00FFFF)),
                      label: const Text(
                        'リセット',
                        style: TextStyle(color: Color(0xFF00FFFF), fontSize: 10, fontFamily: 'monospace'),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withOpacity(0.03),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: s.supported
                              ? '状況を声に出して話すか、ここをタップして直接入力してください...'
                              : 'お使いのブラウザは音声認識に対応していません。こちらに直接状況を入力してください...',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13, fontFamily: 'monospace'),
                          contentPadding: const EdgeInsets.only(left: 12, right: 36, top: 12, bottom: 36),
                          border: InputBorder.none,
                        ),
                      ),
                      if (s.interimTranscript.isNotEmpty && !_isManuallyEditing)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: IgnorePointer(
                            child: Text(
                              '認識中: ${s.interimTranscript}',
                              style: const TextStyle(
                                color: Color(0xFF00FFFF),
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
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
