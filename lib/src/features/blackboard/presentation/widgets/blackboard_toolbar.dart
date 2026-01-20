import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';

// --- 自定义 SVG 图标常量 ---

const String _svgSelection = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 4h3M4 4v3M20 4h-3M20 4v3M4 20h3M4 20v-3M20 20h-3M20 20v-3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  <path d="M10 10l6.5 6.5M16.5 16.5v-4M16.5 16.5h-4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _svgLaser = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M17.5 4.5L19.5 6.5M19.5 4.5L17.5 6.5" stroke="#FF5252" stroke-width="2" stroke-linecap="round"/>
  <path d="M4 20L15 9" stroke="white" stroke-width="2" stroke-linecap="round"/>
  <circle cx="18.5" cy="5.5" r="3" stroke="#FF5252" stroke-width="1" stroke-dasharray="2 2"/>
</svg>
''';

const String _svgEraser = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15.5 4l6 6l-11 11l-7 -7l12 -10z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M10 9l6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M3 21h18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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
    this.onToggleConfigPanel,
    this.isSelectionActive = false,
    required this.onDuplicate,
    required this.onManageLessons,
    required this.onExport,
  });

  // 回调函数，由父组件传入具体逻辑
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final ValueChanged<BlackboardMode> onModeChanged;
  final VoidCallback? onToggleConfigPanel;
  final VoidCallback onDuplicate;
  final VoidCallback onManageLessons;
  final VoidCallback onExport;
  
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
              icon: SvgPicture.string(
                _svgSelection,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  canClear ? Colors.white : Colors.white24,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: '选择 (V)',
              onPressed: canClear ? () => onModeChanged(BlackboardMode.selection) : null,
            ),
            
            // 逻辑分割
            const SizedBox(height: 8),
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
              tooltip: '画笔 (P) - 点击展开配置',
              onPressed: () {
                onModeChanged(BlackboardMode.pen);
                onToggleConfigPanel?.call();
              },
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: mode == BlackboardMode.text ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(22, 22),
              ),
              iconSize: 20,
              icon: const Icon(
                Icons.text_fields,
                color: Colors.white,
              ),
              tooltip: '文本 (T) - 点击添加文本',
              onPressed: () {
                onModeChanged(BlackboardMode.text);
                onToggleConfigPanel?.call();
              },
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: mode == BlackboardMode.laser ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(22, 22),
              ),
              iconSize: 20,
              icon: SvgPicture.string(
                _svgLaser,
                width: 18,
                height: 18,
              ),
              tooltip: '激光笔 (L)',
              onPressed: () {
                onModeChanged(BlackboardMode.laser);
              },
            ),

            // 逻辑分割
            const SizedBox(height: 8),
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
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: mode == BlackboardMode.eraser ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(22, 22),
              ),
              iconSize: 20,
              icon: SvgPicture.string(
                _svgEraser,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  canClear ? Colors.white : Colors.white24,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: '橡皮 (E) - 点击调整大小',
              onPressed: canClear ? () {
                onModeChanged(BlackboardMode.eraser);
                onToggleConfigPanel?.call();
              } : null,
            ),
            
            IconButton(
              iconSize: 20,
              icon: Icon(
                Icons.copy,
                color: isSelectionActive ? Colors.white : Colors.white24,
              ),
              tooltip: '复制选中 (D)',
              onPressed: isSelectionActive ? onDuplicate : null,
            ),

            IconButton(
              iconSize: 22,
              icon: Icon(
                isSelectionActive ? Icons.delete_sweep : Icons.delete_outline,
                color: canClear ? Colors.white : Colors.white24,
              ),
              tooltip: '清空画布 / 删除选中',
              onPressed: canClear ? onClear : null,
            ),
            
            Container(width: 20, height: 1, color: Colors.white12),
            const SizedBox(height: 4),

            IconButton(
              iconSize: 22,
              icon: const Icon(
                Icons.folder_open,
                color: Colors.white,
              ),
              tooltip: '我的课件',
              onPressed: onManageLessons,
            ),

            IconButton(
              iconSize: 22,
              icon: const Icon(
                Icons.ios_share,
                color: Colors.white,
              ),
              tooltip: '导出课件 (PDF/PNG)',
              onPressed: onExport,
            ),
          ],
        ),
      ),
    );
  }
}