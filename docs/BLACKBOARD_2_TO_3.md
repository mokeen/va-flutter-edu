# 画板从 2 → 3（对应总纲 TODO #3）

这份文档专注于实现 **橡皮擦** 与 **光标交互细节**。

总纲 TODO 在：`docs/VA_EDU_DEV_LOG.md`。

---

## 约定

- **Logi/UI 分离**：所有状态逻辑（如 hit test）必须在 `BlackboardController` 中完成。
- **模式互斥**：画笔与橡皮是互斥的，必须通过 `BlackboardMode` 严格管理。

## 范围（Scope）

- **工具栏 UI**：增加模式切换按钮（画笔/橡皮）。
- **橡皮擦逻辑**：基于路径切割的擦除算法。
- **光标反馈**：悬停、跟随、不同模式下的定制光标（画笔/方框）。

---

## Step TODO List

### [x] Step 1：模式支持 (UI & State)

- [x] 创建 `lib/src/features/blackboard/application/blackboard_mode.dart`，定义 `enum BlackboardMode`。
- [x] Controller 引入 `_mode` 变量及 `setMode` 方法。
- [x] Toolbar 增加橡皮擦按钮，实现选中态高亮（背景色变化）。
- **验收**：点击橡皮擦按钮，按钮背景变亮，模式切换成功。

### [x] Step 2：命中检测算法 (Math)

- [x] Controller 实现混合算法：
    - `_isSegmentIntersectsRect`: 检测线段是否穿过橡皮矩形。
    - `_distToSegment`: 检测触摸点到线段的垂直距离（阈值 15.0）。
- **验收**：无需 UI，通过单元测试或简单的日志验证算法准确性。

### [x] Step 3：实现擦除逻辑

- [x] 修改 `moveStroke` 逻辑：如果当前是 `eraser` 模式，不绘制，只检测碰撞。
- [x] 实现路径切割 (Path Splitting) 与混合命中检测：
    - 结合 **矩形相交** (`_isSegmentIntersectsRect`) 与 **点线距离** (`_distToSegment`)。
    - 命中后执行 `removeAt` -> `sublist` -> `insert` 的切割逻辑。
    - *(具体算法见下方“核心代码实现”章节)*

### [x] Step 4：优化与细节 (Visuals)

- [x] Controller 引入 `_currentPointerPosition`，统一管理鼠标/手指位置。
- [x] 实现 `hoverStroke`：支持鼠标悬停时更新位置。
- [x] Painter 绘制光标：
    - **橡皮模式**：绘制半透明圆角矩形。
    - **画笔模式**：绘制旋转 45 度的拟物化黄色铅笔。
- **验收**：鼠标悬停或移动时，光标跟随且样式正确；画笔笔尖对准落点。

### [ ] Step 5：进阶规划 (Command Pattern)

- [ ] 为了支持擦除的撤销，未来将重构为命令模式（见 `Undo/Redo` 专项规划）。
- **状态**：目前暂未实现（作为 TODO #3 的后续优化项）。

---

## 核心代码实现

### 1. 模式与光标管理 (Controller)

```dart
// lib/src/features/blackboard/application/blackboard_controller.dart

class BlackboardController extends ChangeNotifier {
  // 统一的光标位置（支持 Hover 和 Drag）
  Offset? _currentPointerPosition;
  BlackboardMode _mode = BlackboardMode.pen;

  // 鼠标悬停逻辑
  void hoverStroke(Offset point) {
    _currentPointerPosition = point;
    notifyListeners();
  }

  // 绘制/擦除逻辑分流
  void moveStroke(Offset point) {
    if (_mode == BlackboardMode.pen) {
      _currentStroke.add(point);
    } else if (_mode == BlackboardMode.eraser) {
      // 执行擦除算法...
    }
    _currentPointerPosition = point; // 无论什么模式，都更新光标
    notifyListeners();
  }
}
```

### 2. 擦除核心算法 (Controller Calculation)

这是橡皮擦功能的灵魂。通过混合检测算法找到目标，并运用 List 操作实现线条切割。

```dart
// lib/src/features/blackboard/application/blackboard_controller.dart

// 混和命中策略：矩形包围 OR 垂直距离 < 15
if (_isSegmentIntersectsRect(stroke[j], stroke[j + 1], eraserRect) || 
    _distToSegment(point, stroke[j], stroke[j + 1]) < 15) {
   
   // 命中！执行切割逻辑
   _historyStrokes.removeAt(i); // 1. 移除旧线
   
   final firstPart = stroke.sublist(0, j + 1); // 2. 切前半段
   final secondPart = stroke.sublist(j + 1);   // 3. 切后半段
   
   // 4. 将切断后的新线条插回历史
   if (secondPart.isNotEmpty) _historyStrokes.insert(i, secondPart);
   if (firstPart.isNotEmpty) _historyStrokes.insert(i, firstPart);
   break; 
}

// 辅助算法1：线段与矩形相交检测
bool _isSegmentIntersectsRect(Offset p1, Offset p2, Rect rect) {
  if (rect.contains(p1) || rect.contains(p2)) return true;
  final double minx = p1.dx < p2.dx ? p1.dx : p2.dx;
  final double maxx = p1.dx > p2.dx ? p1.dx : p2.dx;
  final double miny = p1.dy < p2.dy ? p1.dy : p2.dy;
  final double maxy = p1.dy > p2.dy ? p1.dy : p2.dy;
  return rect.left <= minx && maxx <= rect.right && rect.top <= miny && maxy <= rect.bottom; 
}

// 辅助算法2：点到线段最短距离 (向量投影法)
double _distToSegment(Offset p, Offset a, Offset b) {
  final double l2 = (b - a).distanceSquared;
  if (l2 == 0) return (p - a).distance;
  double t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
  t = t.clamp(0.0, 1.0);
  final Offset projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
  return (p - projection).distance;
}
```

### 3. 精致的光标绘制 (Painter)

使用 `save/restore` 隔离 Canvas 状态，实现局部旋转，绘制拟物化铅笔。

```dart
// lib/src/features/blackboard/presentation/widgets/blackboard_painter.dart

if (currentPointerPosition != null) {
  if (mode == BlackboardMode.pen) {
    canvas.save();
    // 1. 移动原点到鼠标位置
    canvas.translate(currentPointerPosition!.dx, currentPointerPosition!.dy);
    // 2. 旋转 45 度 (模拟右手握笔)
    canvas.rotate(45 * 0.0174533); 
    
    // 3. 在 (0,0) 处绘制笔尖...
    canvas.drawPath(tipPath, tipPaint);
    // ... 绘制笔身
    
    canvas.restore(); // 恢复状态，避免影响后续绘制
  }
}
```

### 4. 工具栏交互 (Toolbar)

```dart
// lib/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart

IconButton(
  style: IconButton.styleFrom(
    // 选中状态给一个微弱的白色半透明背景，未选中透明
    backgroundColor: mode == BlackboardMode.pen ? Colors.white10 : Colors.transparent,
  ),
  icon: const Icon(Icons.edit, color: Colors.white),
  onPressed: () => onModeChanged(BlackboardMode.pen),
)
```

## 学习总结

1.  **Canvas 状态隔离**: 当需要对某个元素进行旋转或平移时，务必使用 `save()` 和 `restore()` 包裹，否则会破坏整个画布的坐标系。
2.  **命中检测的平衡**: 单纯的矩形相交无法检测细线，单纯的距离检测无法模拟宽橡皮。混合算法（矩形范围检测 + 垂直距离检测）是最佳实践。
3.  **光标体验**: 区分 `PointerMove` (按下移动) 和 `PointerHover` (悬停移动) 并统一更新位置变量，能给桌面端用户带来极佳的预期体验。
