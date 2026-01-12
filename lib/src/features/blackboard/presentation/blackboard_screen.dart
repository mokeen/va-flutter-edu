import 'package:flutter/material.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';

import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_painter.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart';

/// 黑板主页面
///
/// 职责：
/// 1. 组装 UI：Stack (底层 Canvas + 上层 Toolbar)
/// 2. 事件分发：Listener -> Controller
/// 3. 状态监听：ListenableBuilder 监听 Controller 变化并刷新 UI
class BlackboardScreen extends StatefulWidget {
  const BlackboardScreen({super.key});

  @override
  State<BlackboardScreen> createState() => _BlackboardScreenState();
}

class _BlackboardScreenState extends State<BlackboardScreen> {
  // [Refactor] 逻辑上移至 Controller，本地不再持有状态
  final controller = BlackboardController();

  @override
  void dispose() {
    controller.dispose(); // 记得销毁
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  // [Refactor] 所有的手势事件直接委托给 Controller 处理
                  onPointerDown: (event) => controller.startStroke(event.localPosition),
                  onPointerMove: (event) => controller.moveStroke(event.localPosition),
                  onPointerUp: (event) => controller.endStroke(),

                  // 使用 ListenableBuilder 监听 Controller，当 notifyListeners 被调用时重绘
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: BlackboardPainter(
                          // 从 Controller 获取最新的只读数据
                          currentStroke: controller.currentStroke,
                          historyStrokes: controller.historyStrokes,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: BlackboardToolbar(
                    onUndo: () => controller.undo(),
                    onRedo: () => controller.redo(),
                    onClear: () => controller.clear(),
                    canUndo: controller.historyStrokes.isNotEmpty,
                    canRedo: controller.redoStrokes.isNotEmpty,
                    canClear: controller.historyStrokes.isNotEmpty,
                  ),
                ),
              ),
            ]
          );
        },
      )
    );
  }
}
