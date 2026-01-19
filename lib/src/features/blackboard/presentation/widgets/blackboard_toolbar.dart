import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';

/// 黑板工具栏
///
/// 包含撤销、重做、清空按钮。
/// 样式模仿 ClassIn 风格：深色胶囊背景 + 白色图标。
class BlackboardToolbar extends StatelessWidget {
  const BlackboardToolbar({
    super.key,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.canUndo,
    required this.canRedo,
    required this.canClear,
    required this.mode,
    required this.onModeChanged,
    this.isSelectionActive = false,
  });

  // 回调函数，由父组件传入具体逻辑
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final ValueChanged<BlackboardMode> onModeChanged;
  
  // 状态标志，用于控制按钮是否可用 (disabled)
  final bool canUndo;
  final bool canRedo;
  final bool canClear;
  final BlackboardMode mode;
  final bool isSelectionActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF333333), // ClassIn 风格深色背景
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 12
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. 操作区 (Manipulation) ---
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(22, 22),
                backgroundColor: mode == BlackboardMode.selection ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              iconSize: 20,
              icon: Icon(
                Icons.pan_tool_alt_outlined,
                color: canClear ? Colors.white : Colors.white24,
              ),
              tooltip: '选择 (V)',
              onPressed: canClear ? () => onModeChanged(BlackboardMode.selection) : null,
            ),
            const SizedBox(height: 8),

            // 逻辑分割
            Container(width: 20, height: 1, color: Colors.white12),
            const SizedBox(height: 8),

            // --- 2. 绘制区 (Creation) ---
            IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(22, 22),
                backgroundColor: mode == BlackboardMode.pen ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              iconSize: 20,
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              tooltip: '画笔 (P)',
              onPressed: () => onModeChanged(BlackboardMode.pen),
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: mode == BlackboardMode.eraser ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(22, 22),
              ),
              iconSize: 20,
              icon: Icon(
                Icons.cleaning_services_outlined,
                color: canClear ? Colors.white : Colors.white24,
              ),
              tooltip: '橡皮 (E)',
              onPressed: canClear ? () => onModeChanged(BlackboardMode.eraser) : null,
            ),
            const SizedBox(height: 8),

            // 逻辑分割
            Container(width: 20, height: 1, color: Colors.white12),
            const SizedBox(height: 8),

            // --- 3. 系统区 (System) ---
            IconButton(
              iconSize: 20,
              icon: Icon(
                Icons.undo,
                color: canUndo ? Colors.white : Colors.white24,
              ),
              tooltip: '撤销',
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              iconSize: 20,
              icon: Icon(
                Icons.redo,
                color: canRedo ? Colors.white : Colors.white24,
              ),
              tooltip: '重做',
              onPressed: canRedo ? onRedo : null,
            ),
            const SizedBox(height: 4),
            IconButton(
              iconSize: 22,
              icon: Icon(
                isSelectionActive ? Icons.delete_sweep : Icons.delete_outline,
                color: canClear ? (isSelectionActive ? Colors.orange : Colors.red) : Colors.white24,
              ),
              tooltip: isSelectionActive ? '删除选中' : '全屏清空',
              onPressed: canClear ? onClear : null,
            ),
          ],
        ),
      ),
    );
  }
}