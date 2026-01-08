import 'package:flutter/material.dart';
import 'dart:ui';

/// 黑板绘制器
///
/// 继承自 [CustomPainter]，负责将 [BlackboardScreen] 传递过来的点数据绘制到 [Canvas] 上。
/// 这是一个纯 UI 渲染组件，不应包含业务逻辑。
class BlackboardPainter extends CustomPainter {
  const BlackboardPainter({
    required this.currentStroke,
    required this.historyStrokes,
  });

  /// 当前正在绘制的线条（跟随手指移动实时变化）
  final List<Offset> currentStroke;

  /// 已完成的历史线条列表（静态展示）
  final List<List<Offset>> historyStrokes;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制背景
    // 使用 Paint 对象的级联操作 (..) 快速配置属性
    final backgroundPaint = Paint()..color = const Color.fromARGB(255, 88, 72, 72);
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    // drawRect: 填充整个画布区域
    canvas.drawRect(rect, backgroundPaint);

    // 2. 绘制当前正在画的那一笔
    if (currentStroke.isNotEmpty) {
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke // 显式声明为描边模式
        ..strokeCap = StrokeCap.round  // 线段端点圆滑处理
        ..strokeJoin = StrokeJoin.round; // 线段连接处圆角处理

      // 使用 PointMode.polygon 将点依次连接成线
      canvas.drawPoints(PointMode.polygon, currentStroke, strokePaint);
    }

    // 3. 绘制所有历史笔迹
    // TODO(Optimization): 当笔迹较多时，应考虑使用 RepaintBoundary 分层渲染，避免重绘历史笔迹
    for (final stroke in historyStrokes) {
      final historyStrokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPoints(PointMode.polygon, stroke, historyStrokePaint);
    }
  }

  /// 决定是否重绘
  ///
  /// 在本例中，由于我们在 Screen 中使用 setState 触发重绘，
  /// 且每次都会生成新的 Painter 实例，直接返回 true 确保画面实时更新。
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}