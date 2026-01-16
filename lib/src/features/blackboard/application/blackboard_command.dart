import 'package:flutter/material.dart';

/// 抽象命令基类 (Command Pattern)
///
/// 每一个对画板状态的修改（画线、擦除）都封装为一个 Command。
/// 核心作用是支持 Undo (回滚) 和 Execute/Redo (重放)。
abstract class BlackboardCommand {
  /// 执行命令 (Redo)
  ///
  /// [strokedHistory] 是当前画布的数据源 List
  void execute(List<List<Offset>> strokedHistory);

  /// 撤销命令 (Undo)
  void undo(List<List<Offset>> strokedHistory);
}

/// ---------------------------------------------------------------------------

/// 绘制命令
/// 对应：用户画了一笔
class DrawCommand implements BlackboardCommand {
  final List<Offset> stroke;

  DrawCommand(this.stroke);

  @override
  void execute(List<List<Offset>> strokedHistory) {
    // Redo: 重新加入这一笔
    strokedHistory.add(stroke);
  }

  @override
  void undo(List<List<Offset>> strokedHistory) {
    // Undo: 移除最后一笔
    // 注意：假设这是栈顶操作，直接 removeLast 效率最高
    if (strokedHistory.isNotEmpty) {
      strokedHistory.removeLast();
    }
  }
}

/// ---------------------------------------------------------------------------

/// 擦除行为原子 (Atom)
/// 
/// 因为一次擦除手势可能会经过多根线条，或者把一根线切成多段。
/// 我们把每一次微小的“切割/删除”动作定义为一个 Action。
class EraseAction {
  // 原线条在 history 里的索引
  final int index;
  // 被删除/切断的旧线条
  final List<Offset> oldStroke;
  // 切断后生成的新线条（List 为空表示完全删除，有数据表示变成了两根或多根）
  final List<List<Offset>> newStrokes;

  EraseAction({
    required this.index,
    required this.oldStroke,
    required this.newStrokes,
  });
}

/// 擦除命令
/// 对应：用户的一次擦除手势 (PointerDown -> Move -> Up)
/// 内部包含了一组有序的原子操作 [actions]。
class EraseCommand implements BlackboardCommand {
  final List<EraseAction> actions;

  EraseCommand(this.actions);

  @override
  void execute(List<List<Offset>> strokedHistory) {
    // Redo 逻辑：按顺序重放所有的擦除操作
    for (final action in actions) {
      // 1. 移除旧线
      // 注意：这里的 index 必须是针对当前这一刻 list 状态的有效索引
      // 在 Controller 生成 actions 时需要保证这一点
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
  void undo(List<List<Offset>> strokedHistory) {
    // Undo 逻辑：必须 **倒序** 回滚 (FILO)
    // 否则索引会因为 List 长度变化而对不上
    for (int i = actions.length - 1; i >= 0; i--) {
      final action = actions[i];
      
      // 1. 如果当时生成了新线条，现在先把它们删掉
      if (action.newStrokes.isNotEmpty) {
         // 我们在 execute 时是从 index 位置开始插入数据的
         // 所以从 index 处移除 newStrokes.length 个元素
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
/// 对应：用户点击了“清空”按钮
/// 这是一个“快照式”命令，它必须保存清空前的所有笔迹以便撤销。
class ClearCommand implements BlackboardCommand {
  // 备份被清空的笔迹
  final List<List<Offset>> _backupStrokes;

  ClearCommand(List<List<Offset>> currentStrokes)
      : _backupStrokes = List.from(currentStrokes); // 浅拷贝：List 结构备份

  @override
  void execute(List<List<Offset>> strokedHistory) {
    strokedHistory.clear();
  }

  @override
  void undo(List<List<Offset>> strokedHistory) {
    // 恢复之前的笔迹
    strokedHistory.clear(); // 防御性清空
    strokedHistory.addAll(_backupStrokes);
  }
}
