import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:va_edu/src/features/settings/application/settings_controller.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_export_service.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';
import 'package:va_edu/src/features/blackboard/data/blackboard_repository.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_page_thumbnail.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_painter.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_config_panel.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart';
import 'package:va_edu/src/features/blackboard/presentation/widgets/blackboard_page_control.dart';

/// 黑板主页面 (Plan C: 统一缩放画布)
class BlackboardScreen extends ConsumerStatefulWidget {
  const BlackboardScreen({super.key});

  @override
  ConsumerState<BlackboardScreen> createState() => _BlackboardScreenState();
}

class _BlackboardScreenState extends ConsumerState<BlackboardScreen> {
  late final BlackboardController controller;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsControllerProvider);
    controller = BlackboardController(initialSettings: settings);
  }
  
  // 文本输入状态
  Offset? _textInputPosition;
  bool _isTextInputVisible = false;
  int? _editingTextIndex; // [Add] 正在编辑的历史文本索引
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // 双击检测 [Add]
  DateTime? _lastPointerDownTime;
  Offset? _lastPointerDownPos;

  // 导出状态 [Add]
  bool _isExporting = false;

  @override
  void dispose() {
    controller.dispose();
    _textEditingController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _startTextEditing(Offset position, {int? editIndex, String? initialText}) {
    setState(() {
      _textInputPosition = position;
      _isTextInputVisible = true;
      _editingTextIndex = editIndex;
      _textEditingController.text = initialText ?? '';
      // 请求焦点
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFocusNode.requestFocus();
      });
    });
  }

  void _finishTextEditing() {
    if (_isTextInputVisible && _textInputPosition != null) {
      final text = _textEditingController.text;
      if (text.isNotEmpty) {
        if (_editingTextIndex != null) {
          controller.updateText(_editingTextIndex!, text);
        } else {
           final logicPos = controller.toBasePoint(_textInputPosition!);
           controller.addText(logicPos, text);
        }
      }
      
      setState(() {
        _isTextInputVisible = false;
        _textInputPosition = null;
        _editingTextIndex = null;
        _textEditingController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return KeyboardListener(
            focusNode: FocusNode(), // 简化逻辑，实际应为常驻 Node
            autofocus: true,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                 final isMeta = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
                                  // Cmd + D: 复制
                  if (isMeta && event.logicalKey == LogicalKeyboardKey.keyD) {
                     controller.duplicateSelected();
                  }
                  
                  // Cmd + G: 组合 / Ungroup
                  if (isMeta && event.logicalKey == LogicalKeyboardKey.keyG) {
                     if (HardwareKeyboard.instance.isShiftPressed) {
                        controller.ungroupSelected();
                     } else {
                        controller.groupSelected();
                     }
                  }
                 // 模式切换
                 if (!isMeta) {
                   if (event.logicalKey == LogicalKeyboardKey.keyP) controller.setMode(BlackboardMode.pen);
                   if (event.logicalKey == LogicalKeyboardKey.keyE) controller.setMode(BlackboardMode.eraser);
                   if (event.logicalKey == LogicalKeyboardKey.keyV) controller.setMode(BlackboardMode.selection);
                   if (event.logicalKey == LogicalKeyboardKey.keyT) controller.setMode(BlackboardMode.text);
                   if (event.logicalKey == LogicalKeyboardKey.keyL) controller.setMode(BlackboardMode.laser);
                 }
                 
                 // 层级控制 (仅选择模式下有效，或者全局有效也可)
                 if (!isMeta) {
                   final isShift = HardwareKeyboard.instance.isShiftPressed;
                   if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
                     if (isShift) {
                       controller.sendToBack();
                     } else {
                       controller.sendBackward();
                     }
                   }
                   if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
                     if (isShift) {
                       controller.bringToFront();
                     } else {
                       controller.bringForward();
                     }
                   }
                 }
              }
            },
            child: Stack(
              children: [
               // 基础层 147...
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.updateViewport(constraints.biggest);
                    });

                    return Listener(
                      onPointerDown: (event) {
                        // 点击画布时自动关闭配置面板
                        if (controller.isConfigPanelOpen) {
                          controller.closeConfigPanel();
                        }

                        // 双击检测 (仅选择模式下支持二次编辑)
                        final now = DateTime.now();
                        if (_lastPointerDownTime != null && 
                            now.difference(_lastPointerDownTime!) < const Duration(milliseconds: 300) &&
                            (_lastPointerDownPos! - event.localPosition).distance < 20) {
                          if (controller.mode == BlackboardMode.selection) {
                             // 处理双击
                             final basePoint = controller.toBasePoint(event.localPosition);
                             final hitIndex = controller.findStrokeAt(basePoint);
                             if (hitIndex != -1) {
                               final stroke = controller.historyStrokes[hitIndex];
                               if (stroke.type == StrokeType.text) {
                                  // 进入二次编辑
                                  _startTextEditing(event.localPosition, editIndex: hitIndex, initialText: stroke.text);
                                  return; // 不再执行正常的 startStroke
                               }
                             }
                          }
                        }
                        _lastPointerDownTime = now;
                        _lastPointerDownPos = event.localPosition;

                        if (controller.mode == BlackboardMode.text) {
                           // 如果已经在编辑，点击外部则提交
                           if (_isTextInputVisible) {
                             _finishTextEditing();
                           } else {
                             // 开启新编辑
                             _startTextEditing(event.localPosition);
                           }
                        } else {
                           // 如果切换了模式但输入框还在，先提交
                           if (_isTextInputVisible) {
                             _finishTextEditing();
                           }
                           controller.startStroke(event.localPosition);
                        }
                      },
                      onPointerMove: (event) {
                        if (controller.mode != BlackboardMode.text) {
                          controller.moveStroke(event.localPosition);
                        }
                      },
                      onPointerUp: (event) {
                        if (controller.mode != BlackboardMode.text) {
                          controller.endStroke();
                        }
                      },
                      onPointerHover: (event) => controller.hoverStroke(event.localPosition),
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          controller.handleScroll(event.scrollDelta.dy);
                        }
                      },

                      child: CustomPaint(
                        painter: BlackboardPainter(
                          currentStrokePoints: controller.currentStrokePoints,
                          currentStyle: controller.currentStyle,
                          currentStrokeType: controller.currentStrokeType,
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
                          eraserSize: controller.eraserSize,
                          laserStrokes: controller.laserStrokes,
                          snapLines: controller.snapLines,
                        ),
                      )
                    );
                  }
                ),
              ),
              
              // 浮动选择工具栏 (Selection Context Toolbar)
              _buildSelectionToolbar(context, controller),

              // 文本输入浮层
              if (_isTextInputVisible && _textInputPosition != null)
                Positioned(
                  left: _textInputPosition!.dx,
                  top: _textInputPosition!.dy,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 200, // 初始宽度
                      constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                        ]
                      ),
                      child: KeyboardListener(
                        focusNode: FocusNode(), // 这里的 focusNode 只是为了接收键盘事件
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.enter) {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                // Shift + Enter: 允许换行 (TextField 默认行为)
                                // Do nothing, let TextField handle it
                              } else {
                                // Enter only: 提交
                                _finishTextEditing();
                              }
                            }
                          }
                        },
                        child: TextField(
                          controller: _textEditingController,
                          focusNode: _textFocusNode,
                          autofocus: true,
                          maxLines: null, // 多行
                          textInputAction: TextInputAction.newline, // 软键盘显示换行
                          style: TextStyle(
                            color: Color(controller.currentStyle.color),
                            fontSize: controller.currentStyle.width,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '输入文本...',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
              // ... existing UI ...
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 高级配置面板 (悬浮在工具栏左侧)
                      if (controller.isConfigPanelOpen)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: BlackboardConfigPanel(controller: controller),
                        ),
                        
                      // 主工具栏
                      BlackboardToolbar(
                        onUndo: () => controller.undo(),
                        onRedo: () => controller.redo(),
                        onClear: () => controller.selectedIndexes.isNotEmpty 
                            ? controller.deleteSelected() 
                            : controller.clear(),
                        canUndo: controller.undoStackLength > 0,
                        canRedo: controller.redoStackLength > 0,
                        canClear: controller.historyStrokes.isNotEmpty,
                        mode: controller.mode,
                        onModeChanged: (newMode) => controller.setMode(newMode),
                        onToggleConfigPanel: controller.toggleConfigPanel,
                        onDuplicate: controller.duplicateSelected,
                        onManageLessons: () => _showLessonsDialog(context, controller),
                        onExport: () => _showExportDialog(context, controller),
                        isSelectionActive: controller.selectedIndexes.isNotEmpty,
                      ),
                    ],
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
                    onJumpToPageRequest: () {
                      _showJumpToPageDialog(context, controller);
                    },
                  ),
                ),
              ),

              // 分页概览侧边栏 (最高层级)
              _buildPageOverviewSidebar(context, controller),

              // 导出加载遮罩 [Add]
              if (_isExporting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45, // 半透明背景
                    child: Center(
                      child: Card(
                        elevation: 8,
                        color: const Color(0xFF2C2C2C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.cyanAccent),
                              SizedBox(height: 20),
                              Text(
                                '课程导出中，请稍候...',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildPageOverviewSidebar(BuildContext context, BlackboardController controller) {
    final double sidebarWidth = 160.0;
    final bool isOpen = controller.isPageDrawerOpen;
    
    return Stack(
      children: [
        // 遮罩 (点击关闭)
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => controller.togglePageDrawer(),
              child: Container(color: Colors.transparent),
            ),
          ),
          
        // 侧边栏主体
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          left: isOpen ? 0 : -sidebarWidth,
          top: 0,
          bottom: 0,
          child: Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(4, 0),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '分页概览',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => controller.togglePageDrawer(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.totalPageCount,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: BlackboardPageThumbnail(
                            pageIndex: index,
                            isSelected: controller.currentPageIndex == index,
                            strokes: controller.getStrokesForPage(index),
                            aspectRatio: controller.aspectRatio,
                            onTap: () => controller.jumpToPage(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 外部开关按钮 (未打开时显示)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          left: isOpen ? sidebarWidth - 10 : 0,
          top: MediaQuery.of(context).size.height / 2 - 40,
          child: GestureDetector(
             onTap: () => controller.togglePageDrawer(),
             child: Container(
               width: 32,
               height: 80,
               decoration: BoxDecoration(
                 color: const Color(0xFF252525),
                 borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.2),
                     blurRadius: 4,
                     offset: const Offset(2, 0),
                   )
                 ],
               ),
               child: Center(
                 child: Icon(
                   isOpen ? Icons.chevron_left : Icons.chevron_right,
                   color: Colors.white70,
                   size: 20,
                 ),
               ),
             ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar(BuildContext context, BlackboardController controller) {
    final bounds = controller.selectionBounds;
    final selectedCount = controller.selectedIndexes.length;
    
    if (bounds == null || selectedCount == 0 || controller.mode != BlackboardMode.selection) {
      return const SizedBox.shrink();
    }

    // 转换边界到屏幕坐标
    final topLeft = controller.toScreenPoint(bounds.topLeft);
    final bottomRight = controller.toScreenPoint(bounds.bottomRight);
    final screenBounds = Rect.fromPoints(topLeft, bottomRight);

    // 计算工具栏位置 (在选区上方 50px)
    final top = (screenBounds.top - 55).clamp(80.0, double.infinity);
    final center = screenBounds.center.dx;

    // 检查是否有组
    bool hasGroup = false;
    for (final index in controller.selectedIndexes) {
       if (controller.historyStrokes[index].groupId != null) {
          hasGroup = true;
          break;
       }
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: top,
      left: center - 140, // 假设宽度约为 280
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 组合/解组
              if (selectedCount >= 2 && !hasGroup)
                _ToolbarButton(
                  icon: Icons.group_work_outlined,
                  tooltip: '组合 (Cmd+G)',
                  onPressed: () => controller.groupSelected(),
                )
              else if (hasGroup)
                _ToolbarButton(
                  icon: Icons.group_work,
                  tooltip: '取消组合 (Cmd+Shift+G)',
                  color: Colors.cyanAccent,
                  onPressed: () => controller.ungroupSelected(),
                ),
              
              const VerticalDivider(width: 16, indent: 12, endIndent: 12, color: Colors.white10),
              
              // 层级
              _ToolbarButton(
                icon: Icons.vertical_align_top_rounded,
                tooltip: '置于顶层 (Shift+])',
                onPressed: () => controller.bringToFront(),
              ),
              _ToolbarButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: '上移一层 (])',
                onPressed: () => controller.bringForward(),
              ),
              _ToolbarButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: '下移一层 ([)',
                onPressed: () => controller.sendBackward(),
              ),
              _ToolbarButton(
                icon: Icons.vertical_align_bottom_rounded,
                tooltip: '置于底层 (Shift+[)',
                onPressed: () => controller.sendToBack(),
              ),

              const VerticalDivider(width: 16, indent: 12, endIndent: 12, color: Colors.white10),

              // 复制
              _ToolbarButton(
                icon: Icons.copy_rounded,
                tooltip: '复制 (Cmd+D)',
                onPressed: () => controller.duplicateSelected(),
              ),
              
              // 删除
              _ToolbarButton(
                icon: Icons.delete_outline_rounded,
                tooltip: '删除 (Backspace)',
                color: Colors.redAccent.withValues(alpha: 0.8),
                onPressed: () => controller.deleteSelected(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJumpToPageDialog(BuildContext context, BlackboardController controller) {
    final TextEditingController textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text('跳转到指定页', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: '请输入页码',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
            onSubmitted: (value) {
               _handleJump(context, controller, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => _handleJump(context, controller, textController.text),
              child: const Text('确定', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  void _handleJump(BuildContext context, BlackboardController controller, String value) {
     final int? page = int.tryParse(value);
     if (page != null && page > 0 && page <= controller.totalPageCount) {
       controller.jumpToPage(page - 1);
       Navigator.pop(context);
     } else {
       // 可选：显示错误提示或震动
       Navigator.pop(context); // 暂时直接关闭，或者不关闭
     }
  }

  void _showLessonsDialog(BuildContext context, BlackboardController controller) async {
    if (!context.mounted) return;

    await    showDialog(
      context: context,
      builder: (context) {
        return controller.isLessonsLoading
            ? const Center(child: CircularProgressIndicator())
            : StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('我的课件', style: TextStyle(color: Colors.white)),
                    content: SizedBox(
                      width: 400,
                      height: 400,
                      child: Column(
                        children: [
                          // 新建课件输入
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: '输入新课件名称',
                                    hintStyle: TextStyle(color: Colors.white38),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  onSubmitted: (name) async {
                                    if (name.isNotEmpty) {
                                      controller.newLesson(name);
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24),
                          // 课件列表
                          Expanded(
                            child: FutureBuilder<List<String>>(
                              future: BlackboardRepository().listLessons(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                final lessons = snapshot.data!;
                                return ListView.builder(
                                  itemCount: lessons.length,
                                  itemBuilder: (context, index) {
                                    final name = lessons[index];
                                    return ListTile(
                                      title: Text(name, style: const TextStyle(color: Colors.white)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () async {
                                          await BlackboardRepository().delete(name);
                                          setState(() {});
                                        },
                                      ),
                                      onTap: () async {
                                        await controller.loadLesson(name);
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ],
                  );
                },
              );
      },
    );
  }

  void _showExportDialog(BuildContext context, BlackboardController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('导出课件', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择导出的文件格式：', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            _ExportTypeTile(
              title: '高清 PDF 文档',
              subtitle: '矢量格式，适合打印和长期保存',
              icon: Icons.picture_as_pdf,
              color: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);
                await _performExport(controller, isPdf: true);
              },
            ),
            const SizedBox(height: 12),
            _ExportTypeTile(
              title: '长图图片 (PNG)',
              subtitle: '位图格式，适合在社交媒体分享',
              icon: Icons.image,
              color: Colors.blueAccent,
              onTap: () async {
                Navigator.pop(context);
                await _performExport(controller, isPdf: false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport(BlackboardController controller, {required bool isPdf}) async {
    final messenger = ScaffoldMessenger.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    setState(() => _isExporting = true);

    try {
      // 1. 智能分页：支持跨页笔迹，确保内容 100% 完整
      final Map<int, List<Stroke>> pageMap = {};
      
      for (final stroke in controller.historyStrokes) {
        final bounds = stroke.getBounds();
        // 计算这一笔跨越的页码范围 [minPage, maxPage]
        final int minPage = (bounds.top / controller.logicalPageHeight).floor();
        final int maxPage = (bounds.bottom / controller.logicalPageHeight).floor();
        
        // 将该笔迹分配给所有涉及到的页面，防止边界截断
        for (int i = minPage; i <= maxPage; i++) {
          pageMap.putIfAbsent(i, () => []).add(stroke);
        }
      }

      // 提取有内容的页面索引
      final sortedIndices = pageMap.keys.toList()..sort();
      final int minIdx = sortedIndices.isEmpty ? 0 : sortedIndices.first;
      final int maxIdx = sortedIndices.isEmpty ? 0 : sortedIndices.last;
      
      List<List<Stroke>> exportPages;
      
      if (isPdf) {
        // PDF: 仅导出有内容的页面，节省篇幅
        exportPages = sortedIndices.map((idx) {
          final startY = idx * controller.logicalPageHeight;
          return pageMap[idx]!.map((s) => s.copyWith(
            points: s.points.map((p) => Offset(p.dx, p.dy - startY)).toList(),
          )).toList();
        }).toList();
        if (exportPages.isEmpty) exportPages = [[]];
      } else {
        // PNG: 导出从 minIdx 到 maxIdx 的所有页面，确保垂直空间和物理坐标 100% 对应
        exportPages = List.generate(maxIdx - minIdx + 1, (i) {
          final actualIdx = minIdx + i;
          final startY = actualIdx * controller.logicalPageHeight;
          return (pageMap[actualIdx] ?? []).map((s) => s.copyWith(
            points: s.points.map((p) => Offset(p.dx, p.dy - startY)).toList(),
          )).toList();
        });
      }

      final data = BlackboardData(
        pages: exportPages,
        lastModified: DateTime.now(),
      );

      Uint8List bytes;
      String fileName;
      
      // 优化文件名逻辑：支持中文，仅移除系统禁用的特殊字符
      String lessonPrefix = controller.currentLessonName
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .trim();
      if (lessonPrefix == 'default' || lessonPrefix.isEmpty) {
        lessonPrefix = 'Blackboard';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (isPdf) {
        bytes = await BlackboardExportService.exportToPdf(
          data, 
          logicalHeight: controller.logicalPageHeight,
          darkTheme: false, // PDF 默认使用浅色模式 (打印友好)
        );
        fileName = '${lessonPrefix}_Export_$timestamp.pdf';
      } else {
        bytes = await BlackboardExportService.exportToPng(
          data,
          darkTheme: isDarkMode,
          pageHeight: controller.logicalPageHeight,
        );
        fileName = '${lessonPrefix}_Export_$timestamp.png';
      }
      
      // 关闭任务进度提示，并调起系统“另存为”对话框
      if (mounted) {
        setState(() => _isExporting = false);
      }
      
      final settings = ref.read(settingsControllerProvider);
      
      // 调起系统对话框选择保存位置
      final path = await BlackboardExportService.interactiveSave(
        bytes, 
        fileName, 
        defaultPath: settings.exportPath,
      );
      
      if (path != null && mounted) {
         messenger.showSnackBar(
           SnackBar(
             content: Text('导出成功！已保存至: $path'),
             duration: const Duration(seconds: 5),
             action: SnackBarAction(
               label: '打开目录',
               onPressed: () {
                 BlackboardExportService.revealInFolder(path);
               },
             ),
           )
         );
      } else if (mounted) {
         messenger.showSnackBar(
           const SnackBar(content: Text('已取消导出'))
         );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        messenger.showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }
}

class _ExportTypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportTypeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white70, size: 20),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}

