import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [Add]
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';
import 'dart:async'; // [Add]
import 'package:va_edu/src/features/blackboard/application/blackboard_command.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';
import 'package:va_edu/src/features/blackboard/data/blackboard_repository.dart';
import 'package:va_edu/src/features/settings/domain/settings_model.dart';

/// 管理画板状态与操作逻辑 (Plan C: 统一缩放投影画布)
class BlackboardController extends ChangeNotifier {
  // --- 核心常量 (ClassIn 风格) ---
  static const double baseWidth = 1000.0;       // 逻辑参考宽度
  static const int pageCount = 50;              // 默认固定 50 页

  // --- 状态变量 ---
  
  // 所有的历史笔迹 (统一存储在 Base 坐标系下)
  final List<Stroke> _historyStrokes = [];
  
  // [Laser] 专用笔迹列表 (不进历史，自动消失)
  final List<Stroke> _laserStrokes = [];
  Timer? _laserTimer;
  
  // 当前正在绘制的笔迹点集 (Base 坐标)
  final List<Offset> _currentStrokePoints = [];
  
  // 当前样式配置
  StrokeStyle _currentStyle = StrokeStyle.defaultStyle;
  StrokeType _currentStrokeType = StrokeType.freehand;
  
  // 是否打开配置面板
  bool _isConfigPanelOpen = false;

  // 全局撤销/重做栈
  final List<BlackboardCommand> _undoStack = [];
  final List<BlackboardCommand> _redoStack = [];

  // [Eraser] 擦除动作暂存
  final List<EraseAction> _pendingEraseActions = [];
  
  // 橡皮擦尺寸
  double _eraserSize = 30.0;

  BlackboardController({AppSettings? initialSettings}) {
    if (initialSettings != null) {
      _currentStyle = StrokeStyle(
        color: initialSettings.defaultPenColor,
        width: initialSettings.defaultPenWidth,
      );
    }
    // 默认加载
    loadLesson('default');
  }

  @override
  void dispose() {
    _laserTimer?.cancel();
    _autoSaveTimer?.cancel(); // [Add]
    super.dispose();
  }

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

  // [Scaling]
  bool _isScalingSelection = false;
  int? _scalingHandleIndex;
  Rect? _initialScalingRect;

  bool _isPageDrawerOpen = false; // [New] 分页抽屉状态

  final List<Offset> _snapLines = []; // [New] 存储吸附线点对 (每两个点一个线段)

  // --- 持久化相关 ---
  final BlackboardRepository _repository = BlackboardRepository();
  String _currentLessonName = 'default';
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  final bool _isLessonsLoading = false;

  // --- Getters ---

  double get aspectRatio => _viewportSize.height > 0 ? (_viewportSize.width / _viewportSize.height) : 16 / 9;

  double get logicalPageHeight => _scaleFactor > 0 ? (_viewportSize.height / _scaleFactor) : 0.0;

  List<Offset> get currentStrokePoints => List.unmodifiable(_currentStrokePoints);
  List<Stroke> get historyStrokes => List.unmodifiable(_historyStrokes);
  List<Stroke> get laserStrokes => List.unmodifiable(_laserStrokes); // [Add] Getter
  
  int get undoStackLength => _undoStack.length;
  int get redoStackLength => _redoStack.length;
  
  BlackboardMode get mode => _mode;
  Offset? get currentPointerPosition => _currentPointerPosition;
  double get scrollOffset => _scrollOffset;
  double get scaleFactor => _scaleFactor;
  String get currentLessonName => _currentLessonName;

  // 样式与配置 Getters
  StrokeStyle get currentStyle => _currentStyle;
  StrokeType get currentStrokeType => _currentStrokeType;
  bool get isConfigPanelOpen => _isConfigPanelOpen;
  bool get isPageDrawerOpen => _isPageDrawerOpen; // [New]
  double get eraserSize => _eraserSize;
  bool get isLessonsLoading => _isLessonsLoading;

  // 选择状态映射
  Set<int> get selectedIndexes => Set.unmodifiable(_selectedIndexes);
  Rect? get marqueeRect => _marqueeRect;
  Offset? get selectionCurrentDelta => _selectionCurrentDelta;
  List<Offset> get snapLines => List.unmodifiable(_snapLines); // [New]
  Rect? get selectionBounds => _getSelectionBounds(); // [New] Expose private method

  // 根据当前滚动位置计算所在页码 (1-indexed)
  int get currentPageIndex {
    final pageH = logicalPageHeight;
    if (pageH <= 0) return 0;
    final logicalScroll = _scrollOffset / _scaleFactor;
    final judgePoint = logicalScroll + (pageH * 0.3);
    final int index = (judgePoint / pageH).floor();
    return index.clamp(0, pageCount - 1);
  }

  int get totalPageCount => pageCount;
  String get currentPageId => (currentPageIndex + 1).toString();

  /// 获取指定页码的所有笔迹 (逻辑坐标相对于该页顶部)
  List<Stroke> getStrokesForPage(int index) {
    final pageH = logicalPageHeight;
    if (pageH <= 0) return [];
    
    final startY = index * pageH;
    final endY = (index + 1) * pageH;
    
    return _historyStrokes.where((stroke) {
      if (stroke.points.isEmpty) return false;
      // 只要有一个点在页面范围内，就认为属于该页 (简化算法)
      final y = stroke.points.first.dy;
      return y >= startY && y < endY;
    }).map((stroke) {
      // 转换为相对于页面顶部的坐标
      return stroke.copyWith(
        points: stroke.points.map((p) => Offset(p.dx, p.dy - startY)).toList(),
      );
    }).toList();
  }

  // --- Setter &  // --- 对外提供的操作方法 ---
  
  void setStyle(StrokeStyle style) {
    _currentStyle = style;
    notifyListeners();
  }

  void setStrokeType(StrokeType type) {
    _currentStrokeType = type;
    notifyListeners();
  }
  
  void setEraserSize(double size) {
    _eraserSize = size;
    // 橡皮尺寸变化不需要重绘历史，只需要重绘光标
    notifyListeners();
  }
  
  void toggleConfigPanel() {
    _isConfigPanelOpen = !_isConfigPanelOpen;
    if (_isConfigPanelOpen) {
      _isPageDrawerOpen = false; // 互斥
    }
    notifyListeners();
  }

  void togglePageDrawer() {
    _isPageDrawerOpen = !_isPageDrawerOpen;
    if (_isPageDrawerOpen) {
      _isConfigPanelOpen = false; // 互斥
    }
    notifyListeners();
  }

  void closeConfigPanel() {
    _isConfigPanelOpen = false;
    _isPageDrawerOpen = false;
    notifyListeners();
  }

  void addText(Offset position, String text) {
    if (text.isEmpty) return;
    
    // 创建文本笔迹
    // 文本的位置通常作为 points 的第一个点存储
    final textStroke = Stroke(
      points: [position],
      style: _currentStyle,
      type: StrokeType.text,
      text: text,
    );
    
    // 执行添加命令
    final command = DrawCommand(textStroke);
    command.execute(_historyStrokes);
    
    _undoStack.add(command);
    _redoStack.clear();
    _triggerAutoSave();
    notifyListeners();
  }

  void updateText(int index, String newText) {
    if (index < 0 || index >= _historyStrokes.length) return;
    if (_historyStrokes[index].type != StrokeType.text) return;
    if (_historyStrokes[index].text == newText) return;

    final oldStroke = _historyStrokes[index];
    final newStroke = oldStroke.copyWith(text: newText);
    
    // 需新增 Command 类型或复用现有逻辑
    // 实现 UpdateTextCommand 以符合当前架构
    // 这里先简单直接修改并加入撤销栈
    final command = UpdateCommand(index, oldStroke, newStroke);
    command.execute(_historyStrokes);
    
    _undoStack.add(command);
    _redoStack.clear();
    _triggerAutoSave();
    notifyListeners();
  }

  // --- 生命周期 ---

  void updateViewport(Size size) {
    if (_viewportSize == size) return;
    
    final oldScale = _scaleFactor;
    _viewportSize = size;
    _scaleFactor = size.width / baseWidth;

    if (oldScale > 0 && oldScale != _scaleFactor) {
      _scrollOffset = (_scrollOffset / oldScale) * _scaleFactor;
    }
    
    _clampScroll();
    notifyListeners();
  }

  // --- 坐标转换逻辑 ---

  Offset toBasePoint(Offset screenPoint) {
    return Offset(
      screenPoint.dx / _scaleFactor,
      (screenPoint.dy + _scrollOffset) / _scaleFactor,
    );
  }

  Offset toScreenPoint(Offset basePoint) {
    return Offset(
      basePoint.dx * _scaleFactor,
      (basePoint.dy * _scaleFactor) - _scrollOffset,
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

    final totalLogicalHeight = pageCount * logicalPageHeight;
    final totalScreenHeight = totalLogicalHeight * _scaleFactor;
    double maxScroll = totalScreenHeight - _viewportSize.height;
    maxScroll += 20;

    if (maxScroll < 0) maxScroll = 0;
    if (_scrollOffset > maxScroll) _scrollOffset = maxScroll;
  }

  void startStroke(Offset point) {
    closeConfigPanel(); // 开始绘制时自动关闭面板
    final basePoint = toBasePoint(point);

    if (_mode == BlackboardMode.pen || _mode == BlackboardMode.laser) {
      _redoStack.clear();
      _currentStrokePoints.clear();
      _currentStrokePoints.add(basePoint);
      // 对于几何图形，虽然只要两点，但起点也是必要的
    } else if (_mode == BlackboardMode.eraser) {
      _redoStack.clear();
      _pendingEraseActions.clear();
    } else if (_mode == BlackboardMode.selection) {
      final handleIndex = _hitTestHandle(basePoint, 15.0);
      if (handleIndex != -1) {
        _isScalingSelection = true;
        _scalingHandleIndex = handleIndex;
        _initialScalingRect = _getSelectionBounds();
        _selectionDragStart = basePoint;
      } else {
        final hitIndex = findStrokeAt(basePoint);
        if (hitIndex != -1) {
          if (_selectedIndexes.contains(hitIndex)) {
            _isMovingSelection = true;
            _selectionDragStart = basePoint;
            _selectionCurrentDelta = Offset.zero;
          } else {
            _selectedIndexes.clear();
            _selectedIndexes.add(hitIndex);
            _expandSelectionToGroups();
            _isMovingSelection = true;
            _selectionDragStart = basePoint;
            _selectionCurrentDelta = Offset.zero;
          }
        } else {
          _selectedIndexes.clear();
          _marqueeRect = Rect.fromPoints(basePoint, basePoint);
        }
      }
    }
    _currentPointerPosition = point;
    notifyListeners();
  }

  void moveStroke(Offset point) {
    final basePoint = toBasePoint(point);

    if (_mode == BlackboardMode.pen || _mode == BlackboardMode.laser) {
      if (_mode == BlackboardMode.laser || _currentStrokeType == StrokeType.freehand) {
        _currentStrokePoints.add(basePoint);
      } else {
        // 几何图形：始终只保留 [起点, 当前点]
        if (_currentStrokePoints.length > 1) {
          _currentStrokePoints.removeLast();
        }
        _currentStrokePoints.add(basePoint);
      }
    } else if (_mode == BlackboardMode.eraser) {
      _handleEraserMove(basePoint);
    } else if (_mode == BlackboardMode.selection) {
      if (_isScalingSelection) {
        _handleScalingMove(basePoint);
      } else if (_isMovingSelection && _selectionDragStart != null) {
        _handleMovingMove(basePoint);
      } else if (_marqueeRect != null) {
        _marqueeRect = Rect.fromPoints(_marqueeRect!.topLeft, basePoint);
      }
    }
    _currentPointerPosition = point;
    notifyListeners();
  }

  void endStroke() {
    _currentPointerPosition = null;

    if (_isMovingSelection) {
      _applySelectionMove();
      _isMovingSelection = false;
      _selectionDragStart = null;
      _selectionCurrentDelta = null;
      _snapLines.clear();
      _triggerAutoSave();
    } else if (_isScalingSelection) {
       _applySelectionScale();
       _isScalingSelection = false;
       _scalingHandleIndex = null;
       _initialScalingRect = null;
       _triggerAutoSave();
    } else if (_mode == BlackboardMode.eraser) {
       _applyEraseActions();
       _triggerAutoSave();
    } else if (_mode == BlackboardMode.pen) {
      if (_currentStrokePoints.isEmpty) return;
      
      if (_currentStrokeType != StrokeType.freehand && _currentStrokePoints.length < 2) {
           _currentStrokePoints.clear();
           notifyListeners();
           return;
      }

      final stroke = Stroke(
        points: List<Offset>.from(_currentStrokePoints),
        style: _currentStyle,
        type: _currentStrokeType,
      );
      
      final command = DrawCommand(stroke);
      command.execute(_historyStrokes);
      
      _undoStack.add(command);
      _redoStack.clear();
      _currentStrokePoints.clear();
      _triggerAutoSave();
    } else if (_mode == BlackboardMode.laser) {
       if (_currentStrokePoints.isNotEmpty) {
          final stroke = Stroke(
            points: List.from(_currentStrokePoints),
            style: _currentStyle.copyWith(
              color: 0xFFFF5555,
              width: 4.0,
            ),
            type: StrokeType.freehand,
            createdAt: DateTime.now(),
          );
          _laserStrokes.add(stroke);
          _currentStrokePoints.clear();
          _startLaserFading();
       }
    } else if (_mode == BlackboardMode.selection) {
      if (_marqueeRect != null) {
        _selectStrokesInRect(_marqueeRect!);
        _marqueeRect = null;
      }
    }
    
    notifyListeners();
  }

  // 抽离橡皮擦逻辑
  void _handleEraserMove(Offset basePoint) {
      final eraserRect = Rect.fromCenter(
        center: basePoint,
        width: _eraserSize / _scaleFactor,
        height: (_eraserSize * 1.5) / _scaleFactor, // 保持 2:3 比例或根据 UI 调整
      );
      
      for (int i = _historyStrokes.length - 1; i >= 0; i--) {
        final stroke = _historyStrokes[i];
        
        // 策略分流：自由线用切割算法，几何图形用整体删除算法
        if (stroke.type == StrokeType.freehand) {
           _eraseFreehand(i, stroke, eraserRect, basePoint);
        } else {
           _eraseShape(i, stroke, eraserRect);
        }
      }
  }

  void _eraseFreehand(int index, Stroke stroke, Rect eraserRect, Offset eraserPoint) {
    final points = stroke.points;
    final List<Stroke> newStrokes = [];
    final List<Offset> currentPoints = [];
    bool hasChange = false;

    // 遍历所有点，保留在橡皮擦之外的点
    for (int j = 0; j < points.length; j++) {
      final p = points[j];
      
      // 判断点是否在橡皮擦内 (使用稍大的阈值或直接判断矩形)
      // 简单判断: 点在矩形内
       final bool isInside = eraserRect.contains(p);
       
       // 为了更好的手感，增加线段相交检测
       if (!isInside && currentPoints.isNotEmpty) {
         final prev = currentPoints.last;
         if (_isSegmentIntersectsRect(prev, p, eraserRect)) {
           // 线段穿过橡皮擦 -> 视为被擦除
           // 结束当前段
           newStrokes.add(stroke.copyWith(points: List.from(currentPoints)));
           currentPoints.clear();
           
           // 当前点 p 虽然在外，但因为线段断了，作为新一段的起点
           currentPoints.add(p);
           hasChange = true;
           continue;
         }
       }

      if (isInside) {
        hasChange = true;
        if (currentPoints.isNotEmpty) {
          // 结束当前段
          newStrokes.add(stroke.copyWith(points: List.from(currentPoints)));
          currentPoints.clear();
        }
      } else {
        currentPoints.add(p);
      }
    }

    // 添加最后一段
    if (currentPoints.isNotEmpty) {
       // 如果完全没有变化（所有点都保留了），其实不需要任何操作
       // 但为了逻辑统一，如果 hasChange 为 true 才处理
       if (hasChange) {
         newStrokes.add(stroke.copyWith(points: List.from(currentPoints)));
       }
    }

    if (hasChange) {
      _historyStrokes.removeAt(index);
      
      // 过滤掉太短的噪点（可选，但有助于减少碎片）
      final validNewStrokes = newStrokes.where((s) => s.points.isNotEmpty).toList();
      
      // 倒序插入以保持顺序（如果在这里插入，index会变？removeAt已经移除了）
      // 原 index 处插入，需保证顺序正确。 newStrokes 是从前到后的顺序。
      // 所以应该从后往前 insert 到 index，或者使用 insertAll
      
      _historyStrokes.insertAll(index, validNewStrokes);

      _pendingEraseActions.add(EraseAction(
        index: index,
        oldStroke: stroke,
        newStrokes: validNewStrokes
      ));
    }
  }
  void _eraseShape(int index, Stroke stroke, Rect eraserRect) {
     // 几何图形的整体删除判定
     // 简易逻辑：如果橡皮擦矩形与图形的包围盒相交，则删除
     // 进阶逻辑：应该判断图形的具体涵盖范围
     
     Rect shapeBounds;
     if (stroke.type == StrokeType.rect || stroke.type == StrokeType.circle || stroke.type == StrokeType.line) {
        if (stroke.points.length < 2) return;
        shapeBounds = Rect.fromPoints(stroke.points.first, stroke.points.last);
     } else {
       return;
     }
     
     if (eraserRect.overlaps(shapeBounds)) {        
        _historyStrokes.removeAt(index);
        
        _pendingEraseActions.add(EraseAction(
          index: index,
          oldStroke: stroke,
          newStrokes: [] // 空列表代表完全删除
        ));
     }
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
      
      _mode = BlackboardMode.pen;
      _selectedIndexes.clear();
      notifyListeners();
    }
  }

  // --- 页面跳转 ---

  // --- [Z-Order] 层级控制 ---

  void bringToFront() {
    if (_selectedIndexes.isEmpty) return;
    
    final oldHistory = List<Stroke>.from(_historyStrokes);
    final List<Stroke> selectedStrokes = [];
    final List<int> sortedIndices = _selectedIndexes.toList()..sort();
    
    // 从后向前移除，保证索引有效
    for (int i = sortedIndices.length - 1; i >= 0; i--) {
      selectedStrokes.add(_historyStrokes.removeAt(sortedIndices[i]));
    }
    
    // 把选中的插回顶部 (列表末尾)
    _historyStrokes.addAll(selectedStrokes.reversed);
    
    // 更新选中索引
    _selectedIndexes.clear();
    for (int i = 0; i < selectedStrokes.length; i++) {
      _selectedIndexes.add(_historyStrokes.length - 1 - i);
    }
    
    _undoStack.add(ReorderCommand(oldHistory, _historyStrokes));
    _redoStack.clear();
    notifyListeners();
  }

  void sendToBack() {
    if (_selectedIndexes.isEmpty) return;
    
    final oldHistory = List<Stroke>.from(_historyStrokes);
    final List<Stroke> selectedStrokes = [];
    final List<int> sortedIndices = _selectedIndexes.toList()..sort();
    
    for (int i = sortedIndices.length - 1; i >= 0; i--) {
      selectedStrokes.add(_historyStrokes.removeAt(sortedIndices[i]));
    }
    
    // 把选中的插回底部 (列表头部)
    for (final s in selectedStrokes) {
      _historyStrokes.insert(0, s);
    }
    
    _selectedIndexes.clear();
    for (int i = 0; i < selectedStrokes.length; i++) {
      _selectedIndexes.add(i);
    }
    
    _undoStack.add(ReorderCommand(oldHistory, _historyStrokes));
    _redoStack.clear();
    notifyListeners();
  }

  void bringForward() {
    if (_selectedIndexes.isEmpty) return;
    final oldHistory = List<Stroke>.from(_historyStrokes);
    final List<int> sortedIndices = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a)); // 降序
    
    bool changed = false;
    for (final index in sortedIndices) {
      if (index < _historyStrokes.length - 1) {
        // 如果上方不是选中的，则交换
        if (!_selectedIndexes.contains(index + 1)) {
          final temp = _historyStrokes[index];
          _historyStrokes[index] = _historyStrokes[index + 1];
          _historyStrokes[index + 1] = temp;
          
          _selectedIndexes.remove(index);
          _selectedIndexes.add(index + 1);
          changed = true;
        }
      }
    }
    
    if (changed) {
      _undoStack.add(ReorderCommand(oldHistory, _historyStrokes));
      _redoStack.clear();
      notifyListeners();
    }
  }

  void sendBackward() {
    if (_selectedIndexes.isEmpty) return;
    final oldHistory = List<Stroke>.from(_historyStrokes);
    final List<int> sortedIndices = _selectedIndexes.toList()..sort(); // 升序
    
    bool changed = false;
    for (final index in sortedIndices) {
      if (index > 0) {
        // 如果下方不是选中的，则交换
        if (!_selectedIndexes.contains(index - 1)) {
          final temp = _historyStrokes[index];
          _historyStrokes[index] = _historyStrokes[index - 1];
          _historyStrokes[index - 1] = temp;
          
          _selectedIndexes.remove(index);
          _selectedIndexes.add(index - 1);
          changed = true;
        }
      }
    }
    
    if (changed) {
      _undoStack.add(ReorderCommand(oldHistory, _historyStrokes));
      _redoStack.clear();
      notifyListeners();
    }
  }

  void jumpToPage(int index) {
    if (_scaleFactor <= 0) return;
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
      // 切换模式关闭面板
      closeConfigPanel();
      
      if (newMode != BlackboardMode.selection) {
        _selectedIndexes.clear();
      }

      // [Text] 切换到文本模式时，如果字号过小，自动设置为默认大小 (18.0)
      if (newMode == BlackboardMode.text) {
        if (_currentStyle.width < 12.0) {
          _currentStyle = _currentStyle.copyWith(width: 18.0);
        }
      }
      notifyListeners();
    }
  }

  // --- 选择辅助方法 ---

  int findStrokeAt(Offset basePoint) {
    final threshold = 10.0;
    for (int i = _historyStrokes.length - 1; i >= 0; i--) {
      final stroke = _historyStrokes[i];
      
      // 分类型命中检测
      if (stroke.type == StrokeType.freehand) {
        for (int j = 0; j < stroke.points.length - 1; j++) {
          if (_distToSegment(basePoint, stroke.points[j], stroke.points[j + 1]) < threshold) {
            return i;
          }
        }
      } else {
        // 几何图形与文本：检测是否在包围盒内
        final bounds = stroke.getBounds();
        if (bounds.inflate(threshold).contains(basePoint)) {
          return i;
        }
      }
    }
    return -1;
  }

  // --- [Grouping] 对象组合 ---

  void groupSelected() {
    if (_selectedIndexes.length < 2) return;
    
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    final oldHistory = List<Stroke>.from(_historyStrokes);
    
    for (final index in _selectedIndexes) {
      _historyStrokes[index] = _historyStrokes[index].copyWith(groupId: groupId);
    }
    
    _undoStack.add(ReorderCommand(oldHistory, _historyStrokes)); // 复用 ReorderCommand
    _redoStack.clear();
    notifyListeners();
  }

  void ungroupSelected() {
    if (_selectedIndexes.isEmpty) return;
    
    final oldHistory = List<Stroke>.from(_historyStrokes);
    bool changed = false;
    
    for (final index in _selectedIndexes) {
      if (_historyStrokes[index].groupId != null) {
        _historyStrokes[index] = _historyStrokes[index].copyWith(groupId: null);
        changed = true;
      }
    }
    
    if (changed) {
      _undoStack.add(ReorderCommand(oldHistory, _historyStrokes));
      _redoStack.clear();
      notifyListeners();
    }
  }

  void _selectStrokesInRect(Rect rect) {
    _selectedIndexes.clear();
    for (int i = 0; i < _historyStrokes.length; i++) {
      if (rect.overlaps(_historyStrokes[i].getBounds())) {
        _selectedIndexes.add(i);
      }
    }
    _expandSelectionToGroups();
    notifyListeners();
  }

  void _expandSelectionToGroups() {
    if (_selectedIndexes.isEmpty) return;
    
    final Set<String> groupIds = {};
    for (final index in _selectedIndexes) {
      final gid = _historyStrokes[index].groupId;
      if (gid != null) groupIds.add(gid);
    }
    
    if (groupIds.isEmpty) return;
    
    for (int i = 0; i < _historyStrokes.length; i++) {
      final gid = _historyStrokes[i].groupId;
      if (gid != null && groupIds.contains(gid)) {
        _selectedIndexes.add(i);
      }
    }
  }

  // --- [Selection Move & Snap] 移动与吸附 ---

  void _handleMovingMove(Offset currentBasePoint) {
    if (_selectionDragStart == null) return;
    
    final rawDelta = currentBasePoint - _selectionDragStart!;
    final selBounds = _getSelectionBounds();
    if (selBounds == null) {
      _selectionCurrentDelta = rawDelta;
      return;
    }

    // 移动后的预计矩形
    final currentRect = selBounds.shift(rawDelta);
    _snapLines.clear();
    
    double snapX = rawDelta.dx;
    double snapY = rawDelta.dy;
    
    final threshold = 5.0;
    
    // 获取当前页面的其他笔迹
    final cpIndex = currentPageIndex;
    final pageStrokes = _historyStrokes.asMap().entries
        .where((e) => !_selectedIndexes.contains(e.key)) // 排除自身
        .map((e) => e.value)
        .where((s) {
          // 简单的页面冲突检测
          final pBounds = s.getBounds();
          final pageStart = cpIndex * logicalPageHeight;
          return pBounds.top >= pageStart && pBounds.bottom <= (cpIndex + 1) * logicalPageHeight;
        }).toList();

    for (final other in pageStrokes) {
      final otherBounds = other.getBounds();
      
      // X 轴吸附 (左、中、右)
      final List<double> myX = [currentRect.left, currentRect.center.dx, currentRect.right];
      final List<double> otherX = [otherBounds.left, otherBounds.center.dx, otherBounds.right];
      
      for (var mx in myX) {
        for (var ox in otherX) {
          if ((mx - ox).abs() < threshold) {
            snapX -= (mx - ox);
            // 记录吸附线 (垂直线)
            _snapLines.add(Offset(ox, otherBounds.top - 20));
            _snapLines.add(Offset(ox, otherBounds.bottom + 20));
          }
        }
      }
      
      // Y 轴吸附 (顶、中、底)
      final List<double> myY = [currentRect.top, currentRect.center.dy, currentRect.bottom];
      final List<double> otherY = [otherBounds.top, otherBounds.center.dy, otherBounds.bottom];
      
      for (var my in myY) {
        for (var oy in otherY) {
          if ((my - oy).abs() < threshold) {
            snapY -= (my - oy);
            // 记录吸附线 (水平线)
            _snapLines.add(Offset(otherBounds.left - 20, oy));
            _snapLines.add(Offset(otherBounds.right + 20, oy));
          }
        }
      }
    }
    
    _selectionCurrentDelta = Offset(snapX, snapY);
  }

  void _applySelectionMove() {
     if (_selectionCurrentDelta == null || _selectionCurrentDelta == Offset.zero) return;
    
    final delta = _selectionCurrentDelta!;
    final indices = Set<int>.from(_selectedIndexes);
    // MoveCommand 现在会修改 Stroke.points (in-place)
    final command = MoveCommand(indices, delta);
    command.execute(_historyStrokes); // 这会立即修改数据
    
    _undoStack.add(command);
    _redoStack.clear();
  }

  void deleteSelected() {
    if (_selectedIndexes.isEmpty) return;

    final List<EraseAction> actions = [];
    final sortedIndices = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index < _historyStrokes.length) {
        actions.add(EraseAction(
          index: index,
          oldStroke: _historyStrokes[index].copyWith(points: List.from(_historyStrokes[index].points)), 
          newStrokes: [], 
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

  /// [Duplicate] 复制选中的笔迹
  void duplicateSelected() {
    if (_selectedIndexes.isEmpty) return;
    
    final List<Stroke> newStrokes = [];
    const offset = Offset(30, 30); // 偏移量，方便用户看到复制出了新对象
    
    final int insertionIndex = _historyStrokes.length;
    
    // 对每个选中索引进行克隆
    for (final index in _selectedIndexes) {
      if (index >= 0 && index < _historyStrokes.length) {
        final original = _historyStrokes[index];
        final cloned = original.copyWith(
          points: original.points.map((p) => p + offset).toList(),
        );
        newStrokes.add(cloned);
      }
    }
    
    if (newStrokes.isNotEmpty) {
      final command = DuplicateCommand(newStrokes, insertionIndex);
      command.execute(_historyStrokes);
      
      _undoStack.add(command);
      _redoStack.clear();
      
      // 自动选中新生成的笔迹
      _selectedIndexes.clear();
      for (int i = 0; i < newStrokes.length; i++) {
        _selectedIndexes.add(insertionIndex + i);
      }
      notifyListeners();
    }
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
    if (l2 == 0.0) return (p - a).distance;
    final double t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    if (t < 0.0) return (p - a).distance;
    if (t > 1.0) return (p - b).distance;
    final Offset projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - projection).distance;
  }

  // --- [Laser] 自动淡出逻辑 ---

  void _startLaserFading() {
    if (_laserTimer != null) return;
    _laserTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final now = DateTime.now();
      bool changed = false;
      
      _laserStrokes.removeWhere((stroke) {
        if (stroke.createdAt == null) return false;
        final duration = now.difference(stroke.createdAt!);
        if (duration.inMilliseconds > 3500) { // 3.5秒后完全移除
          changed = true;
          return true;
        }
        return false;
      });
      
      if (_laserStrokes.isEmpty) {
        timer.cancel();
        _laserTimer = null;
      }
      
      if (changed || _laserStrokes.isNotEmpty) {
        notifyListeners();
      }
    });
  }

  // --- [Scaling] 缩放核心逻辑 ---

  Rect? _getSelectionBounds() {
    if (_selectedIndexes.isEmpty) return null;
    Rect? collective;
    for (final index in _selectedIndexes) {
      if (index >= 0 && index < _historyStrokes.length) {
        final bounds = _historyStrokes[index].getBounds();
        collective = collective == null ? bounds : collective.expandToInclude(bounds);
      }
    }
    return collective;
  }

  int _hitTestHandle(Offset basePoint, double threshold) {
    final bounds = _getSelectionBounds();
    if (bounds == null) return -1;
    
    final handleRect = bounds.inflate(4.0);
    final handles = [
      handleRect.topLeft,
      handleRect.topRight,
      handleRect.bottomLeft,
      handleRect.bottomRight,
    ];
    
    for (int i = 0; i < handles.length; i++) {
        if ((handles[i] - basePoint).distance < threshold) return i;
    }
    return -1;
  }

  void _handleScalingMove(Offset currentBasePoint) {
    if (_initialScalingRect == null || _scalingHandleIndex == null) return;
    
    final oldRect = _initialScalingRect!;
    final handleIdx = _scalingHandleIndex!;
    
    // 确定固定点 (对角线)
    Offset anchor;
    switch (handleIdx) {
      case 0: anchor = oldRect.bottomRight; break; // 拖动 TL，anchor 是 BR
      case 1: anchor = oldRect.bottomLeft; break;  // 拖动 TR，anchor 是 BL
      case 2: anchor = oldRect.topRight; break;    // 拖动 BL，anchor 是 TR
      case 3: anchor = oldRect.topLeft; break;     // 拖动 BR，anchor 是 TL
      default: return;
    }
    
    // 计算缩放比例 (相对于 anchor)
    double scaleX = 1.0;
    double scaleY = 1.0;
    
    final oldW = oldRect.width;
    final oldH = oldRect.height;
    if (oldW == 0 || oldH == 0) return;
    
    final currentW = (currentBasePoint.dx - anchor.dx).abs();
    final currentH = (currentBasePoint.dy - anchor.dy).abs();
    
    scaleX = currentW / oldW;
    scaleY = currentH / oldH;
    
    // Proportional scaling (Shift key)
    if (HardwareKeyboard.instance.isShiftPressed) {
      final double maxScale = scaleX > scaleY ? scaleX : scaleY;
      scaleX = maxScale;
      scaleY = maxScale;
    }
    
    // 限制最小缩放，防止变成负数或无限小
    if (scaleX < 0.05) scaleX = 0.05;
    if (scaleY < 0.05) scaleY = 0.05;

    // 对所有选中笔迹应用缩放变换
    // 注意：实时更新需从 "_initialState" 开始，以避免累积误差
    // 简化处理：直接更新 _historyStrokes (在大规模连续缩放时可能产生微小误差)
    // 更好的做法是存储初始点集。
    
    for (final index in _selectedIndexes) {
      if (index >= 0 && index < _historyStrokes.length) {
        final stroke = _historyStrokes[index];
        final newPoints = stroke.points.map((p) {
          final dx = (p.dx - anchor.dx) * scaleX;
          final dy = (p.dy - anchor.dy) * scaleY;
          // 计算新坐标。避免基于上一帧计算产生的偏移累积。
          // 采用快照机制确保计算精度。
          // 暂时简化处理：在 moveStroke 中计算临时转换，而非直接修改 history。
          // 但目前没有临时 transform 逻辑。
          return Offset(anchor.dx + dx, anchor.dy + dy);
        }).toList();
        
        // 如果是文本，不仅缩放位置，也可以缩放字号
        double newWidth = stroke.style.width;
        if (stroke.type == StrokeType.text) {
           newWidth = stroke.style.width * ((scaleX + scaleY) / 2);
        }
        
        _historyStrokes[index] = stroke.copyWith(
          points: newPoints,
          style: stroke.style.copyWith(width: newWidth),
        );
      }
    }
    
    // 更新参考矩形，用于下一帧比例计算
    // 等等，如果是增量修改，比例应该是 current/prev。
    // 重新写比例逻辑为 current/prev
    _getSelectionBounds(); // 更新一下以反映最新状态
    _initialScalingRect = _getSelectionBounds();
  }

  // --- 持久化逻辑 ---

  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      saveLesson(_currentLessonName);
    });
  }

  Future<void> saveLesson(String name) async {
    if (_isSaving) return;
    _isSaving = true;
    
    try {
      // 将 history 分解到 pages
      final List<List<Stroke>> pages = List.generate(pageCount, (_) => []);
      for (final stroke in _historyStrokes) {
        final minY = stroke.getBounds().top;
        final pageIdx = (minY / logicalPageHeight).floor().clamp(0, pageCount - 1);
        pages[pageIdx].add(stroke);
      }

      final data = BlackboardData(
        pages: pages,
        lastModified: DateTime.now(),
      );
      
      await _repository.save(name, data);
      _currentLessonName = name;
    } finally {
      _isSaving = false;
    }
  }

  Future<void> loadLesson(String name) async {
    final data = await _repository.load(name);
    if (data != null) {
      _historyStrokes.clear();
      for (final page in data.pages) {
        _historyStrokes.addAll(page);
      }
      _undoStack.clear();
      _redoStack.clear();
      _currentLessonName = name;
      notifyListeners();
    }
  }

  void newLesson(String name) {
    _historyStrokes.clear();
    _undoStack.clear();
    _redoStack.clear();
    _selectedIndexes.clear();
    _currentLessonName = name;
    saveLesson(name);
    notifyListeners();
  }

  // --- 辅助方法 ---
  
  void _applyEraseActions() {
    if (_pendingEraseActions.isNotEmpty) {
      final command = EraseCommand(List.from(_pendingEraseActions));
      _undoStack.add(command);
      _redoStack.clear();
      _pendingEraseActions.clear();
    }
  }

  void _applySelectionScale() {
     // 缩放逻辑已经在 _handleScalingMove 中直接修改了 history
     // 这里可以记录一个 Command 用于记录变换前的状态，以便撤销
     // 暂时简单记录一个状态快照或标记已改变
     _redoStack.clear();
  }
}