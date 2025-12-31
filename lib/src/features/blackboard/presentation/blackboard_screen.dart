import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// RenderObject 渲染层（RenderRepaintBoundary 等）
import 'package:flutter/rendering.dart';
// 平台服务与键盘快捷键（LogicalKeyboardKey/LogicalKeySet 等）
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_tool.dart';
import 'package:va_edu/src/features/blackboard/domain/stroke.dart' as domain;
import 'package:va_edu/src/features/blackboard/presentation/widgets/board_hint.dart';

/// 黑板页面（MVP）
///
/// 组成：
/// - 输入：`Listener` 获取 PointerEvent（适合高频绘制）
/// - 分页：画布只在垂直方向延伸（pageHeight * pageCount），宽度随视口变化
/// - 翻页：鼠标滚轮触发翻页（滚动到页边界），不支持拖拽/缩放画布
/// - 绘制：`CustomPaint` + `_BlackboardPainter`
/// - 状态：`blackboardControllerProvider`（strokes/工具/撤销重做）
class BlackboardScreen extends HookConsumerWidget {
  const BlackboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod：watch 状态触发重建；read notifier 调用命令（undo/redo/startStroke 等）
    final state = ref.watch(blackboardControllerProvider);
    final controller = ref.read(blackboardControllerProvider.notifier);

    // 翻页滚动控制器：禁用拖拽滚动，仅使用鼠标滚轮翻页（动画滚动到页边界）
    final scrollController = useScrollController();
    useListenable(scrollController);

    // 导出图片使用的边界：RepaintBoundary -> Image
    final repaintKey = useMemoized<GlobalKey>(() => GlobalKey());

    // 记录“上一次分页高度”，用于 resize 时保持当前页不跳变
    final lastPageHeight = useRef<double?>(null);
    final resizeResyncScheduled = useRef(false);

    // 提示浮层：仅在交互（滚动/绘制/擦除/拖拽）时显示一小会
    final hintVisible = useState(false);
    final hintHideTimer = useRef<Timer?>(null);

    void showHint() {
      hintVisible.value = true;
      hintHideTimer.value?.cancel();
      hintHideTimer.value = Timer(const Duration(milliseconds: 900), () {
        hintVisible.value = false;
      });
    }

    useEffect(() {
      return () {
        hintHideTimer.value?.cancel();
      };
    }, const []);

    // 导出 PNG（当前仅展示 bytes；后续可做 Web 下载 / macOS 保存文件）
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

    // Focus + Shortcuts + Actions：键盘快捷键统一在这里声明（P/H/E、撤销/重做）
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
            // 背景由 AppShell 提供全局渐变，这里透明以透出背景
            backgroundColor: Colors.transparent,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final viewportHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.sizeOf(context).height;
                final pageHeight = viewportHeight <= 0 ? 1.0 : viewportHeight;

                // 虚拟分页：用滚动偏移换算页数（0 偏移时为 1.0，跨页时会出现 1.3/2.7 等）
                final scrollOffset =
                    scrollController.hasClients ? scrollController.offset : 0.0;
                final rawPage = (scrollOffset / pageHeight) + 1.0;
                final clampedPage =
                    rawPage.clamp(1.0, state.pageCount.toDouble());
                final pageText =
                    '${clampedPage.toStringAsFixed(1)} / ${state.pageCount}';

                // resize 时保持“当前页”一致：按旧 pageHeight 计算页索引，再映射到新 pageHeight。
                final previousPageHeight = lastPageHeight.value;
                if (previousPageHeight != null &&
                    previousPageHeight != pageHeight &&
                    scrollController.hasClients &&
                    !resizeResyncScheduled.value) {
                  resizeResyncScheduled.value = true;
                  final currentPageIndex =
                      (scrollController.offset / previousPageHeight).floor();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      if (!context.mounted || !scrollController.hasClients) {
                        return;
                      }
                      final target = (currentPageIndex * pageHeight).clamp(
                        0.0,
                        scrollController.position.maxScrollExtent,
                      );
                      scrollController.jumpTo(target);
                    } finally {
                      resizeResyncScheduled.value = false;
                    }
                  });
                }
                lastPageHeight.value = pageHeight;

                void scrollByPixels(double deltaY) {
                  if (!scrollController.hasClients) return;
                  final nextOffset = (scrollController.offset + deltaY).clamp(
                    0.0,
                    scrollController.position.maxScrollExtent,
                  );
                  scrollController.jumpTo(nextOffset);
                }

                final canvasSize = Size(
                  constraints.maxWidth,
                  pageHeight * state.pageCount,
                );

                return Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification ||
                            notification is OverscrollNotification ||
                            notification is ScrollEndNotification) {
                          showHint();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: state.tool == BlackboardTool.hand
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          // 鼠标/触控板滚动：连续滚动（手型工具交给 ScrollView 自己处理，避免重复滚动）
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              showHint();
                              if (state.tool != BlackboardTool.hand) {
                                scrollByPixels(event.scrollDelta.dy);
                              }
                            }
                          },
                          onPointerDown: (event) {
                            showHint();
                            final pos = event.localPosition;
                            if (state.tool == BlackboardTool.pen) {
                              controller.startStroke(pos);
                            } else if (state.tool == BlackboardTool.eraser) {
                              controller.eraseAt(pos);
                            }
                          },
                          onPointerMove: (event) {
                            if (state.tool != BlackboardTool.pen) return;
                            showHint();
                            controller.addPoint(event.localPosition);
                          },
                          onPointerUp: (_) {
                            showHint();
                            controller.endStroke();
                          },
                          child: RepaintBoundary(
                            key: repaintKey,
                            child: CustomPaint(
                              size: canvasSize,
                              painter: _BlackboardPainter(
                                pageHeight: pageHeight,
                                pageCount: state.pageCount,
                                strokes: state.strokes,
                                activeStroke: state.activeStroke,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: BoardHint(
                          visible: hintVisible.value,
                          child: Text('当前页数 $pageText'),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        // 工具栏：切换工具 + 撤销/重做/清空/导出
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
                );
              },
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
    // 单个工具按钮样式（轻量的“竖向工具条”）
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
              tooltip: '浏览/翻页 (H)',
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
    // 背景底色
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1E1E1E),
    );

    // 分页分隔线
    final pageLinePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;

    for (var i = 0; i <= pageCount; i++) {
      final y = pageHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pageLinePaint);
    }

    // 已完成的笔迹
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    // 正在绘制中的笔迹
    if (activeStroke case final domain.Stroke stroke) {
      _paintStroke(canvas, stroke);
    }
  }

  void _paintStroke(Canvas canvas, domain.Stroke stroke) {
    if (stroke.points.length < 2) return;

    // 线条样式：圆角端点与连接更像真实笔迹
    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // 当前用折线连接点（后续可做平滑：Bezier/滤波）
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
