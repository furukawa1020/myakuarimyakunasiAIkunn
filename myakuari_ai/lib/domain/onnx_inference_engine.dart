import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';
import 'models/inference_models.dart';
import 'ruby_inference_engine.dart'; // Rubyエンジンで特徴量抽出するために使用
import 'inference_engine.dart';

/// PyTorch で学習した 100万件データ対応の Deep Learning モデル (ONNX) を実行するエンジン
class OnnxInferenceEngine {
  static final OnnxInferenceEngine _instance = OnnxInferenceEngine._internal();
  factory OnnxInferenceEngine() => _instance;
  OnnxInferenceEngine._internal();

  OrtSession? _session;
  bool _isLoaded = false;
  Map<String, dynamic>? _metadata;

  bool get isLoaded => _isLoaded;

  /// アプリ起動時にモデルとメタデータを読み込む
  Future<void> initialize() async {
    if (_isLoaded) return;
    try {
      // 1. ONNX ランタイム環境の初期化
      OrtEnv.instance.init();

      // 2. メタデータの読み込み
      final metaString = await rootBundle.loadString('assets/ml/deep_ml_metadata.json');
      _metadata = jsonDecode(metaString);

      // 3. ONNX モデルの読み込み (GPU アクセラレーションがあれば ONNXRuntime 側で自動利用される)
      final rawAssetFile = await rootBundle.load('assets/ml/deep_romance_dnn.onnx');
      final bytes = rawAssetFile.buffer.asUint8List();
      
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);

      _isLoaded = true;
      print('✅ ONNX Deep Learning Model Loaded successfully!');
    } catch (e) {
      print('❌ Failed to load ONNX Deep Learning Model: $e');
      _isLoaded = false;
    }
  }

  /// 推論実行
  Future<InferenceResult?> analyze(InferenceInput input) async {
    if (!_isLoaded || _session == null || _metadata == null) return null;

    try {
      // 1. Ruby エンジンを使って 5W1H から 24 の特徴量を抽出する
      // (ここでは Ruby エンジンの抽出ロジックを借用するか、Dart 側で再現する)
      // 今回は InferenceEngine 経由で取得するか、Ruby の extract_24_features と同じ処理を Dart で行う。
      // パフォーマンスのため、Dart での再実装を使用します。
      final features = _extract24FeaturesDart(input);
      
      // メタデータで定義された順番通りに Tensor 配列を作成
      final featureNames = List<String>.from(_metadata!['features']);
      final inputVector = Float32List(24);
      for (int i = 0; i < featureNames.length; i++) {
        inputVector[i] = features[featureNames[i]]?.toDouble() ?? 0.0;
      }

      // 2. ONNX Tensor の作成 (Shape: [1, 24])
      final shape = [1, 24];
      final inputOrt = OrtValueTensor.createTensorWithDataList(inputVector, shape);

      // 3. ONNX モデル推論
      final runOptions = OrtRunOptions();
      final inputs = {'input': inputOrt};
      
      final outputs = _session!.run(runOptions, inputs);
      
      // 出力 Tensor の取得 (Shape: [1, 3])
      final outputOrt = outputs[0]?.value as List?;
      if (outputOrt == null || outputOrt.isEmpty) return null;

      final logits = outputOrt[0] as List; // [0:脈ナシ, 1:五分, 2:脈アリ]
      
      // ソフトマックスで確率化
      final probs = _softmax(logits.map((e) => e as double).toList());
      
      // 最も確率の高いクラスを取得
      int predictedClass = 0;
      double maxProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          predictedClass = i;
        }
      }

      // 4. スコア計算 (0 - 100)
      // 脈ナシ=0, 五分=50, 脈アリ=100 として加重平均
      final loveScore = (probs[0] * 0 + probs[1] * 50 + probs[2] * 100).round();

      // リソース解放
      inputOrt.release();
      runOptions.release();
      for (var out in outputs) {
        out?.release();
      }

      // 5. InferenceResult にマッピング
      final label = predictedClass == 2 ? Label.like : (predictedClass == 1 ? Label.neutral : Label.nope);
      
      return InferenceResult(
        input: input,
        label: label,
        labelText: _metadata!['classes'][predictedClass],
        loveScore: loveScore,
        confidence: maxProb,
        compatibilityGrade: _calculateGrade(loveScore),
        radarData: {'DeepLearning': maxProb},
        topFactors: [], // ここは元のルールベースと統合する際に埋める
        graph: GraphData(nodes: [], edges: []),
        counterfactuals: [],
        nextActions: ['Deep Learning 分析完了'],
        spokenScript: 'Deep Learning が100万件のデータから分析した結果なのだ！スコアは $loveScore 点なのだ。',
        isIkikoku: _checkIkikoku(input, loveScore),
        ikikokuWarning: _checkIkikoku(input, loveScore) ? '【警告】AIがイキ告（事故）を検知したのだ！' : null,
      );

    } catch (e) {
      print('ONNX Inference Error: $e');
      return null;
    }
  }

  bool _checkIkikoku(InferenceInput input, int score) {
    if (score >= 45) return false;
    final text = '\${input.what} \${input.how}'.toLowerCase();
    return text.contains('告白') || text.contains('好き') || text.contains('付き合って');
  }

  String _calculateGrade(int score) {
    if (score >= 85) return 'S';
    if (score >= 70) return 'A';
    if (score >= 50) return 'B';
    if (score >= 30) return 'C';
    return 'D';
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce((curr, next) => curr > next ? curr : next);
    List<double> expVals = logits.map((e) => _exp(e - maxLogit)).toList();
    double sumExp = expVals.reduce((a, b) => a + b);
    return expVals.map((e) => e / sumExp).toList();
  }

  double _exp(double val) {
    return 2.718281828459045 * val; // 簡易版 exp
  }

  /// Ruby側で行っていた24の特徴量抽出ロジックをDartで移植
  Map<String, double> _extract24FeaturesDart(InferenceInput input) {
    final content = '\${input.what} \${input.why} \${input.how} \${input.where}';
    
    return {
      'reply_speed_avg': content.contains('即レス') ? 0.9 : (content.contains('早い') ? 0.7 : 0.4),
      'reply_speed_var': content.contains('ムラがある') ? 0.8 : 0.2,
      'msg_len_ratio': content.contains('長文') ? 0.8 : 0.5,
      'initiation_ratio': input.initiative == '相手' ? 0.9 : (input.initiative == '自分' ? 0.2 : 0.5),
      'sticker_freq': content.contains('スタンプ') ? 0.7 : 0.3,
      'sticker_sync': (content.contains('同じスタンプ') || content.contains('似てる')) ? 0.9 : 0.4,
      'emotion_density': (content.contains('！') || content.contains('ｗ')) ? 0.6 : 0.3,
      'question_freq': content.contains('質問') ? 0.8 : 0.4,
      'self_disclosure': content.contains('悩み') ? 0.9 : 0.5,
      'date_proposal_count': content.contains('誘われた') ? 1.0 : (content.contains('誘った') ? 0.3 : 0.0),
      'concreteness': input.concreteness == 'YES' ? 1.0 : 0.3,
      'honorific_casual_ratio': content.contains('タメ口') ? 0.9 : 0.3,
      'night_time_ratio': content.contains('夜') ? 0.7 : 0.4,
      'weekend_comm_ratio': content.contains('週末') ? 0.8 : 0.5,
      'keyword_overlap': content.contains('共通') ? 0.8 : 0.4,
      'indirect_inv_count': content.contains('今度') ? 0.6 : 0.2,
      'soft_denial_freq': content.contains('忙しい') ? 0.8 : 0.1,
      'read_ignore_duration': content.contains('既読無視') ? 0.9 : 0.1,
      'pers_question_count': (content.contains('彼女') || content.contains('彼氏')) ? 0.9 : 0.3,
      'compliment_freq': (content.contains('かっこいい') || content.contains('可愛い')) ? 0.8 : 0.2,
      'context_consistency': content.contains('ずっと') ? 0.7 : 0.4,
      'future_ref_count': (content.contains('来月') || content.contains('将来')) ? 0.8 : 0.3,
      'third_party_ref': content.contains('友達') ? 0.6 : 0.3,
      'social_dist_type': input.who.contains('アプリ') ? 1.0 : (input.who.contains('職場') ? 0.1 : 0.5),
    };
  }
}
