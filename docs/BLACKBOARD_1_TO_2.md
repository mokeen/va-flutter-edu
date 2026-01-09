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

### Step 1：工具栏 UI (Toolbar Widget)

- [ ] 创建 `lib/src/features/blackboard/presentation/widgets/blackboard_toolbar.dart`
- [ ] 实现一个简单的 `Row` 或 `Column`，包含三个 `IconButton`（撤销、重做、清空）
- [ ] 在 `BlackboardScreen` 中使用 `Stack` 将 Toolbar 放置在画布上方
- **验收**：能看到按钮，点击控制台打印日志。

### Step 2：引入 Controller (架构重构)

- [ ] 创建 `lib/src/features/blackboard/domain/blackboard_controller.dart`
- [ ] 定义 `BlackboardController extends ChangeNotifier`
- [ ] 将 `currentStroke` 和 `historyStrokes` 移入 Controller
- [ ] `BlackboardScreen` 使用 `ListenableBuilder` (或 AnimatedBuilder) 监听 Controller
- **验收**：重构后应用行为与之前完全一致（能画线、能多笔画）。

### Step 3：实现撤销 (Undo)

- [ ] Controller 新增 `undo()` 方法
    - 逻辑：`historyStrokes.removeLast()` -> `redoStack.add()`
- [ ] 按钮绑定 `controller.undo()`
- **验收**：绘制后点击撤销，笔迹消失；Undo 栈空时按钮应禁用（可选）。

### Step 4：实现重做 (Redo)

- [ ] Controller 新增 `redo()` 方法
    - 逻辑：`redoStack.removeLast()` -> `historyStrokes.add()`
- [ ] 关键逻辑：**当发生新绘制时，必须清空 redoStack**
- **验收**：撤销后点击重做，笔迹恢复；撤销后画新线，重做失效。

### Step 5：实现清空 (Clear)

- [ ] Controller 新增 `clear()` 方法
    - 逻辑：清空 history 和 redo
- **验收**：点击清空，画布变白。
