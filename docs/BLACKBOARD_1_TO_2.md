# 画板从 1 → 2（对应总纲 TODO #2）

这份文档专注于实现 **工具栏** 与 **撤销/重做/清空** 功能。

总纲 TODO 在：`docs/VA_EDU_DEV_LOG.md`。

---

## 约定

- **Logi/UI 分离**：本阶段将引入 `BlackboardController`，将状态逻辑从 UI 中剥离。
- **小步提交**：每完成一个 Step 验证无误后再进行下一步。

## 范围（Scope）

- **工具栏 UI**：一个悬浮的按钮容器。
- **架构重构**：引入 `ChangeNotifier` 管理画板状态。
- **核心功能**：撤销 (Undo)、重做 (Redo)、清空 (Clear)。

---

## Step TODO List

### [x] Step 1：工具栏 UI (Toolbar Widget)

- [x] 创建 `lib/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart`
- [x] 实现一个简单的 `Row` 或 `Column`，包含三个 `IconButton`（撤销、重做、清空）
- [x] 在 `BlackboardScreen` 中使用 `Stack` 将 Toolbar 放置在画布上方
- **验收**：能看到按钮，点击控制台打印日志。

### [x] Step 2：引入 Controller (架构重构)

- [x] 创建 `lib/src/features/blackboard/application/blackboard_controller.dart`
- [x] 定义 `BlackboardController extends ChangeNotifier`
- [x] 将 `currentStroke` 和 `historyStrokes` 移入 Controller
- [x] `BlackboardScreen` 使用 `ListenableBuilder` (或 AnimatedBuilder) 监听 Controller
- **验收**：重构后应用行为与之前完全一致（能画线、能多笔画）。

### [x] Step 3：实现撤销 (Undo)

- [x] Controller 新增 `undo()` 方法
    - 逻辑：`historyStrokes.removeLast()` -> `redoStack.add()`
- [x] 按钮绑定 `controller.undo()`
- **验收**：绘制后点击撤销，笔迹消失；Undo 栈空时按钮应禁用（可选）。

### [x] Step 4：实现重做 (Redo)

- [x] Controller 新增 `redo()` 方法
    - 逻辑：`redoStack.removeLast()` -> `historyStrokes.add()`
- [x] 关键逻辑：**当发生新绘制时，必须清空 redoStack**
- **验收**：撤销后点击重做，笔迹恢复；撤销后画新线，重做失效。

### [x] Step 5：实现清空 (Clear)

- [x] Controller 新增 `clear()` 方法
    - 逻辑：清空 history 和 redo
- **验收**：点击清空，画布变白。

---

## 核心代码实现

### 1. 状态管理 (Controller)

`BlackboardController` 负责管理核心状态：当前笔迹、历史堆栈、撤销堆栈。

```dart
// lib/src/features/blackboard/application/blackboard_controller.dart

class BlackboardController extends ChangeNotifier {
  // ... 状态变量 ...
  final List<List<Offset>> _historyStrokes = [];
  final List<List<Offset>> _redoStrokes = [];

  void startStroke(Offset point) {
    // [Key Logic] 开始新笔画时，清空 Redo 堆栈，避免时间线分支
    _redoStrokes.clear();
    _currentStroke.clear();
    _currentStroke.add(point);
    notifyListeners();
  }

  void undo() {
    if (_historyStrokes.isNotEmpty) {
      // 历史 -> Redo
      _redoStrokes.add(List.from(_historyStrokes.last));
      _historyStrokes.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStrokes.isNotEmpty) {
      // Redo -> 历史
      _historyStrokes.add(List.from(_redoStrokes.last));
      _redoStrokes.removeLast();
      notifyListeners();
    }
  }
}
```

### 2. UI 绑定 (Screen)

使用 `ListenableBuilder` 包裹 UI，根据 Controller 的变化自动刷新。

```dart
// lib/src/features/blackboard/presentation/blackboard_screen.dart

// 所有的手势逻辑委托给 Controller
Listener(
  onPointerDown: (event) => controller.startStroke(event.localPosition),
  // ...
  
  // 画板区域绑定
  child: ListenableBuilder(
    listenable: controller,
    builder: (context, child) => CustomPaint(
      painter: BlackboardPainter(
        currentStroke: controller.currentStroke, // 只读数据源
        historyStrokes: controller.historyStrokes,
      ),
    ),
  ),
),

// ...

// 工具栏区域绑定（按钮的 Disabled 状态也需要实时刷新）
ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      return BlackboardToolbar(
        onUndo: () => controller.undo(),
        // 动态判断是否可点击
        canUndo: controller.historyStrokes.isNotEmpty,
        // ...
      );
    }
),
```

### 3. 工具栏样式 (Toolbar)

使用深色卡片风格，并处理按钮的禁用样式。

```dart
// lib/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart

Card(
  color: const Color(0xFF333333), // ClassIn 风格深色背景
  child: Column(
    children: [
      IconButton(
        icon: Icon(Icons.undo, color: canUndo ? Colors.white : Colors.white24),
        // onPressed 传 null 自动禁用
        onPressed: canUndo ? onUndo : null,
      ),
      // ...
    ],
  ),
)
```

## 学习总结

1.  **ChangeNotifier vs setState**:  对于复杂的交互（如撤销重做），将逻辑抽离到 Controller 中比直接在 Widget 里用 `setState` 无论是代码清晰度还是可维护性都高得多。
2.  **List.from (深拷贝)**: 存入历史栈时，必须创建列表的副本，否则引用的还是同一个列表对象，会被后续操作修改。
3.  **Redo 栈的生命周期**: 只要产生了新的绘制操作，Redo 栈就必须清空，这是撤销重做逻辑的金科玉律。
