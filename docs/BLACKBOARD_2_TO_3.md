# 画板从 2 → 3：橡皮擦（对应总纲 TODO #3）

**目标**：实现“对象擦除”功能。用户切换到橡皮擦模式后，手指经过的笔迹会被删除。

---

## 核心挑战

1.  **模式切换**：不仅要“画”，还要能“擦”。Controller 需要一个状态 `toolType` (Pen / Eraser)。
2.  **命中检测 (Hit Test)**：怎么知道手指是不是碰到了线条？需要点到直线的距离算法。
3.  **撤销的复杂性**：
    *   之前的 `undo` 只是简单地 `pop` 最后一笔。
    *   擦除是“删除中间的某一笔”，这会破坏 `history` 的顺序。
    *   **策略**：本阶段先实现**简单物理删除**（删除后可能无法完美撤销，或者需要升级 Undo 系统）。为降低难度，我们先做“删除”，暂不处理“擦除操作的撤销”，或者采用简单的“软删除”策略。

---

## Step TODO List

### Step 1：模式支持 (UI & State)

- [ ] Controller：添加 `BlackboardMode` 枚举 (draw, eraser)。
- [ ] Controller：添加 `setMode` 方法。
- [ ] Toolbar：添加“橡皮擦”按钮。
    - 选中状态高亮（需区分当前是画笔还是橡皮）。

### Step 2：命中检测算法 (Math)

- [ ] Controller：添加私有方法 `_isHit(stroke, point)`。
    - 逻辑：遍历 stroke 的所有线段，计算 point 到线段的距离。如果 `< threshold` (如 10px) 则判定命中。

### Step 3：实现擦除逻辑

- [ ] 修改 `moveStroke` / `startStroke` 逻辑：
    - 如果是 **Eraser Mode**：不产生新点，而是遍历 `historyStrokes`，对每一笔进行 `_isHit` 检测。
    - 如果命中：从 `_historyStrokes` 中移除该笔迹 -> `notifyListeners`。

### Step 4：优化与细节

- [ ] 橡皮擦的拖尾效果（可选）：手指划过时显示一个半透明的小圆圈，提示擦除范围。
