import 'dart:typed_data';
import 'dart:math' as math;

/// GC発生を完全に抑制する Zero-Allocation DSPエンジン
/// (Webブラウザ環境のDartでのヒープ割当を最小化)
class MfccExtractor {
  // 事前確保されるバッファ群（GC対象にならないように再利用）
  final Float32List _window;
  final Float32List _spectrum;
  final Float32List _melEnergies;
  final int _fftSize;
  final int _numFilters;
  
  MfccExtractor(this._fftSize, this._numFilters)
      : _window = Float32List(_fftSize),
        _spectrum = Float32List(_fftSize ~/ 2),
        _melEnergies = Float32List(_numFilters) {
    _initHammingWindow();
  }

  void _initHammingWindow() {
    for (int i = 0; i < _fftSize; i++) {
      _window[i] = 0.54 - 0.46 * math.cos(2 * math.pi * i / (_fftSize - 1));
    }
  }

  /// 窓関数の適用 (インプレース処理でメモリ割当ゼロ)
  void applyWindow(Float32List buffer) {
    for (int i = 0; i < _fftSize && i < buffer.length; i++) {
      buffer[i] *= _window[i];
    }
  }

  /// Zero-Crossing Rate (ゼロ交差率)の計算
  /// かすれ声やため息のようなノイズ成分の検出に有効
  double calculateZCR(Float32List buffer) {
    int crossings = 0;
    for (int i = 1; i < buffer.length; i++) {
      if ((buffer[i] >= 0 && buffer[i - 1] < 0) || 
          (buffer[i] < 0 && buffer[i - 1] >= 0)) {
        crossings++;
      }
    }
    return crossings / buffer.length;
  }

  /// 擬似的なメル周波数エネルギーの計算 (本来はメルフィルタバンクとの行列積)
  void extractFeatures(Float32List magnitudes, Float32List outMfcc) {
    // 簡易的な対数メルエネルギー計算（軽量化版）
    int binSize = magnitudes.length ~/ _numFilters;
    for (int i = 0; i < _numFilters; i++) {
      double energy = 0.0;
      int start = i * binSize;
      for (int j = 0; j < binSize && (start + j) < magnitudes.length; j++) {
        energy += magnitudes[start + j];
      }
      _melEnergies[i] = math.log(energy + 1e-10); // Log Energy
    }
    
    // 離散コサイン変換 (DCT)
    for (int i = 0; i < outMfcc.length; i++) {
      double sum = 0.0;
      for (int j = 0; j < _numFilters; j++) {
        sum += _melEnergies[j] * math.cos(math.pi * i / _numFilters * (j + 0.5));
      }
      outMfcc[i] = sum;
    }
  }
}
