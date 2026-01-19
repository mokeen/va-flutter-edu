import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';

import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_painter.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_page_control.dart';

/// 黑板主页面 (Plan C: 统一缩放画布)
class BlackboardScreen extends StatefulWidget {
  const BlackboardScreen({super.key});

  @override
  State<BlackboardScreen> createState() => _BlackboardScreenState();
}

class _BlackboardScreenState extends State<BlackboardScreen> {
  final controller = BlackboardController();

  @override
  void dispose() {
    controller.dispose();
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // [IMPORTANT] 实时更新 Controller 的视口大小，用于计算缩放和滚动边界
                    // 这里避开在 build 期间调用 setState，updateViewport 内部有同步处理
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.updateViewport(constraints.biggest);
                    });

                    return Listener(
                      onPointerDown: (event) => controller.startStroke(event.localPosition),
                      onPointerMove: (event) => controller.moveStroke(event.localPosition),
                      onPointerUp: (event) => controller.endStroke(),
                      onPointerHover: (event) => controller.hoverStroke(event.localPosition),
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          controller.handleScroll(event.scrollDelta.dy);
                        }
                      },

                      child: CustomPaint(
                        painter: BlackboardPainter(
                          currentStroke: controller.currentStroke,
                          historyStrokes: controller.historyStrokes,
                          currentPointerPosition: controller.currentPointerPosition,
                          mode: controller.mode,
                          scrollOffset: controller.scrollOffset,
                          scaleFactor: controller.scaleFactor,
                          pageCount: controller.totalPageCount,
                          logicalPageHeight: controller.logicalPageHeight,
                          selectedIndexes: controller.selectedIndexes,
                          marqueeRect: controller.marqueeRect,
                          selectionDelta: controller.selectionCurrentDelta,
                        ),
                      )
                    );
                  }
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
                    onClear: () => controller.selectedIndexes.isNotEmpty 
                        ? controller.deleteSelected() 
                        : controller.clear(),
                    canUndo: controller.undoStackLength > 0,
                    canRedo: controller.redoStackLength > 0,
                    canClear: controller.historyStrokes.isNotEmpty,
                    mode: controller.mode,
                    onModeChanged: (mode) => controller.setMode(mode),
                    isSelectionActive: controller.selectedIndexes.isNotEmpty,
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: BlackboardPageControl(
                    currentPageIndex: controller.currentPageIndex,
                    pageCount: controller.totalPageCount,
                    onPrevPage: () => controller.prevPage(),
                    onNextPage: () => controller.nextPage(),
                    onHome: () => controller.jumpToHome(),
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
