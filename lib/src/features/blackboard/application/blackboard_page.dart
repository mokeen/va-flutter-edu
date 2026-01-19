import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_command.dart';

/// 标识单页画板的数据状态
class BlackboardPage {
  final String id;
  
  // 每一页独立的笔迹历史
  final List<List<Offset>> historyStrokes = [];
  
  // 每一页独立的撤销/重做栈
  final List<BlackboardCommand> undoStack = [];
  final List<BlackboardCommand> redoStack = [];

  BlackboardPage({required this.id});
  
  // 清零该页
  void clear() {
    historyStrokes.clear();
    undoStack.clear();
    redoStack.clear();
  }
}
