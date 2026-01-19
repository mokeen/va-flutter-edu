import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_command.dart';

/// 管理画板状态与操作逻辑 (Plan C: 统一缩放投影画布)
class BlackboardController extends ChangeNotifier {
  // --- 核心常量 (ClassIn 风格) ---
  static const double baseWidth = 1000.0;       // 逻辑参考宽度
  static const int pageCount = 50;              // 默认固定 50 页

  // --- 状态变量 ---
  
  // 所有的历史笔迹 (统一存储在 Base 坐标系下)
  final List<List<Offset>> _historyStrokes = [];
  
  // 当前正在绘制的笔迹 (Base 坐标)
  final List<Offset> _currentStroke = [];

  // 全局撤销/重做栈
  final List<BlackboardCommand> _undoStack = [];
  final List<BlackboardCommand> _redoStack = [];

  // [Eraser] 擦除动作暂存
  final List<EraseAction> _pendingEraseActions = [];

  // 当前视口参数
  Size _viewportSize = Size.zero;
  double _scaleFactor = 1.0;
  double _scrollOffset = 0.0; // 这是屏幕层面的偏移

  BlackboardMode _mode = BlackboardMode.pen;
  Offset? _currentPointerPosition; // 屏幕坐标

  // --- [Selection] 选择相关状态 ---
  final Set<int> _selectedIndexes = {};      // 已选中笔迹的索引
  Rect? _marqueeRect;                         // 框选矩形 (Base 坐标)
  bool _isMovingSelection = false;            // 是否正在移动选中的内容
  Offset? _selectionDragStart;                // 移动开始时的逻辑坐标
  Offset? _selectionCurrentDelta;             // 当前移动的增量 (用于实时预览)

  // --- Getters ---

  // 动态计算逻辑页高：一页刚好撑满一个视口高度
  double get logicalPageHeight => _scaleFactor > 0 ? (_viewportSize.height / _scaleFactor) : 0.0;

  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  List<List<Offset>> get historyStrokes => List.unmodifiable(_historyStrokes);
  
  int get undoStackLength => _undoStack.length;
  int get redoStackLength => _redoStack.length;
  
  BlackboardMode get mode => _mode;
  Offset? get currentPointerPosition => _currentPointerPosition;
  double get scrollOffset => _scrollOffset;
  double get scaleFactor => _scaleFactor;

  // 选择状态映射
  Set<int> get selectedIndexes => Set.unmodifiable(_selectedIndexes);
  Rect? get marqueeRect => _marqueeRect;
  Offset? get selectionCurrentDelta => _selectionCurrentDelta;

  // 根据当前滚动位置计算所在页码 (1-indexed)
  int get currentPageIndex {
    final pageH = logicalPageHeight;
    if (pageH <= 0) return 0;
    
    // 逻辑偏移 = 屏幕偏移 / 缩放系数
    final logicalScroll = _scrollOffset / _scaleFactor;
    // 以视口中心或上方一点作为判定
    final judgePoint = logicalScroll + (pageH * 0.3);
    final int index = (judgePoint / pageH).floor();
    return index.clamp(0, pageCount - 1);
  }

  int get totalPageCount => pageCount;
  String get currentPageId => (currentPageIndex + 1).toString();

  // --- 生命周期 ---

  /// 更新视口大小并重新计算缩放系数
  void updateViewport(Size size) {
    if (_viewportSize == size) return;
    
    // 宽度决定一切：缩放系数 = 当前宽度 / 逻辑参考宽度
    final oldScale = _scaleFactor;
    _viewportSize = size;
    _scaleFactor = size.width / baseWidth;

    // 为了保持视角不跳动，如果垂直缩放了，需要按比例调整 scrollOffset
    if (oldScale > 0 && oldScale != _scaleFactor) {
      _scrollOffset = (_scrollOffset / oldScale) * _scaleFactor;
    }
    
    _clampScroll();
    notifyListeners();
  }

  // --- 坐标转换逻辑 ---

  /// 屏幕坐标 -> 逻辑 Base 坐标
  /// 逻辑：(ScreenPoint + ScrollOffset) / Scale
  Offset toBasePoint(Offset screenPoint) {
    return Offset(
      screenPoint.dx / _scaleFactor,
      (screenPoint.dy + _scrollOffset) / _scaleFactor,
    );
  }

  // --- 操作逻辑 ---

  void handleScroll(double delta) {
    _scrollOffset += delta;
    _clampScroll();
    notifyListeners();
  }

  void _clampScroll() {
    if (_scaleFactor <= 0) return;
    
    if (_scrollOffset < 0) {
      _scrollOffset = 0;
      return;
    }

    // 总逻辑高度 = 50 页
    final totalLogicalHeight = pageCount * logicalPageHeight;
    // 转换为屏幕高度
    final totalScreenHeight = totalLogicalHeight * _scaleFactor;
    
    // 最大屏幕偏移 = 总高度 - 视口高度
    double maxScroll = totalScreenHeight - _viewportSize.height;
    
    // 稍微允许一点底部留白
    maxScroll += 20;

    if (maxScroll < 0) maxScroll = 0;
    if (_scrollOffset > maxScroll) _scrollOffset = maxScroll;
  }

  void startStroke(Offset point) {
    final basePoint = toBasePoint(point);

    if (_mode == BlackboardMode.pen) {
      _redoStack.clear();
      _currentStroke.clear();
      _currentStroke.add(basePoint);
    } else if (_mode == BlackboardMode.eraser) {
      _redoStack.clear();
      _pendingEraseActions.clear();
    } else if (_mode == BlackboardMode.selection) {
      // 检查点击位置是否有笔迹
      final hitIndex = _findStrokeAt(basePoint);
      if (hitIndex != -1) {
        // 如果点中了已选中的，则准备移动
        if (_selectedIndexes.contains(hitIndex)) {
          _isMovingSelection = true;
          _selectionDragStart = basePoint;
          _selectionCurrentDelta = Offset.zero;
        } else {
          // 点中了未选中的：
          // 这里可以根据是否按住 Shift 支持多选，目前默认为单选/切换
          _selectedIndexes.clear();
          _selectedIndexes.add(hitIndex);
          _isMovingSelection = true;
          _selectionDragStart = basePoint;
          _selectionCurrentDelta = Offset.zero;
        }
      } else {
        // 没点中任何东西，清空选择并准备开始框选
        _selectedIndexes.clear();
        _marqueeRect = Rect.fromPoints(basePoint, basePoint);
      }
    }
    _currentPointerPosition = point;
    notifyListeners();
  }

  void moveStroke(Offset point) {
    final basePoint = toBasePoint(point);

    if (_mode == BlackboardMode.pen) {
      _currentStroke.add(basePoint);
    } else if (_mode == BlackboardMode.eraser) {
      final eraserRect = Rect.fromCenter(
        center: basePoint,
        width: 26 / _scaleFactor,
        height: 40 / _scaleFactor,
      );
      
      for (int i = _historyStrokes.length - 1; i >= 0; i--) {
        final stroke = _historyStrokes[i];
        for (int j = 0; j < stroke.length - 1; j++) {
          if (_isSegmentIntersectsRect(stroke[j], stroke[j + 1], eraserRect) || 
              _distToSegment(basePoint, stroke[j], stroke[j + 1]) < (15 / _scaleFactor)) {
            
            final oldStroke = List<Offset>.from(stroke);
            final List<List<Offset>> newStrokes = [];

            _historyStrokes.removeAt(i);
            
            final firstPart = stroke.sublist(0, j + 1);
            final secondPart = stroke.sublist(j + 1);
            
            if (secondPart.isNotEmpty) {
              _historyStrokes.insert(i, secondPart);
              newStrokes.add(secondPart);
            }
            if (firstPart.isNotEmpty) {
              _historyStrokes.insert(i, firstPart);
              newStrokes.insert(0, firstPart);
            }

            _pendingEraseActions.add(EraseAction(
              index: i,
              oldStroke: oldStroke,
              newStrokes: newStrokes
            ));
            break; 
          }
        }
      }
    } else if (_mode == BlackboardMode.selection) {
      if (_isMovingSelection && _selectionDragStart != null) {
        _selectionCurrentDelta = basePoint - _selectionDragStart!;
      } else if (_marqueeRect != null) {
        _marqueeRect = Rect.fromPoints(_marqueeRect!.topLeft, basePoint);
      }
    }
    _currentPointerPosition = point;
    notifyListeners();
  }

  void endStroke() {
    if (_mode == BlackboardMode.pen) {
      if (_currentStroke.isNotEmpty) {
        final strokeData = List<Offset>.from(_currentStroke);
        final command = DrawCommand(strokeData);
        command.execute(_historyStrokes);
        _undoStack.add(command);
        _currentStroke.clear();
      }
    } else if (_mode == BlackboardMode.eraser) {
      if (_pendingEraseActions.isNotEmpty) {
        final command = EraseCommand(List.from(_pendingEraseActions));
        _undoStack.add(command);
        _pendingEraseActions.clear();
      }
    } else if (_mode == BlackboardMode.selection) {
      if (_isMovingSelection && _selectionCurrentDelta != null && _selectionCurrentDelta != Offset.zero) {
        // [TODO] 这里应该应用移动并创建 MoveCommand
        _applySelectionMove();
      } else if (_marqueeRect != null) {
        // 完成框选：计算哪些笔迹在矩形内
        _selectStrokesInRect(_marqueeRect!);
      }
      
      // 重置交互状态
      _isMovingSelection = false;
      _selectionDragStart = null;
      _selectionCurrentDelta = null;
      _marqueeRect = null;
    }
    _currentPointerPosition = null;
    notifyListeners();
  }

  void hoverStroke(Offset point) {
    _currentPointerPosition = point;
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final command = _undoStack.removeLast();
      command.undo(_historyStrokes);
      _redoStack.add(command);
      
      // 专业化细节：如果撤销后没笔迹了，切回画笔模式
      if (_historyStrokes.isEmpty && (_mode == BlackboardMode.eraser || _mode == BlackboardMode.selection)) {
        _mode = BlackboardMode.pen;
        _selectedIndexes.clear();
      }
      
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final command = _redoStack.removeLast();
      command.execute(_historyStrokes);
      _undoStack.add(command);
      notifyListeners();
    }
  }

  void clear() {
    if (_historyStrokes.isNotEmpty) {
      final command = ClearCommand(_historyStrokes);
      command.execute(_historyStrokes);
      _undoStack.add(command);
      _redoStack.clear();
      _pendingEraseActions.clear();
      
      // 专业化细节：清空后切回画笔
      _mode = BlackboardMode.pen;
      _selectedIndexes.clear();
      
      notifyListeners();
    }
  }

  // --- 页面跳转 ---

  void jumpToPage(int index) {
    if (_scaleFactor <= 0) return;
    // 跳转位置 = 逻辑页起始高度 * 缩放系数
    // 简化：逻辑页起始高度 = index * logicalPageHeight
    // 而 logicalPageHeight * scaleFactor 实际上就是 _viewportSize.height
    _scrollOffset = index * _viewportSize.height;
    _clampScroll();
    notifyListeners();
  }

  void jumpToHome() {
    jumpToPage(0);
  }

  void nextPage() {
    jumpToPage(currentPageIndex + 1);
  }

  void prevPage() {
    jumpToPage(currentPageIndex - 1);
  }

  void setMode(BlackboardMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      
      // 专业化增强：切换到非选择模式时，自动清空选中
      if (newMode != BlackboardMode.selection) {
        _selectedIndexes.clear();
      }
      
      notifyListeners();
    }
  }

  // --- 选择辅助方法 ---

  /// 在指定位置寻找笔迹索引
  int _findStrokeAt(Offset basePoint) {
    final threshold = 10.0; // 逻辑像素阈值
    // 从后往前搜，优先选中最后画的
    for (int i = _historyStrokes.length - 1; i >= 0; i--) {
      final stroke = _historyStrokes[i];
      for (int j = 0; j < stroke.length - 1; j++) {
        if (_distToSegment(basePoint, stroke[j], stroke[j + 1]) < threshold) {
          return i;
        }
      }
    }
    return -1;
  }

  /// 选中指定矩形框内的所有笔迹
  void _selectStrokesInRect(Rect rect) {
    _selectedIndexes.clear();
    for (int i = 0; i < _historyStrokes.length; i++) {
      final stroke = _historyStrokes[i];
      // 如果笔迹中任一点在矩形内，则认为选中（也可以改成全包含判定）
      final bool hit = stroke.any((p) => rect.contains(p));
      if (hit) {
        _selectedIndexes.add(i);
      }
    }
  }

  /// 应用移动并创建命令
  void _applySelectionMove() {
    if (_selectionCurrentDelta == null || _selectionCurrentDelta == Offset.zero) return;
    
    final delta = _selectionCurrentDelta!;
    final indices = Set<int>.from(_selectedIndexes);
    
    // 创建指令并执行（虽然实时预览已经画了，但 execute 才是真正持久化坐标）
    final command = MoveCommand(indices, delta);
    command.execute(_historyStrokes);
    
    _undoStack.add(command);
    _redoStack.clear();
  }

  /// 删除当前所有选中的笔迹
  void deleteSelected() {
    if (_selectedIndexes.isEmpty) return;

    final List<EraseAction> actions = [];
    // 必须从后往前删，以保持索引稳定（虽然 EraseCommand 内部会处理，但这里生成 actions 也要注意）
    final sortedIndices = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index < _historyStrokes.length) {
        actions.add(EraseAction(
          index: index,
          oldStroke: List.from(_historyStrokes[index]),
          newStrokes: [], // 空表示完全删除
        ));
        _historyStrokes.removeAt(index);
      }
    }

    if (actions.isNotEmpty) {
      _undoStack.add(EraseCommand(actions));
      _redoStack.clear();
    }
    
    _selectedIndexes.clear();
    notifyListeners();
  }

  // --- 内部数学方法 ---

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