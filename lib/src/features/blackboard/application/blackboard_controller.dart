import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';

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

  BlackboardMode _mode = BlackboardMode.pen;

  Offset? _currentPointerPosition;

  // Getters (对外只读，防止外部直接修改内部 List)
  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  List<List<Offset>> get historyStrokes => List.unmodifiable(_historyStrokes);
  List<List<Offset>> get redoStrokes => List.unmodifiable(_redoStrokes);
  BlackboardMode get mode => _mode;
  Offset? get currentPointerPosition => _currentPointerPosition;

  /// 开始绘制 (PointerDown)
  /// 清空重做栈，因为产生了新历史，未来的时间线已失效。
  void startStroke(Offset point) {
    if (_mode == BlackboardMode.pen) {
      _redoStrokes.clear(); // [Key Logic] 新操作必需清空 Redo 栈
      _currentStroke.clear();
      _currentStroke.add(point);
      notifyListeners();
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
            _historyStrokes.removeAt(i);
            final firstPart = stroke.sublist(0, j + 1);
            final secondPart = stroke.sublist(j + 1);
            if (secondPart.isNotEmpty) {
              _historyStrokes.insert(i, secondPart);
            }
            if (firstPart.isNotEmpty) {
              _historyStrokes.insert(i, firstPart);
            }
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
        _historyStrokes.add(List.from(_currentStroke)); // [Key Logic] 深拷贝保存
        _currentStroke.clear();
        notifyListeners();
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