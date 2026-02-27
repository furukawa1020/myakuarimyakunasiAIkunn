import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> values; // 0.0 to 1.0
  final Color color;

  const RadarChartWidget({
    super.key,
    required this.values,
    this.color = const Color(0xFF00FFFF),
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RadarChartPainter(values, color),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> values;
  final Color color;

  _RadarChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final angleStep = (2 * math.pi) / values.length;

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric polygons (grid)
    for (var i = 1; i <= 5; i++) {
      final gridRadius = radius * (i / 5);
      final path = Path();
      for (var j = 0; j < values.length; j++) {
        final angle = j * angleStep - math.pi / 2;
        final point = center + Offset(math.cos(angle) * gridRadius, math.sin(angle) * gridRadius);
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes and labels
    final labels = values.keys.toList();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final endPoint = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(center, endPoint, axisPaint);

      // Labels
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      final labelOffset = center + Offset(
        math.cos(angle) * (radius + 15) - textPainter.width / 2,
        math.sin(angle) * (radius + 15) - textPainter.height / 2,
      );
      textPainter.paint(canvas, labelOffset);
    }

    // Draw the data area
    final dataPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final dataStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    final dataPoints = values.values.toList();
    for (var i = 0; i < dataPoints.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final pointRadius = radius * dataPoints[i].clamp(0.1, 1.0);
      final point = center + Offset(math.cos(angle) * pointRadius, math.sin(angle) * pointRadius);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // Draw points
    final pointPaint = Paint()..color = color;
    for (var i = 0; i < dataPoints.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final pointRadius = radius * dataPoints[i].clamp(0.1, 1.0);
      final point = center + Offset(math.cos(angle) * pointRadius, math.sin(angle) * pointRadius);
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
