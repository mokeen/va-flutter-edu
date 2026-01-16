import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_command.dart';

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
  // 历史笔迹堆栈（用于显示，也是 Command 执行的目标）
  final List<List<Offset>> _historyStrokes = [];
  
  // 撤销/重做命令栈 (Command Pattern)
  final List<BlackboardCommand> _undoStack = [];
  final List<BlackboardCommand> _redoStack = [];

  // [Eraser] 当前一次触摸手势中累积的擦除动作
  // 因为 moveStroke 会触发多次，我们需要把这一连串的动作打包成一个 EraseCommand
  final List<EraseAction> _pendingEraseActions = [];

  BlackboardMode _mode = BlackboardMode.pen;

  Offset? _currentPointerPosition;

  // Getters (对外只读，防止外部直接修改内部 List)
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  List<List<Offset>> get historyStrokes => List.unmodifiable(_historyStrokes);
  // Stack 长度用于简单的 UI 状态判断 (canUndo/canRedo)
  int get undoStackLength => _undoStack.length;
  int get redoStackLength => _redoStack.length;
  BlackboardMode get mode => _mode;
  Offset? get currentPointerPosition => _currentPointerPosition;

  /// 开始绘制 (PointerDown)
  /// 清空重做栈，因为产生了新历史，未来的时间线已失效。
  void startStroke(Offset point) {
    if (_mode == BlackboardMode.pen) {
      _redoStack.clear(); // 产生新分支，清空重做栈
      _currentStroke.clear();
      _currentStroke.add(point);
      notifyListeners();
    } else if (_mode == BlackboardMode.eraser) {
      _redoStack.clear();
      _pendingEraseActions.clear(); // 准备记录新的一组擦除动作
    }
    _currentPointerPosition = point;
    notifyListeners();
  }

  /// 移动绘制 (PointerMove)
  void moveStroke(Offset point) {
    if (_mode == BlackboardMode.pen) {
      _currentStroke.add(point);
    } else if (_mode == BlackboardMode.eraser) {
      final eraserRect = Rect.fromCenter(
        center: point,
        width: 26,
        height: 40,
      );
      for (int i = _historyStrokes.length - 1; i >= 0; i--) {
        final stroke = _historyStrokes[i];
        for (int j = 0; j < stroke.length - 1; j++) {
          if (_isSegmentIntersectsRect(stroke[j], stroke[j + 1], eraserRect) || _distToSegment(point, stroke[j], stroke[j + 1]) < 15) {
            
            // --- 命中！准备切割 ---
            
            // 1. 记录原始线条 (Deep Copy)
            final oldStroke = List<Offset>.from(stroke);
            final List<List<Offset>> newStrokes = [];

            // 2. 从画布移除
            _historyStrokes.removeAt(i);
            
            // 3. 计算切断后的片段
            final firstPart = stroke.sublist(0, j + 1);
            final secondPart = stroke.sublist(j + 1);
            
            // 4. 将新片段插回画布 (注意顺序)
            // 结果顺序必须是 [firstPart, secondPart]
            // insert(i, second) -> [..., second, ...]
            // insert(i, first)  -> [..., first, second, ...]
            if (secondPart.isNotEmpty) {
              _historyStrokes.insert(i, secondPart);
              newStrokes.add(secondPart);
            }
            if (firstPart.isNotEmpty) {
              _historyStrokes.insert(i, firstPart);
              newStrokes.insert(0, firstPart); // 加到前面
            }

            // 5. 记录这个原子动作
            _pendingEraseActions.add(EraseAction(
              index: i, 
              oldStroke: oldStroke, 
              newStrokes: newStrokes
            ));

            break; 
          }
        }
      }
    }
    _currentPointerPosition = point;
    notifyListeners();
  }

  /// 结束绘制 (PointerUp)
  /// 将当前笔迹存入历史。
  void endStroke() {
    if (_mode == BlackboardMode.pen) {
      if (_currentStroke.isNotEmpty) {
        // [Command Pattern] 封装绘制命令
        final strokeData = List<Offset>.from(_currentStroke);
        final command = DrawCommand(strokeData);
        
        // 执行并入栈 (注: 现在的 UI 逻辑其实是先画了再存 command，
        // DrawCommand.execute 其实是 history.add。
        // 为了逻辑闭环，我们这里还是应该走 execute，或者仅仅是把 data 加进去
        // 现在的逻辑是：moveStroke 已经把 pixel 画在屏幕上了吗？
        // 不，moveStroke 只是加到了 _currentStroke（UI 层的暂存区）。
        // _historyStrokes 还没加呢。
        // 所以这里调用 execute 是非常正确的。)
        
        command.execute(_historyStrokes);
        _undoStack.add(command);

        _currentStroke.clear();
        notifyListeners();
      }
    } else if (_mode == BlackboardMode.eraser) {
        // [Command Pattern] 如果产生了擦除动作，打包入栈
        if (_pendingEraseActions.isNotEmpty) {
          final command = EraseCommand(List.from(_pendingEraseActions));
          _undoStack.add(command);
          _pendingEraseActions.clear();
        }
    }
    _currentPointerPosition = null;
    notifyListeners();
  }

  void hoverStroke(Offset point) {
    _currentPointerPosition = point;
    notifyListeners();
  }

  /// 撤销 (Undo)
  /// 将历史栈顶的笔迹移入重做栈。
  void undo() {
    if (_undoStack.isNotEmpty) {
      final command = _undoStack.removeLast();
      command.undo(_historyStrokes);
      _redoStack.add(command);
      notifyListeners();
    }
  }

  /// 重做 (Redo)
  void redo() {
    if (_redoStack.isNotEmpty) {
      final command = _redoStack.removeLast();
      command.execute(_historyStrokes);
      _undoStack.add(command);
      notifyListeners();
    }
  }

  /// 清空 (Clear)
  /// 使用 Command Pattern，使其可撤销。
  void clear() {
    if (_historyStrokes.isNotEmpty) {
      final command = ClearCommand(_historyStrokes);
      command.execute(_historyStrokes);
      
      _undoStack.add(command);
      _redoStack.clear(); // 清空产生新历史，重做栈失效
      _pendingEraseActions.clear();
      
      notifyListeners();
    }
  }

  void setMode(BlackboardMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  bool _isSegmentIntersectsRect(Offset p1, Offset p2, Rect rect) {
    if (rect.contains(p1) || rect.contains(p2)) return true;
    
    final double minx = p1.dx < p2.dx ? p1.dx : p2.dx;
    final double maxx = p1.dx > p2.dx ? p1.dx : p2.dx;
    final double miny = p1.dy < p2.dy ? p1.dy : p2.dy;
    final double maxy = p1.dy > p2.dy ? p1.dy : p2.dy;
    
    return rect.left <= minx && maxx <= rect.right && rect.top <= miny && maxy <= rect.bottom;
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final double l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    
    double t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = t.clamp(0, 1);
    
    final Offset projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - projection).distance;
  }
}