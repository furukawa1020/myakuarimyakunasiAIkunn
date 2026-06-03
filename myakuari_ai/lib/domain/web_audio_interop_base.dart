class AudioScanState {
  final bool recording;
  final String transcript;        // 確定済みテキスト
  final String interimTranscript; // 認識中（リアルタイム）
  final int rms;                  // 音量 0-100
  final int jitter;               // 声の揺れ(ZCR) 0-100
  final int dominantFreqHz;       // 主要周波数 Hz
  final List<int> spectrum;       // FFT 16バンド 0-255
  final bool supported;           // 音声認識に対応しているか
  final String speechError;       // 音声認識のエラー内容

  const AudioScanState({
    this.recording = false,
    this.transcript = '',
    this.interimTranscript = '',
    this.rms = 0,
    this.jitter = 0,
    this.dominantFreqHz = 0,
    this.spectrum = const [],
    this.supported = true,
    this.speechError = '',
  });

  factory AudioScanState.fromJson(Map<String, dynamic> j) => AudioScanState(
    recording:          j['recording'] as bool? ?? false,
    transcript:         j['transcript'] as String? ?? '',
    interimTranscript:  j['interimTranscript'] as String? ?? '',
    rms:                (j['rms'] as num?)?.toInt() ?? 0,
    jitter:             (j['jitter'] as num?)?.toInt() ?? 0,
    dominantFreqHz:     (j['dominantFreqHz'] as num?)?.toInt() ?? 0,
    spectrum:           (j['spectrum'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
    supported:          j['supported'] as bool? ?? true,
    speechError:        j['speechError'] as String? ?? '',
  );

  String get fullTranscript => interimTranscript.isNotEmpty
      ? '$transcript $interimTranscript'
      : transcript;
}
