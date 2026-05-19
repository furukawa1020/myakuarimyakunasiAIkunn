import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

final String _workerBaseUrl = kDebugMode 
    ? 'http://localhost:8787' 
    : 'https://myakuari-ogp-generator.myakuarimyakunasiaikunn.workers.dev';

class ResonanceMatch {
  final String userId;
  final int score;
  final String label;
  final String grade;
  final int syncRate; // 0-100

  const ResonanceMatch({
    required this.userId,
    required this.score,
    required this.label,
    required this.grade,
    required this.syncRate,
  });

  factory ResonanceMatch.fromJson(Map<String, dynamic> j) => ResonanceMatch(
    userId:   j['userId'] as String? ?? '???',
    score:    (j['score'] as num?)?.toInt() ?? 0,
    label:    j['label'] as String? ?? '',
    grade:    j['grade'] as String? ?? 'D',
    syncRate: (j['syncRate'] as num?)?.toInt() ?? 0,
  );
}

/// Cloudflare KV-based 絶望ベクトルマッチングサービス
class ResonanceService {
  static final ResonanceService _i = ResonanceService._();
  factory ResonanceService() => _i;
  ResonanceService._();

  String? _myUserId;
  String? get myUserId => _myUserId;

  /// 自分の絶望ベクトルをCloudflare KVに保存する
  /// [vector]はMLInferenceEngineと同じ10次元特徴ベクトル
  Future<String?> storeVector({
    required List<double> vector,
    required int score,
    required String label,
    required String grade,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_workerBaseUrl/api/store'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vector': vector,
          'score': score,
          'label': label,
          'grade': grade,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _myUserId = data['userId'] as String?;
        return _myUserId;
      }
    } catch (_) {}
    return null;
  }

  /// コサイン類似度でTop5の「絶望共鳴個体」を検索する
  Future<List<ResonanceMatch>> findMatches(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_workerBaseUrl/api/match?userId=$userId'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['matches'] as List? ?? [];
        return list.map((e) => ResonanceMatch.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}
