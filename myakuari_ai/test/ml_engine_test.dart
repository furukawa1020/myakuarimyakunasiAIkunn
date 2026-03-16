import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myakuari_ai/domain/ml_inference_engine.dart';
import 'package:myakuari_ai/domain/models/inference_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ML Inference Engine Integration Test', () async {
    final engine = MLInferenceEngine.instance;
    
    // Simulate asset loading for the test environment if needed, 
    // or just rely on the actual bundle if available in widget tests.
    await engine.load();
    
    if (!engine.isLoaded) {
      print('Warning: Asset not found in test environment, skipping full analysis test.');
      return;
    }

    final input = InferenceInput(
      when: '最近',
      who: '職場の同僚',
      where: '趣味のカフェ',
      what: '週末に遊びに行こうと誘われた',
      why: '共通の趣味の話で盛り上がったから',
      how: '直接',
      initiative: '相手',
      concreteness: 'YES',
      contactFrequency: 4,
      continuation: '続いてる',
      evidenceLevel: 5,
    );

    final result = engine.analyze(input);
    
    expect(result, isNotNull);
    if (result != null) {
      print('Result Label: \${result.labelText}');
      print('Love Score: \${result.loveScore}');
      print('Grade: \${result.compatibilityGrade}');
      print('Script: \${result.spokenScript}');
      
      expect(result.loveScore, greaterThanOrEqualTo(0));
      expect(result.loveScore, lessThanOrEqualTo(100));
    }
  });
}
