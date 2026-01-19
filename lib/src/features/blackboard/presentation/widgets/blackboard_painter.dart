import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';

/// 黑板绘制器 (Plan C: 统一缩放投影画布 + TODO #5 选择能力)
class BlackboardPainter extends CustomPainter {
  const BlackboardPainter({
    required this.currentStroke,
    required this.historyStrokes,
    required this.currentPointerPosition,
    required this.mode,
    required this.scrollOffset,
    required this.scaleFactor,
    required this.pageCount,
    required this.logicalPageHeight,
    required this.selectedIndexes,
    required this.marqueeRect,
    required this.selectionDelta,
  });

  // 数据源
  final List<Offset> currentStroke;
  final List<List<Offset>> historyStrokes;
  final Offset? currentPointerPosition;
  final BlackboardMode mode;
  final double scrollOffset;
  final double scaleFactor;
  final int pageCount;
  final double logicalPageHeight;

  // 选择相关
  final Set<int> selectedIndexes;
  final Rect? marqueeRect;
  final Offset? selectionDelta;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制全局底色 (深色，作为画布外的背景)
    final backgroundPaint = Paint()..color = const Color(0xFF1A1C1E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    if (scaleFactor <= 0 || logicalPageHeight <= 0) return;

    // 2. 转换坐标系：应用全局缩放和滚动
    canvas.save();
    
    // 先缩放，后续所有绘制都基于 Base 坐标 (1000px 宽度)
    canvas.scale(scaleFactor);
    // 再平移：scrollOffset 是屏幕像素，需要转换为逻辑像素
    canvas.translate(0, -scrollOffset / scaleFactor);

    // --- 逻辑画布开始 ---
    
    final blackboardPaint = Paint()..color = const Color.fromARGB(255, 88, 72, 72);
    final gapPaint = Paint()..color = const Color(0xFF1A1C1E);

    // 绘制每一页的背景和隔离线
    for (int i = 0; i < pageCount; i++) {
      final startY = i * logicalPageHeight;
      
      // 绘制该页黑板面 (逻辑宽度固定为 1000.0)
      canvas.drawRect(Rect.fromLTWH(0, startY, 1000, logicalPageHeight), blackboardPaint);

      // 绘制页码标识 (- N -)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '- ${i + 1} -',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.12),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas, 
        Offset(
          (1000 - textPainter.width) / 2, 
          startY + logicalPageHeight - 30,
        ),
      );

      // 分页线 (只在页间)
      if (i < pageCount - 1) {
          canvas.drawLine(
            Offset(0, startY + logicalPageHeight),
            Offset(1000, startY + logicalPageHeight),
            gapPaint..strokeWidth = 1,
          );
      }
    }

    // 绘制笔迹
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2 // 逻辑像素宽度
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (currentStroke.isNotEmpty) {
      canvas.drawPoints(PointMode.polygon, currentStroke, strokePaint);
    }

    for (int i = 0; i < historyStrokes.length; i++) {
      final stroke = historyStrokes[i];
      final isSelected = selectedIndexes.contains(i);
      
      Paint p = strokePaint;
      List<Offset> pointsToDraw = stroke;

      if (isSelected) {
        // 选中状态：颜色变为青色，且如果正在移动，应用实时位移预览
        p = Paint()
          ..color = Colors.cyanAccent
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        if (selectionDelta != null && selectionDelta != Offset.zero) {
          pointsToDraw = stroke.map((pt) => pt + selectionDelta!).toList();
        }
      }

      canvas.drawPoints(PointMode.polygon, pointsToDraw, p);
    }

    // 绘制框选矩形 (Marquee)
    if (marqueeRect != null) {
      final marqueePaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(marqueeRect!, marqueePaint);

      final marqueeBorder = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(marqueeRect!, marqueeBorder);
    }

    canvas.restore(); 
    // --- 逻辑画布结束 ---

    // 3. 绘制光标 (保持屏幕原生大小，不随画布缩放)
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
        canvas.save();
        canvas.translate(currentPointerPosition!.dx, currentPointerPosition!.dy);
        canvas.rotate(45 * 0.0174533); 
  
        final tipPaint = Paint()..color = const Color(0xFF333333);
        final tipPath = Path()
          ..moveTo(0, 0)
          ..lineTo(-3, -6)
          ..lineTo(3, -6)
          ..close();
        canvas.drawPath(tipPath, tipPaint);
  
        final woodPaint = Paint()..color = const Color(0xFFE6B47C);
        final woodPath = Path()
          ..moveTo(-3, -6)
          ..lineTo(-5, -10)
          ..lineTo(5, -10)
          ..lineTo(3, -6)
          ..close();
        canvas.drawPath(woodPath, woodPaint);
  
        final bodyPaint = Paint()..color = const Color(0xFFFFD54F);
        canvas.drawRect(const Rect.fromLTWH(-5, -28, 10, 18), bodyPaint);
        
        final metalPaint = Paint()..color = const Color(0xFFB0BEC5);
        canvas.drawRect(const Rect.fromLTWH(-5, -30, 10, 3), metalPaint);
  
        final eraserEndPaint = Paint()..color = const Color(0xFFFF8A80);
        canvas.drawRRect(
            RRect.fromRectAndCorners(
              const Rect.fromLTWH(-5, -36, 10, 6),
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2),
            ),
            eraserEndPaint);
  
        final linePaint = Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawLine(const Offset(0, -10), const Offset(0, -28), linePaint);
  
        canvas.restore();
      } else if (mode == BlackboardMode.selection) {
        // 选择模式下的光标 (类似普通鼠标)
        final selectPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(currentPointerPosition!, 3, selectPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BlackboardPainter oldDelegate) {
    return oldDelegate.currentStroke != currentStroke ||
           oldDelegate.historyStrokes != historyStrokes ||
           oldDelegate.currentPointerPosition != currentPointerPosition ||
           oldDelegate.scrollOffset != scrollOffset ||
           oldDelegate.scaleFactor != scaleFactor ||
           oldDelegate.mode != mode ||
           oldDelegate.selectedIndexes != selectedIndexes ||
           oldDelegate.marqueeRect != marqueeRect ||
           oldDelegate.selectionDelta != selectionDelta;
  }
}