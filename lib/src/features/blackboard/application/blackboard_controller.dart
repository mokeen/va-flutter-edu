import 'package:flutter/material.dart';

/// 管理画板状态（笔迹历史）与操作逻辑
///
/// 遵循 ChangeNotifier 模式，作为 View (Screen) 与 Data (Stroke) 之间的桥梁。
/// 负责：
/// 1. 维护当前笔迹 (_currentStroke)
/// 2. 维护历史笔迹 (_historyStrokes)
/// 3. 管理撤销/重做栈 (_redoStrokes)
/// 4. 提供绘制动作的方法 (start/move/end)
class BlackboardController extends ChangeNotifier {
  // 当前正在绘制的一笔（点集合）
  final List<Offset> _currentStroke = [];
  
  // 历史笔迹堆栈（用于显示）
  final List<List<Offset>> _historyStrokes = [];
  
  // 撤销笔迹堆栈（用于重做）
  final List<List<Offset>> _redoStrokes = [];

  // Getters (对外只读，防止外部直接修改内部 List)
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  List<List<Offset>> get historyStrokes => List.unmodifiable(_historyStrokes);
  List<List<Offset>> get redoStrokes => List.unmodifiable(_redoStrokes);

  /// 开始绘制 (PointerDown)
  /// 清空重做栈，因为产生了新历史，未来的时间线已失效。
  void startStroke(Offset point) {
    _redoStrokes.clear(); // [Key Logic] 新操作必需清空 Redo 栈
    _currentStroke.clear();
    _currentStroke.add(point);
    notifyListeners();
  }

  /// 移动绘制 (PointerMove)
  void moveStroke(Offset point) {
    _currentStroke.add(point);
    notifyListeners();
  }

  /// 结束绘制 (PointerUp)
  /// 将当前笔迹存入历史。
  void endStroke() {
    if (_currentStroke.isNotEmpty) {
      _historyStrokes.add(List.from(_currentStroke)); // [Key Logic] 深拷贝保存
      _currentStroke.clear();
      notifyListeners();
    }
  }

  /// 撤销 (Undo)
  /// 将历史栈顶的笔迹移入重做栈。
  void undo() {
    if (_historyStrokes.isNotEmpty) {
      _redoStrokes.add(List.from(_historyStrokes.last));
      _historyStrokes.removeLast();
      notifyListeners();
    }
  }

  /// 重做 (Redo)
  /// 将重做栈顶的笔迹移回历史栈。
  void redo() {
    if (_redoStrokes.isNotEmpty) {
      _historyStrokes.add(List.from(_redoStrokes.last));
      _redoStrokes.removeLast();
      notifyListeners();
    }
  }

  /// 清空 (Clear)
  /// 彻底清空所有状态。
  void clear() {
    _historyStrokes.clear();
    _redoStrokes.clear();
    notifyListeners();
  }
}