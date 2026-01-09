import 'package:flutter/material.dart';

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

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final bool canUndo;
  final bool canRedo;
  final bool canClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF333333),
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
              icon: Icon(
                Icons.undo,
                color: canUndo ? Colors.white : Colors.grey,
              ),
              tooltip: '撤销',
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              icon: Icon(
                Icons.redo,
                color: canRedo ? Colors.white : Colors.grey,
              ),
              tooltip: '重做',
              onPressed: canRedo ? onRedo : null,
            ),
            const SizedBox(height: 8,),
            Container(
              width: 24,
              height: 1,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: canClear ? Colors.red : Colors.grey,
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