import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';

/// 黑板绘制器
///
/// 负责将数据 (Points) 转换为像素 (Pixels) 显示在屏幕上。
/// 继承自 [CustomPainter]，这是 Flutter 中高性能绘制 2D 图形的标准方式。
class BlackboardPainter extends CustomPainter {
  const BlackboardPainter({
    required this.currentStroke,
    required this.historyStrokes,
    required this.currentPointerPosition,
    required this.mode
  });

  // 数据源：当前笔迹和历史笔迹
  final List<Offset> currentStroke;
  final List<List<Offset>> historyStrokes;
  final Offset? currentPointerPosition;
  final BlackboardMode mode;

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

    if (currentPointerPosition != null) {
      if (mode == BlackboardMode.eraser) {
        final eraserPaint = Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.fill;

        final rect = Rect.fromCenter(
          center: currentPointerPosition!,
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
      } else if (mode == BlackboardMode.pen) {
        // --- 绘制画笔指示器 (Pen Cursor) ---
        canvas.save();
        canvas.translate(currentPointerPosition!.dx, currentPointerPosition!.dy);
        // 旋转 45 度 (向右倾斜，模拟右手握笔)
        canvas.rotate(45 * 0.0174533); 
  
        // 1. 笔尖 (石墨色)
        final tipPaint = Paint()..color = const Color(0xFF333333);
        final tipPath = Path()
          ..moveTo(0, 0)
          ..lineTo(-3, -6)
          ..lineTo(3, -6)
          ..close();
        canvas.drawPath(tipPath, tipPaint);
  
        // 2. 笔木质部分 (浅木色)
        final woodPaint = Paint()..color = const Color(0xFFE6B47C);
        final woodPath = Path()
          ..moveTo(-3, -6)
          ..lineTo(-5, -10)
          ..lineTo(5, -10)
          ..lineTo(3, -6)
          ..close();
        canvas.drawPath(woodPath, woodPaint);
  
        // 3. 笔身 (经典铅笔黄)
        final bodyPaint = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawRect(const Rect.fromLTWH(-5, -28, 10, 18), bodyPaint);
        
        // 4. 笔末端金属扣 (银色)
        final metalPaint = Paint()..color = const Color(0xFFB0BEC5);
        canvas.drawRect(const Rect.fromLTWH(-5, -30, 10, 3), metalPaint);
  
        // 5. 笔末端 (粉色橡皮)
        final eraserEndPaint = Paint()..color = const Color(0xFFFF8A80);
        canvas.drawRRect(
            RRect.fromRectAndCorners(
              const Rect.fromLTWH(-5, -36, 10, 6),
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2),
            ),
            eraserEndPaint);
  
        // 6. 装饰中线
        final linePaint = Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawLine(const Offset(0, -10), const Offset(0, -28), linePaint);
  
        canvas.restore();
      }
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