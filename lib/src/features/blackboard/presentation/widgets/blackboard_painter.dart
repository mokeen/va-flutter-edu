import 'package:flutter/material.dart';
import 'dart:ui';

/// 黑板绘制器
///
/// 负责将数据 (Points) 转换为像素 (Pixels) 显示在屏幕上。
/// 继承自 [CustomPainter]，这是 Flutter 中高性能绘制 2D 图形的标准方式。
class BlackboardPainter extends CustomPainter {
  const BlackboardPainter({
    required this.currentStroke,
    required this.historyStrokes,
    required this.lastEraserPosition
  });

  // 数据源：当前笔迹和历史笔迹
  final List<Offset> currentStroke;
  final List<List<Offset>> historyStrokes;
  final Offset? lastEraserPosition;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制背景
    // 使用纯色填充整个画布区域
    final backgroundPaint = Paint()..color = const Color.fromARGB(255, 88, 72, 72);
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    canvas.drawRect(rect, backgroundPaint);

    // 2. 绘制当前正在画的笔迹 (实时反馈)
    if (currentStroke.isNotEmpty) {
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round // 线条端点圆角
        ..strokeJoin = StrokeJoin.round; // 线条连接处圆角

      // PointMode.polygon 会将点按顺序连成折线
      canvas.drawPoints(PointMode.polygon, currentStroke, strokePaint);
    }

    // 3. 绘制历史笔迹 (持久化显示)
    for (final stroke in historyStrokes) {
      final historyStrokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPoints(PointMode.polygon, stroke, historyStrokePaint);
    }

    if (lastEraserPosition != null) {
      final eraserPaint = Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCenter(
        center: lastEraserPosition!,
        width: 26,
        height: 40,
      );
      
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, eraserPaint);

      final borderPaint = Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  /// 控制重绘时机
  ///
  /// 返回 true 表示稍有变动就重绘。
  /// 优化点：虽然这里总是返回 true，但配合 RepaintBoundary 可以控制重绘范围。
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}