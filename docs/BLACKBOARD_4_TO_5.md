# 画板从 4 → 5（对应总纲 TODO #5）

这份文档记录了画板从单一的绘制工具进化为具备 **选择、变换与专业化交互 (Selection & Transformation)** 能力的完整编辑器。

总纲 TODO 在：`docs/VA_EDU_DEV_LOG.md`。

---

## 范围（Scope）

1.  **编辑能力**：
    - **命中测试**：点选（精准）与框选（批量）。
    - **变换操作**：平移（Move）、删除（Delete）。
    - **历史支持**：所有编辑操作均支持 Undo/Redo。
2.  **交互专业化**：
    - **工具栏重构**：按操作、绘制、系统逻辑分区。
    - **状态自清理**：切换工具时自动清除选中态。
    - **智能回弹**：无内容时自动切回画笔模式。
3.  **原生限制**：
    - macOS 窗口最小尺寸限制 (Content Min Size)。

---

## Step TODO List

### [x] Step 1：基础选择能力 (Selection Core)

- [x] 定义 `BlackboardMode.selection`。
- [x] 实现点击命中算法 (`_findStrokeAt`)：基于点到线段距离。
- [x] 实现矩形框选算法 (`_selectStrokesInRect`)：基于包围盒相交。

### [x] Step 2：变换与指令 (Transformation & Command)

- [x] 实现平移交互：
  - 渲染层：`BlackboardPainter` 实时预览位移增量。
  - 逻辑层：松手后固化坐标。
- [x] 引入 `MoveCommand`：记录受影响笔迹的索引与位移向量，支持撤销。
- [x] 实现智能删除：复用 `EraseCommand` 实现“删除选中”功能。

### [x] Step 3：专业化细节 (Professional Polish)

- [x] **状态管理**：切换画笔/橡皮时，自动清空 `_selectedIndexes`。
- [x] **禁用逻辑**：无笔迹时，“选择”与“橡皮”工具置灰不可用。
- [x] **模式回弹**：撤销/清空导致画布为空时，自动切回画笔。
- [x] **macOS 限制**：原生 Swift 代码强制窗口最小尺寸 800x600。

### [x] Step 4：UI 视觉重构 (Visuals)

- [x] 工具栏增加逻辑分割线。
- [x] 优化选中高亮（青色）与橡皮擦激活态。
- [x] 完善 Tooltip 快捷键提示 `(V)`, `(P)`, `(E)`。

---

## 核心代码实现

### 1. 移动命令 (MoveCommand)

支持增量位移的撤销与重做。

```dart
class MoveCommand implements BlackboardCommand {
  final Set<int> indices;
  final Offset delta;

  MoveCommand(this.indices, this.delta);

  @override
  void execute(List<List<Offset>> strokedHistory) {
    for (final index in indices) {
      if (index >= 0 && index < strokedHistory.length) {
        final stroke = strokedHistory[index];
        for (int i = 0; i < stroke.length; i++) {
          stroke[i] += delta; // 对选中笔迹应用位移
        }
      }
    }
  }

  @override
  void undo(List<List<Offset>> strokedHistory) {
    for (final index in indices) {
      if (index >= 0 && index < strokedHistory.length) {
        final stroke = strokedHistory[index];
        for (int i = 0; i < stroke.length; i++) {
          stroke[i] -= delta; // 反向操作
        }
      }
    }
  }
}
```

### 2. 模式切换自清理 (Auto Cleanup)

`BlackboardController` 中的逻辑守卫。

```dart
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
```

### 3. macOS 原生窗口限制

在 `MainFlutterWindow.swift` 中强制约束。

```swift
override func awakeFromNib() {
    // ...
    // 强化方案：设置内容区域的最小尺寸
    self.contentMinSize = NSSize(width: 800, height: 600)

    // 启动时强制纠正尺寸
    var rect = self.frame
    if rect.size.width < 800 || rect.size.height < 600 {
        rect.size.width = max(rect.size.width, 800)
        rect.size.height = max(rect.size.height, 600)
        self.setFrame(rect, display: true)
    }
    // ...
}
```

---

## 学习总结

1.  **编辑模式的隔离**：将“绘制”与“选择”作为互斥模式，并配合自动状态清理，是保证用户心智模型清晰的关键。
2.  **增量预览**：移动操作中，只在渲染层应用临时的 `Offset` 增量，直到松手才修改真实数据。这既保证了 120fps 的流畅度，又简化了撤销逻辑。
3.  **原生与 Flutter 的边界**：涉及到窗口尺寸强约束时，原生代码 (`NSWindow`) 比 Flutter 层的 `ConstrainedBox` 更可靠且体验更好。
