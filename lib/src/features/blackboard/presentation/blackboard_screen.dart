import 'package:flutter/material.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';

import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_painter.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart';

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
                child: Listener(
                  onPointerDown: (event) {
                    controller.startStroke(event.localPosition);
                  },
                  onPointerMove: (event) {
                    controller.moveStroke(event.localPosition);
                  },
                  onPointerUp: (event) {
                    controller.endStroke();
                  },
                  child: CustomPaint(
                    painter: BlackboardPainter(
                      currentStroke: controller.currentStroke,
                      historyStrokes: controller.historyStrokes,
                    ),
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
