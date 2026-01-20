import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart'; 

/// 黑板绘制器 (Plan C: 统一缩放投影画布 + #5 选择能力 + #6 样式支持)
class BlackboardPainter extends CustomPainter {
  const BlackboardPainter({
    required this.currentStrokePoints,
    required this.currentStyle,
    required this.currentStrokeType,
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
    this.eraserSize = 30.0,
    this.laserStrokes = const [],
    this.snapLines = const [], // [New]
  });

  // 数据源
  final List<Offset> currentStrokePoints; // 只有点集，样式由外部传入
  final StrokeStyle currentStyle;
  final StrokeType currentStrokeType;
  
  // [New] 历史不再是 List<List<Offset>> 而是 List<Stroke>
  final List<Stroke> historyStrokes;
  
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
  final double eraserSize;
  final List<Stroke> laserStrokes;
  final List<Offset> snapLines; // [New]吸附辅助线

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
      canvas.drawRect(Rect.fromLTWH(0, startY, 1000, logicalPageHeight), blackboardPaint);

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
        Offset((1000 - textPainter.width) / 2, startY + logicalPageHeight - 30),
      );

      if (i < pageCount - 1) {
          canvas.drawLine(
            Offset(0, startY + logicalPageHeight),
            Offset(1000, startY + logicalPageHeight),
            gapPaint..strokeWidth = 1,
          );
      }
    }

    // --- 绘制历史笔迹 ---
    for (int i = 0; i < historyStrokes.length; i++) {
      final stroke = historyStrokes[i];
      final isSelected = selectedIndexes.contains(i);
      
      final Paint paint = stroke.style.toPaint();
      List<Offset> pointsToDraw = stroke.points;

      // 如果被选中，应用位移 (用于预览)
      if (isSelected && selectionDelta != null && selectionDelta != Offset.zero) {
        pointsToDraw = stroke.points.map((pt) => pt + selectionDelta!).toList();
      }

      // 如果选中，绘制高亮光晕
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.5)
          ..strokeWidth = stroke.style.width + 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        if (stroke.type == StrokeType.text && stroke.text != null) {
           // [Text] 文本选中时绘制边框矩形，而不是文字重绘
           final textPainter = TextPainter(
             text: TextSpan(
               text: stroke.text,
               style: TextStyle(
                 fontSize: stroke.style.width, 
               ),
             ),
             textDirection: TextDirection.ltr,
           )..layout();
           
           final pos = pointsToDraw.first;
           // 稍微留一点 padding
           final rect = Rect.fromLTWH(pos.dx - 4, pos.dy - 4, textPainter.width + 8, textPainter.height + 8);
           // 填充淡蓝色背景
           canvas.drawRRect(
             RRect.fromRectAndRadius(rect, const Radius.circular(4)), 
             Paint()..color = Colors.cyanAccent.withValues(alpha: 0.2)
           );
           // 描边
           canvas.drawRRect(
             RRect.fromRectAndRadius(rect, const Radius.circular(4)), 
             Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 1
           );
        } else {
           _drawStrokeShape(canvas, stroke.type, pointsToDraw, highlightPaint, false); // 高亮不需虚线
        }
      }

      // 绘制本体
      _drawStrokeShape(canvas, stroke.type, pointsToDraw, paint, stroke.style.isDashed, stroke.text);
    }

    // --- 绘制当前正在画的笔迹 ---
    if (currentStrokePoints.isNotEmpty) {
      if (mode == BlackboardMode.laser) {
         // 激光笔实时绘制效果 (亮红)
         final paint = Paint()
          ..color = const Color(0xFFFF5555)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
         _drawStrokeShape(canvas, StrokeType.freehand, currentStrokePoints, paint, false);
         
         final corePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
         _drawStrokeShape(canvas, StrokeType.freehand, currentStrokePoints, corePaint, false);
      } else {
        final paint = currentStyle.toPaint();
        _drawStrokeShape(canvas, currentStrokeType, currentStrokePoints, paint, currentStyle.isDashed, null);
      }
    }

    // --- 绘制激光笔迹 (已完成的正在淡出) ---
    for (final stroke in laserStrokes) {
      if (stroke.createdAt == null) continue;
      final now = DateTime.now();
      final ageMs = now.difference(stroke.createdAt!).inMilliseconds;
      if (ageMs > 3500) continue; // 延长至 3.5s

      double opacity = 1.0;
      if (ageMs > 1500) { // 保持 1.5s 后开始淡出
        opacity = 1.0 - (ageMs - 1500) / 2000.0; // 淡出持续 2s
      }

      final paint = stroke.style.toPaint()
        ..color = Color(stroke.style.color).withValues(alpha: opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      _drawStrokeShape(canvas, stroke.type, stroke.points, paint, false);
      
      final coreColor = Colors.white.withValues(alpha: opacity * 0.8);
      final corePaint = Paint()
        ..color = coreColor
        ..strokeWidth = stroke.style.width * 0.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawStrokeShape(canvas, stroke.type, stroke.points, corePaint, false);
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

    // --- 绘制选中状态的控制台 (Handles) ---
    if (selectedIndexes.isNotEmpty) {
      Rect? collectiveRect;
      for (final index in selectedIndexes) {
        if (index < historyStrokes.length) {
          final stroke = historyStrokes[index];
          List<Offset> pts = stroke.points;
          if (selectionDelta != null && selectionDelta != Offset.zero) {
             pts = pts.map((p) => p + selectionDelta!).toList();
          }
          
          final bounds = _getStrokeBounds(stroke, pts);
          collectiveRect = collectiveRect == null ? bounds : collectiveRect.expandToInclude(bounds);
        }
      }
      
      if (collectiveRect != null) {
        final padding = 4.0;
        final handleRect = collectiveRect.inflate(padding);
        
        // 绘制边缘实线框
        final borderPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRect(handleRect, borderPaint);
        
        // 绘制四个角的手柄
        final handlePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        final handleBorder = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 1.5;
        const hRadius = 4.0;
        
        final corners = [
          handleRect.topLeft,
          handleRect.topRight,
          handleRect.bottomLeft,
          handleRect.bottomRight,
        ];
        
        for (final corner in corners) {
          canvas.drawCircle(corner, hRadius, handlePaint);
          canvas.drawCircle(corner, hRadius, handleBorder);
        }
      }

      // --- 绘制吸附辅助线 (Snapping Lines) ---
      if (snapLines.isNotEmpty) {
        final snapPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.6)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
          
        for (int i = 0; i < snapLines.length - 1; i += 2) {
          final p1 = snapLines[i];
          final p2 = snapLines[i + 1];
          final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy);
          canvas.drawPath(_dashPath(path, 10, 5), snapPaint);
        }
      }
    }

    canvas.restore(); 
    // --- 逻辑画布结束 ---

    // 3. 绘制光标 (保持屏幕原生大小)
    if (currentPointerPosition != null) {
      if (mode == BlackboardMode.eraser) {
        final eraserPaint = Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.fill;

        // 使用 eraserSize
        final rect = Rect.fromCenter(
          center: currentPointerPosition!,
          width: eraserSize,
          height: eraserSize * 1.5, // 保持比例
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(rrect, eraserPaint);

        final borderPaint = Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRRect(rrect, borderPaint);
      } else if (mode == BlackboardMode.pen) {
        if (currentStyle.isHighlighter) {
          // 绘制荧光笔光标 (扁平笔头)
          canvas.save();
          canvas.translate(currentPointerPosition!.dx, currentPointerPosition!.dy);
          // 稍微倾斜，符合书写习惯
          canvas.rotate(15 * 0.0174533);

          final hColor = Color(currentStyle.color).withValues(alpha: 0.5);
          
          // 笔尖 (扁平)
          final tipPaint = Paint()..color = hColor..style = PaintingStyle.fill;
          canvas.drawRect(const Rect.fromLTWH(-8, -2, 16, 4), tipPaint);
          
          // 笔杆
          final bodyPaint = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-10, -30, 20, 28),
              const Radius.circular(4),
            ),
            bodyPaint,
          );
          
          // 笔杆装饰 (荧光标示)
          final accentPaint = Paint()..color = hColor..style = PaintingStyle.fill;
          canvas.drawRect(const Rect.fromLTWH(-10, -20, 20, 8), accentPaint);

          canvas.restore();
        } else {
          // 绘制普通铅笔光标
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
    
          canvas.restore();
        }
      } else if (mode == BlackboardMode.laser) {
        // 激光笔光标 (科技感笔杆 + 发光红点)
        canvas.save();
        canvas.translate(currentPointerPosition!.dx, currentPointerPosition!.dy);
        canvas.rotate(45 * 0.0174533);

        // 笔尖红光
        final glowPaint = Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset.zero, 4, glowPaint);
        
        final corePaint = Paint()..color = Colors.redAccent;
        canvas.drawCircle(Offset.zero, 1.5, corePaint);
        
        // 笔杆 (金属银/深灰)
        final bodyPaint = Paint()..color = const Color(0xFF455A64)..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -24, 6, 20),
            const Radius.circular(1),
          ),
          bodyPaint,
        );
        
        // 笔头锥形部分
        final headPaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
        final headPath = Path()
          ..moveTo(-3, -4)
          ..lineTo(0, 0)
          ..lineTo(3, -4)
          ..close();
        canvas.drawPath(headPath, headPaint);
        
        // 笔尾指示灯
        final tailPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
        canvas.drawRect(const Rect.fromLTWH(-3, -26, 6, 2), tailPaint);

        canvas.restore();
      } else if (mode == BlackboardMode.selection) {
        final selectPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPointerPosition!, 3, selectPaint);
      } else if (mode == BlackboardMode.text) {
        // 文本模式光标：仅显示 "I" 型光标或类似提示
        final textCursorPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
        canvas.drawLine(
          currentPointerPosition! - const Offset(0, 10),
          currentPointerPosition! + const Offset(0, 10),
          textCursorPaint,
        );
        // 横线
        canvas.drawLine(
           currentPointerPosition! - const Offset(3, 10),
           currentPointerPosition! - const Offset(-3, 10),
           textCursorPaint
        );
        canvas.drawLine(
           currentPointerPosition! - const Offset(3, -10),
           currentPointerPosition! - const Offset(-3, -10),
           textCursorPaint
        );
      }
    }
  }

  /// 内部方法：根据类型绘制形状
  void _drawStrokeShape(Canvas canvas, StrokeType type, List<Offset> points, Paint paint, [bool isDashed = false, String? text]) {
    if (points.isEmpty) return;
    
    Path? path;

    switch (type) {
      case StrokeType.text:
        if (text != null && text.isNotEmpty) {
           final textPainter = TextPainter(
             text: TextSpan(
               text: text,
               style: TextStyle(
                 color: paint.color,
                 fontSize: paint.strokeWidth, 
               ),
             ),
             textDirection: TextDirection.ltr,
           );
           textPainter.layout();
           textPainter.paint(canvas, points.first);
        }
        return; 

      case StrokeType.freehand:
        if (points.length == 1) {
          canvas.drawPoints(PointMode.points, points, paint);
          return;
        } else {
          path = Path()..addPolygon(points, false);
        }
        break;
        
      case StrokeType.line:
        if (points.length >= 2) {
          path = Path()..moveTo(points.first.dx, points.first.dy)..lineTo(points.last.dx, points.last.dy);
        }
        break;
        
      case StrokeType.rect:
        if (points.length >= 2) {
          final rect = Rect.fromPoints(points.first, points.last);
          path = Path()..addRect(rect);
        }
        break;
        
      case StrokeType.circle:
        if (points.length >= 2) {
          final rect = Rect.fromPoints(points.first, points.last);
          path = Path()..addOval(rect);
        }
        break;
    }
    
    if (path != null) {
      if (isDashed) {
        final dashWidth = paint.strokeWidth * 3;
        final gapWidth = paint.strokeWidth * 2;
        path = _dashPath(path, dashWidth > 15 ? dashWidth : 15, gapWidth > 10 ? gapWidth : 10);
      }
      canvas.drawPath(path, paint);
    }
  }

  Path _dashPath(Path source, double dashWidth, double gapWidth) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : gapWidth;
        if (draw) {
          final extractEnd = (distance + len < metric.length) ? distance + len : metric.length;
          dest.addPath(metric.extractPath(distance, extractEnd), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  Rect _getStrokeBounds(Stroke stroke, List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    if (stroke.type == StrokeType.text && stroke.text != null) {
       final textPainter = TextPainter(
         text: TextSpan(
           text: stroke.text,
           style: TextStyle(fontSize: stroke.style.width),
         ),
         textDirection: TextDirection.ltr,
       )..layout();
       return Rect.fromLTWH(points.first.dx, points.first.dy, textPainter.width, textPainter.height);
    }
    
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;
    
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    
    final halfWidth = stroke.style.width / 2;
    return Rect.fromLTRB(minX - halfWidth, minY - halfWidth, maxX + halfWidth, maxY + halfWidth);
  }

  @override
  bool shouldRepaint(BlackboardPainter oldDelegate) {
    return oldDelegate.currentStrokePoints != currentStrokePoints || 
           oldDelegate.currentStyle != currentStyle ||
           oldDelegate.currentStrokeType != currentStrokeType ||
           oldDelegate.historyStrokes != historyStrokes ||
           oldDelegate.currentPointerPosition != currentPointerPosition ||
           oldDelegate.scaleFactor != scaleFactor ||
           oldDelegate.mode != mode ||
           oldDelegate.selectedIndexes != selectedIndexes ||
           oldDelegate.marqueeRect != marqueeRect ||
           oldDelegate.selectionDelta != selectionDelta ||
           oldDelegate.eraserSize != eraserSize ||
           oldDelegate.laserStrokes != laserStrokes;
  }
}