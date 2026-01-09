import 'package:flutter/material.dart';
import 'dart:ui';

class BlackboardPainter extends CustomPainter {
  const BlackboardPainter({
    required this.currentStroke,
    required this.historyStrokes,
  });

  final List<Offset> currentStroke;
  final List<List<Offset>> historyStrokes;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color.fromARGB(255, 88, 72, 72);
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    canvas.drawRect(rect, backgroundPaint);

    if (currentStroke.isNotEmpty) {
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPoints(PointMode.polygon, currentStroke, strokePaint);
    }

    for (final stroke in historyStrokes) {
      final historyStrokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPoints(PointMode.polygon, stroke, historyStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}