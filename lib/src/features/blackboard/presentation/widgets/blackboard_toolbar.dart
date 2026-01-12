import 'package:flutter/material.dart';

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
  });

  // 回调函数，由父组件传入具体逻辑
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  
  // 状态标志，用于控制按钮是否可用 (disabled)
  final bool canUndo;
  final bool canRedo;
  final bool canClear;

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
            IconButton(
              // 根据状态改变图标颜色 (Disabled 状态为半透)
              icon: Icon(
                Icons.undo,
                color: canUndo ? Colors.white : Colors.white24,
              ),
              tooltip: '撤销',
              // onPressed 为 null 时按钮自动禁用
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              icon: Icon(
                Icons.redo,
                color: canRedo ? Colors.white : Colors.white24,
              ),
              tooltip: '重做',
              onPressed: canRedo ? onRedo : null,
            ),
            const SizedBox(height: 8,),
            // 自定义分割线 (Container 替换 Divider 以解决可见性问题)
            Container(
              width: 24,
              height: 1,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              tooltip: '清空',
              onPressed: canClear ? onClear : null,
            ),
          ],
        ),
      ),
    );
  }
}