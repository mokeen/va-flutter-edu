import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';

/// 页面缩略图组件
/// 
/// 用于在侧边栏显示每一页的预览。
class BlackboardPageThumbnail extends StatelessWidget {
  const BlackboardPageThumbnail({
    super.key,
    required this.strokes,
    required this.pageIndex,
    required this.isSelected,
    required this.onTap,
    required this.aspectRatio,
  });

  final List<Stroke> strokes;
  final int pageIndex;
  final bool isSelected;
  final VoidCallback onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120 / aspectRatio,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.cyanAccent : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ] : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: ThumbnailPainter(strokes: strokes),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '第 ${pageIndex + 1} 页',
            style: TextStyle(
              color: isSelected ? Colors.cyanAccent : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ThumbnailPainter extends CustomPainter {
  ThumbnailPainter({required this.strokes});

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    // 计算缩放：将 1000 宽度的逻辑坐标映射到缩略图 Size
    // 假设 baseWidth 为 1000
    final double scale = size.width / 1000.0;
    canvas.scale(scale);

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.style.color)
        ..strokeWidth = stroke.style.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.style.isHighlighter) {
        paint.color = paint.color.withValues(alpha: 0.5);
        paint.strokeWidth *= 2;
      }

      if (stroke.type == StrokeType.freehand) {
        if (stroke.points.length < 2) continue;
        final path = Path()..addPolygon(stroke.points, false);
        canvas.drawPath(path, paint);
      } else if (stroke.type == StrokeType.text) {
        // 缩略图中简化绘制文字，或者绘制一个矩形代表文字
        // 简单起见，可以绘制一个小矩形
        if (stroke.points.isNotEmpty) {
           final rect = Rect.fromLTWH(stroke.points.first.dx, stroke.points.first.dy, 100, 20);
           canvas.drawRect(rect, paint..style = PaintingStyle.fill..color = paint.color.withValues(alpha: 0.3));
        }
      } else {
        // 线条、矩形、圆
        if (stroke.points.length < 2) continue;
        final p1 = stroke.points.first;
        final p2 = stroke.points.last;
        
        switch (stroke.type) {
          case StrokeType.line:
            canvas.drawLine(p1, p2, paint);
            break;
          case StrokeType.rect:
            canvas.drawRect(Rect.fromPoints(p1, p2), paint);
            break;
          case StrokeType.circle:
            canvas.drawOval(Rect.fromPoints(p1, p2), paint);
            break;
          default:
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ThumbnailPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
