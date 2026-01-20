import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';

/// 抽象命令基类 (Command Pattern)
///
/// 每一个对画板状态的修改（画线、擦除）都封装为一个 Command。
/// 核心作用是支持 Undo (回滚) 和 Execute/Redo (重放)。
abstract class BlackboardCommand {
  /// 执行命令 (Redo)
  ///
  /// [strokedHistory] 是当前画布的数据源 List
  void execute(List<Stroke> strokedHistory);

  /// 撤销命令 (Undo)
  void undo(List<Stroke> strokedHistory);
}

/// ---------------------------------------------------------------------------

/// 绘制命令
/// 对应：用户画了一笔
class DrawCommand implements BlackboardCommand {
  final Stroke stroke;

  DrawCommand(this.stroke);

  @override
  void execute(List<Stroke> strokedHistory) {
    // Redo: 重新加入这一笔
    strokedHistory.add(stroke);
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    // Undo: 移除最后一笔
    if (strokedHistory.isNotEmpty) {
      strokedHistory.removeLast();
    }
  }
}

/// ---------------------------------------------------------------------------

/// 擦除行为原子 (Atom)
class EraseAction {
  // 原线条在 history 里的索引
  final int index;
  // 被删除/切断的旧线条
  final Stroke oldStroke;
  // 切断后生成的新线条（List 为空表示完全删除，有数据表示变成了两根或多根）
  final List<Stroke> newStrokes;

  EraseAction({
    required this.index,
    required this.oldStroke,
    required this.newStrokes,
  });
}

/// 擦除命令
class EraseCommand implements BlackboardCommand {
  final List<EraseAction> actions;

  EraseCommand(this.actions);

  @override
  void execute(List<Stroke> strokedHistory) {
    // Redo 逻辑：按顺序重放所有的擦除操作
    for (final action in actions) {
      // 1. 移除旧线
      if (action.index < strokedHistory.length) {
        strokedHistory.removeAt(action.index);
        
        // 2. 插入新线（倒序插入，确保索引不乱）
        if (action.newStrokes.isNotEmpty) {
          for (int i = action.newStrokes.length - 1; i >= 0; i--) {
            strokedHistory.insert(action.index, action.newStrokes[i]);
          }
        }
      }
    }
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    // Undo 逻辑：必须 **倒序** 回滚 (FILO)
    for (int i = actions.length - 1; i >= 0; i--) {
      final action = actions[i];
      
      // 1. 如果当时生成了新线条，现在先把它们删掉
      if (action.newStrokes.isNotEmpty) {
         for (int k = 0; k < action.newStrokes.length; k++) {
           if (action.index < strokedHistory.length) {
             strokedHistory.removeAt(action.index);
           }
         }
      }

      // 2. 把旧线条插回原位，完美复原
      strokedHistory.insert(action.index, action.oldStroke);
    }
  }
}

/// ---------------------------------------------------------------------------

/// 清空命令
class ClearCommand implements BlackboardCommand {
  // 备份被清空的笔迹
  final List<Stroke> _backupStrokes;

  ClearCommand(List<Stroke> currentStrokes)
      : _backupStrokes = List.from(currentStrokes); // 浅拷贝：List 结构备份

  @override
  void execute(List<Stroke> strokedHistory) {
    strokedHistory.clear();
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    // 恢复之前的笔迹
    strokedHistory.clear(); 
    strokedHistory.addAll(_backupStrokes);
  }
}

/// ---------------------------------------------------------------------------

/// 移动命令
class MoveCommand implements BlackboardCommand {
  final Set<int> indices;
  final Offset delta;

  MoveCommand(this.indices, this.delta);

  @override
  void execute(List<Stroke> strokedHistory) {
    for (final index in indices) {
      if (index >= 0 && index < strokedHistory.length) {
        final stroke = strokedHistory[index];
        for (int i = 0; i < stroke.points.length; i++) {
          stroke.points[i] += delta;
        }
      }
    }
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    for (final index in indices) {
      if (index >= 0 && index < strokedHistory.length) {
        final stroke = strokedHistory[index];
        for (int i = 0; i < stroke.points.length; i++) {
          stroke.points[i] -= delta;
        }
      }
    }
  }
}

/// ---------------------------------------------------------------------------

/// 更新操作命令 (整体替换某个位置的 Stroke 对象)
class UpdateCommand implements BlackboardCommand {
  final int index;
  final Stroke oldStroke;
  final Stroke newStroke;

  UpdateCommand(this.index, this.oldStroke, this.newStroke);

  @override
  void execute(List<Stroke> strokedHistory) {
    if (index >= 0 && index < strokedHistory.length) {
      strokedHistory[index] = newStroke;
    }
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    if (index >= 0 && index < strokedHistory.length) {
      strokedHistory[index] = oldStroke;
    }
  }
}

/// 复制操作命令
class DuplicateCommand implements BlackboardCommand {
  final List<Stroke> newStrokes;
  final int startIndex; // 插入的起始位置

  DuplicateCommand(this.newStrokes, this.startIndex);

  @override
  void execute(List<Stroke> strokedHistory) {
    // 从 startIndex 开始插入
    for (int i = 0; i < newStrokes.length; i++) {
      if (startIndex + i <= strokedHistory.length) {
        strokedHistory.insert(startIndex + i, newStrokes[i]);
      } else {
        strokedHistory.add(newStrokes[i]);
      }
    }
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    // 逆序移除
    for (int i = newStrokes.length - 1; i >= 0; i--) {
      final targetIndex = startIndex + i;
      if (targetIndex < strokedHistory.length) {
        strokedHistory.removeAt(targetIndex);
      }
    }
  }
}

/// 层级重排命令
class ReorderCommand implements BlackboardCommand {
  final List<Stroke> oldHistory;
  final List<Stroke> newHistory;

  ReorderCommand(List<Stroke> oldH, List<Stroke> newH)
      : oldHistory = List.from(oldH),
        newHistory = List.from(newH);

  @override
  void execute(List<Stroke> strokedHistory) {
    strokedHistory.clear();
    strokedHistory.addAll(newHistory);
  }

  @override
  void undo(List<Stroke> strokedHistory) {
    strokedHistory.clear();
    strokedHistory.addAll(oldHistory);
  }
}
