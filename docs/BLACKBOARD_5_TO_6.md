# 画板从 5 → 6 (TODO #6：功能扩展与架构飞跃)

本阶段是黑板应用的里程碑，将画板从“简单绘图”提升为“工业级协作工具”。重点实现了**复杂图形支持**、**智能排版辅助**以及**专业化组织管理**。

---

## 🏗️ 核心功能范围 (Scope)

### 1. 绘图能力进化

- **全能配置面板**：支持 12 色预设调色盘、多档粗细滑块、实线/虚线切换。
- **高级画笔**：
  - **荧光笔 (Highlighter)**：基于混合模式的半透明标记。
  - **激光笔 (Laser Pointer)**：支持轨迹自动淡出的演示模式（3.5s 生命周期）。
- **几何图形工具**：直线、矩形、圆形、箭头，支持实时预览与吸附。
- **专业文本引擎**：支持内联输入、双击二次编辑、多行文本处理。

### 2. 智能组织与排版 (Organization)

- **分页全景预览**：侧边栏实时缩略图，支持 50 页快速导航，动态适配窗口比例。
- **对象组合 (Grouping)**：支持多个笔迹打包，联动移动、缩放与删除。
- **层级控制 (Z-Order)**：精细的对象叠放次序管理（置顶、置底、逐层移动）。
- **智能吸附 (Smart Snapping)**：基于边界线与中心线的 PPT 级自动对齐。

### 3. 交互体验打磨 (UX Polish)

- **浮动选择工具栏**：选中对象时自动弹出，快捷操作组合、层级与克隆。
- **专业缩放手柄**：支持四角手柄缩放，按住 **Shift** 锁定纵横比。
- **视觉反馈**：激光笔定制笔尖、荧光笔专用平头笔触、悬停高亮提示。

---

## 🛠️ 关键代码实现

### 1. 智能吸附算法 (Smart Snapping)

通过计算选择框 (Selection Bounds) 对齐点与画布上其他对象的距离，动态注入吸附偏移量。

```dart
void _handleMovingMove(Offset currentPoint) {
  // ... 计算 delta
  for (final other in otherStrokes) {
    // 检查左、右、中轴对齐
    if ((selectionLeft - otherLeft).abs() < threshold) {
      snapDeltaX = otherLeft - selectionLeft;
      _snapLines.add(Offset(otherLeft, 0)); // 触发垂直参考线
    }
    // ... 对齐 Y 轴同理
  }
}
```

### 2. 对象组合与选中逻辑 (Grouping)

采用 `groupId` 标识，并在选中、删除、移动时实现联动。

```dart
void _expandSelectionToGroups() {
  final groupIds = _selectedIndexes.map((i) => _historyStrokes[i].groupId).whereType<String>().toSet();
  for (int i = 0; i < _historyStrokes.length; i++) {
    if (groupIds.contains(_historyStrokes[i].groupId)) {
      _selectedIndexes.add(i);
    }
  }
}
```

### 3. 动态缩略图 (Dynamic Thumbnails)

通过 Matrix4 变换将逻辑坐标映射到微型画布，并实时计算容器宽高比。

```dart
// BlackboardPageThumbnail
Container(
  width: 120,
  height: 120 / aspectRatio, // 实时适配 controller.aspectRatio
  child: CustomPaint(painter: ThumbnailPainter(strokes: strokes)),
)
```

---

## ⌨️ 快捷操作指南

| 功能          | 快捷键                         | 视觉反馈             |
| :------------ | :----------------------------- | :------------------- |
| **复制对象**  | `Cmd + D`                      | 偏移克隆             |
| **快捷组合**  | `Cmd + G`                      | 浮动栏显示“解组”按钮 |
| **取消组合**  | `Cmd + Shift + G`              | 恢复独立选框         |
| **置顶/置底** | `Shift + ]` / `[`              | 遮挡关系瞬间切换     |
| **等比缩放**  | `Shift + Drag`                 | 锁定纵横比不变形     |
| **模式切换**  | `P` (笔) / `E` (擦) / `V` (选) | 光标形态变化         |

---

## 📈 演进总结

从 TODO 6 开始，数据模型从简单的 `List<Offset>` 迁移到了具有**样式字段 (`StrokeStyle`)** 和 **关系字段 (`groupId`)** 的结构化对象。这不仅满足了当前的视觉需求，也为 TODO 7 的**本地存储**与 TODO 8 的**云端协作**埋下了坚实的架构伏笔。
