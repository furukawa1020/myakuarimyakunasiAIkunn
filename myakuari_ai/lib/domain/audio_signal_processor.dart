import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:fftea/fftea.dart';

class AudioSignalProcessor {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  /// マイクからの音声波形をキャプチャし、FFTで「声の震え（ジッター）」やエネルギーを数値化する
  Future<Map<String, double>> analyzeVoiceSentiment() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Web対応: Streamとして音声波形を取得 (PCM 16bit, 16kHz)
        final stream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ));
        
        // 1秒分のチャンクを集める
        List<int> audioData = [];
        await for (var chunk in stream) {
          audioData.addAll(chunk);
          if (audioData.length >= 32000) { // 16kHz * 2 bytes = 32000 bytes/sec
            break;
          }
        }
        await _audioRecorder.stop();

        // バイト列から実数の波形データへ変換
        final byteData = ByteData.view(Uint8List.fromList(audioData).buffer);
        final samples = Float64List(1024);
        for (int i = 0; i < 1024 && i * 2 < byteData.lengthInBytes; i++) {
          samples[i] = byteData.getInt16(i * 2, Endian.host) / 32768.0;
        }

        // FFT (高速フーリエ変換) の実行
        final fft = FFT(1024);
        final spectrum = fft.realFft(samples.toList());
        
        // 簡易的な特徴量抽出
        double lowFrequencyEnergy = 0.0;
        double highFrequencyEnergy = 0.0;
        double maxMagnitude = 0.0;
        
        for (int i = 0; i < spectrum.length; i++) {
          final real = spectrum[i].x;
          final imag = spectrum[i].y;
          final magnitude = (real * real + imag * imag); // squared magnitude for performance
          if (magnitude > maxMagnitude) maxMagnitude = magnitude;
          
          if (i < spectrum.length / 4) {
            lowFrequencyEnergy += magnitude; // 落ち着き・重み
          } else {
            highFrequencyEnergy += magnitude; // 焦り・震え
          }
        }

        // ノイズフロア計算
        final totalEnergy = lowFrequencyEnergy + highFrequencyEnergy;
        final jitter = (highFrequencyEnergy / (totalEnergy + 1e-6)).clamp(0.0, 1.0);
        final dominance = (lowFrequencyEnergy / (totalEnergy + 1e-6)).clamp(0.0, 1.0);

        return {
          'Vocal_Jitter': jitter,          // 焦り具合
          'Vocal_Dominance': dominance,    // 自信
          'Energy_Peak': maxMagnitude.clamp(0.0, 1.0), // 声の大きさ
        };
      }
    } catch (e) {
      // マイク拒否やWebでの動作制約の場合はデフォルトのベースラインを返す
    }
    
    return {
      'Vocal_Jitter': 0.1,
      'Vocal_Dominance': 0.5,
      'Energy_Peak': 0.3,
    };
  }
}
