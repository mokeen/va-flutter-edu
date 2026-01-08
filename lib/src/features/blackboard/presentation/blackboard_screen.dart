import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_painter.dart';

/// 黑板（画板）主页面
///
/// 这是一个有状态组件 (StatefulWidget)，负责管理画板的核心状态（笔迹数据）和交互事件。
/// 它并不直接处理绘制逻辑，而是将数据传递给 [BlackboardPainter] 进行渲染。
class BlackboardScreen extends StatefulWidget {
  const BlackboardScreen({super.key});

  @override
  State<BlackboardScreen> createState() => _BlackboardScreenState();
}

class _BlackboardScreenState extends State<BlackboardScreen> {
  /// 当前正在绘制的一笔。
  ///
  /// 包含了从 [Listener.onPointerDown] 开始，到 [Listener.onPointerMove] 过程中的所有点。
  /// 当 [Listener.onPointerUp] 触发时，该列表会被清空，并未存入 [historyStrokes]。
  List<Offset> currentStroke = [];

  /// 历史笔迹列表。
  ///
  /// 这是一个二维数组，存储了所有已经完成绘制的线条（每一条线都是一个 [Offset] 列表）。
  /// 这里是画板“持久化”数据的内存态。
  List<List<Offset>> historyStrokes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        // 使用 Listener 监听原始指针事件（比 GestureDetector 更底层，无延迟）
        child: Listener(
          onPointerDown: (event) {
            // 手指按下：开始新的一笔
            setState(() {
              // 初始化当前笔迹，存入起始点
              currentStroke = [event.localPosition];
            });
          },
          onPointerMove: (event) {
            // 手指移动：持续收集点
            setState(() {
              // 将新采集的点追加到当前笔迹中
              // 注意：频繁 setState 会触发重绘，这是实时的关键
              currentStroke.add(event.localPosition);
            });
          },
          onPointerUp: (event) {
            // 手指抬起：结束当前笔，归档到历史
            setState(() {
              // 将 currentStroke 添加到历史记录中
              historyStrokes.add(currentStroke);
              // 清空 currentStroke，准备下一次绘制
              // 注意：这里必须重新赋值一个新列表，避免引用问题
              currentStroke = [];
            });
          },
          // CustomPaint 是连接逻辑层与渲染层的桥梁
          child: CustomPaint(
            // 将数据（State）传递给 Painter（View）
            // 只要 points 或 historyStrokes 发生变化，Painter 就会被触发重绘
            painter: BlackboardPainter(
              currentStroke: currentStroke,
              historyStrokes: historyStrokes,
            ),
          ),
        ),
      ),
    );
  }
}
