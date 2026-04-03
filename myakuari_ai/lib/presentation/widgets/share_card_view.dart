import 'package:flutter/material.dart';
import '../../domain/models/inference_models.dart';
import 'glass_card.dart';
import 'radar_chart.dart';

/// SNS共有用の診断カード。
/// ずんだもんの顔、スコア、判定、そして「イキ告」警告を目立たせる。
class ShareCardView extends StatelessWidget {
  final InferenceResult result;

  const ShareCardView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.loveScore >= 70
        ? const Color(0xFFFF007F)
        : result.loveScore >= 40
            ? const Color(0xFF00FFFF)
            : const Color(0xFFFF4500);

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A0033), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scoreColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '恋愛診断 AI くん',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              Text(
                'DATE: ${DateTime.now().toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),

          // 判定とスコア
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '総合判定: ${result.labelText}',
                      style: TextStyle(color: scoreColor, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LOVE SCORE: ${result.loveScore}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              _buildGradeBadge(result.compatibilityGrade, scoreColor),
            ],
          ),
          
          const SizedBox(height: 20),

          // レーダーチャート (画像生成時は簡易表示)
          SizedBox(
            height: 150,
            child: RadarChartWidget(values: result.radarData, color: scoreColor),
          ),

          const SizedBox(height: 16),

          // イキ告警告 (ここが訴求ポイント)
          if (result.isIkikoku)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'イキ告（事故）要注意なのだ！',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.ikikokuWarning ?? '今の距離感で告白するのは自殺行為なのだ。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          
          // フッターメッセージ
          Text(
            result.spokenScript.length > 60 ? result.spokenScript.substring(0, 60) + '...' : result.spokenScript,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          const Text(
            '#恋愛診断AIくん #ずんだもん',
            style: TextStyle(color: Color(0xFF00FFFF), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBadge(String grade, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)],
      ),
      alignment: Alignment.center,
      child: Text(
        grade,
        style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}
