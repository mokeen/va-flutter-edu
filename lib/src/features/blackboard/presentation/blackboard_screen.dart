import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_tool.dart';
import 'package:va_edu/src/features/blackboard/domain/stroke.dart' as domain;

class BlackboardScreen extends HookConsumerWidget {
  const BlackboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blackboardControllerProvider);
    final controller = ref.read(blackboardControllerProvider.notifier);

    final transformController = useMemoized(TransformationController.new);
    useEffect(() => transformController.dispose, [transformController]);
    useListenable(transformController);

    final repaintKey = useMemoized<GlobalKey>(() => GlobalKey());

    Offset toWorld(Offset viewportLocalPosition) {
      return transformController.toScene(viewportLocalPosition);
    }

    String computePageText() {
      final size = MediaQuery.sizeOf(context);
      final viewportCenter = Offset(size.width / 2, size.height / 2);
      final sceneCenter = transformController.toScene(viewportCenter);
      final rawPage = (sceneCenter.dy / state.pageHeight) + 1.0;
      final clampedPage = rawPage.clamp(1.0, state.pageCount.toDouble());
      return '${clampedPage.toStringAsFixed(1)} / ${state.pageCount}';
    }

    Future<void> exportPng() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('PNG bytes: ${bytes.lengthInBytes}')),
      );
    }

    final pageText = computePageText();

    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
              const _UndoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
              const _UndoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyZ,
          ): const _RedoIntent(),
          LogicalKeySet(
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.keyZ,
          ): const _RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.keyP):
              const _SetToolIntent(BlackboardTool.pen),
          LogicalKeySet(LogicalKeyboardKey.keyH):
              const _SetToolIntent(BlackboardTool.hand),
          LogicalKeySet(LogicalKeyboardKey.keyE):
              const _SetToolIntent(BlackboardTool.eraser),
        },
        child: Actions(
          actions: {
            _UndoIntent: CallbackAction<_UndoIntent>(onInvoke: (_) {
              controller.undo();
              return null;
            }),
            _RedoIntent: CallbackAction<_RedoIntent>(onInvoke: (_) {
              controller.redo();
              return null;
            }),
            _SetToolIntent: CallbackAction<_SetToolIntent>(onInvoke: (intent) {
              controller.setTool(intent.tool);
              return null;
            }),
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                final pos = toWorld(event.localPosition);
                if (state.tool == BlackboardTool.pen) {
                  controller.startStroke(pos);
                } else if (state.tool == BlackboardTool.eraser) {
                  controller.eraseAt(pos);
                }
              },
              onPointerMove: (event) {
                if (state.tool != BlackboardTool.pen) return;
                controller.addPoint(toWorld(event.localPosition));
              },
              onPointerUp: (_) => controller.endStroke(),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: transformController,
                    panEnabled: state.tool == BlackboardTool.hand,
                    scaleEnabled: state.tool == BlackboardTool.hand,
                    minScale: 0.2,
                    maxScale: 6.0,
                    boundaryMargin: const EdgeInsets.all(1e9),
                    constrained: false,
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: CustomPaint(
                        size: Size(
                          state.pageWidth,
                          state.pageHeight * state.pageCount,
                        ),
                        painter: _BlackboardPainter(
                          pageHeight: state.pageHeight,
                          pageCount: state.pageCount,
                          strokes: state.strokes,
                          activeStroke: state.activeStroke,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text('当前页数 $pageText'),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _ToolBar(
                        tool: state.tool,
                        onToolSelected: controller.setTool,
                        onUndo: controller.undo,
                        onRedo: controller.redo,
                        onClear: controller.clear,
                        onExport: exportPng,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.tool,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onExport,
  });

  final BlackboardTool tool;
  final ValueChanged<BlackboardTool> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    Widget toolButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      bool selected = false,
    }) {
      return IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: selected ? Colors.white24 : Colors.white10,
        ),
        icon: Icon(icon),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            toolButton(
              icon: Icons.brush,
              tooltip: '画笔 (P)',
              selected: tool == BlackboardTool.pen,
              onPressed: () => onToolSelected(BlackboardTool.pen),
            ),
            toolButton(
              icon: Icons.pan_tool_alt,
              tooltip: '平移/缩放 (H)',
              selected: tool == BlackboardTool.hand,
              onPressed: () => onToolSelected(BlackboardTool.hand),
            ),
            toolButton(
              icon: Icons.auto_fix_high,
              tooltip: '橡皮擦 (E)',
              selected: tool == BlackboardTool.eraser,
              onPressed: () => onToolSelected(BlackboardTool.eraser),
            ),
            const SizedBox(height: 8),
            toolButton(
              icon: Icons.undo,
              tooltip: '撤销 (Cmd/Ctrl+Z)',
              onPressed: onUndo,
            ),
            toolButton(
              icon: Icons.redo,
              tooltip: '重做 (Cmd/Ctrl+Shift+Z)',
              onPressed: onRedo,
            ),
            toolButton(
              icon: Icons.delete_sweep,
              tooltip: '清空',
              onPressed: onClear,
            ),
            toolButton(
              icon: Icons.image_outlined,
              tooltip: '导出 PNG (占位)',
              onPressed: onExport,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlackboardPainter extends CustomPainter {
  _BlackboardPainter({
    required this.pageHeight,
    required this.pageCount,
    required this.strokes,
    required this.activeStroke,
  });

  final double pageHeight;
  final int pageCount;
  final List<domain.Stroke> strokes;
  final domain.Stroke? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1E1E1E),
    );

    final pageLinePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;

    for (var i = 0; i <= pageCount; i++) {
      final y = pageHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pageLinePaint);
    }

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (activeStroke case final domain.Stroke stroke) {
      _paintStroke(canvas, stroke);
    }
  }

  void _paintStroke(Canvas canvas, domain.Stroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
    for (var i = 1; i < stroke.points.length; i++) {
      final p = stroke.points[i];
      path.lineTo(p.x, p.y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlackboardPainter oldDelegate) {
    return oldDelegate.pageHeight != pageHeight ||
        oldDelegate.pageCount != pageCount ||
        oldDelegate.strokes != strokes ||
        oldDelegate.activeStroke != activeStroke;
  }
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SetToolIntent extends Intent {
  const _SetToolIntent(this.tool);

  final BlackboardTool tool;
}
