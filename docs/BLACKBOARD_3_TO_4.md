# 画板从 3 → 4（对应总纲 TODO #4）

这份文档记录了画板从离散页面模式进化为 **统一缩放投影画布 (Unified Scaling Canvas, Plan C+)** 的设计与实现。

总纲 TODO 在：`docs/VA_EDU_DEV_LOG.md`。

---

## 约定

- **统一画布 (Plan C+)**：不再有物理隔离的 `Page` 对象。整个画板是一条垂直无限延伸的长卷。
- **宽度基准缩放 (Width-Anchor Scaling)**：所有坐标以逻辑宽度 `1000.0` 为基准存储。渲染时根据窗口实际宽度自动缩放。
- **动态视口分页 (Dynamic Viewport Paging)**：逻辑上的“一页”高度动态等于当前窗口高度，确保 100% 视口填充。
- **全局撤销/重做**：整个画板共用一套 Undo/Redo 栈，操作跨越逻辑页边界。

---

## 范围（Scope）

1.  **视图控制**：
    - 支持连续垂直滚动。
    - 自适应窗口 Resize，保持笔迹相对比例不变。
2.  **坐标转换**：
    - 引入 `baseWidth` 和 `scaleFactor`。
    - 存算分离：Base 坐标系存数据，屏幕坐标系处理手势。
3.  **阅读模式集成**：
    - 翻页按钮跳转“整屏”高度。
    - 逻辑页码标识 `- N -` 自动吸附在每屏底部。

---

## Step TODO List

### [x] Step 1：坐标系重构 (Scaling & Projection)

- [x] 引入 `baseWidth = 1000.0`。
- [x] 实现 `toBasePoint` 转换公式。
- [x] 修改 `BlackboardPainter` 应用全局 `canvas.scale`。

### [x] Step 2：动态分页逻辑 (Dynamic Logical Paging)

- [x] `logicalPageHeight = ViewportHeight / scaleFactor`。
- [x] 移除固定 16:9 比例锁定，改为视口垂直填充。

### [x] Step 3：全局数据流 (Unified History)

- [x] 移除 `BlackboardPage` 结构，改为单列笔迹存储。
- [x] 实现跨页连续书写支持。

### [x] Step 4：UI 控件优化 (Navigation)

- [x] 实现“回到首页 (Jump to Home)”功能。
- [x] 翻页按钮适配动态页高跳转。

---

## 核心设计思路 (Design Final)

### 1. 坐标投影公式

```dart
// 1. 屏幕点 -> 逻辑 Base 坐标 (存储用)
Offset toBasePoint(Offset screenPoint) {
  return Offset(
    screenPoint.dx / scaleFactor,
    (screenPoint.dy + scrollOffset) / scaleFactor,
  );
}

// 2. 渲染转换 (Painter)
void paint(Canvas canvas, Size size) {
  canvas.scale(scaleFactor); // 统一宽度缩放
  canvas.translate(0, -scrollOffset / scaleFactor); // 垂直滚动平移
  // ... 绘制所有笔迹
}
```

### 2. 动态页高逻辑

为了消灭“黑边”并实现“一页等于一屏”，页高随视口动态变化：

```dart
// 逻辑页高 = 视口高度像素 / 当前宽度的缩放系数
double get logicalPageHeight => viewportHeight / scaleFactor;

// 跳转到第 N 页 (0-indexed)
void jumpToPage(int index) {
  _scrollOffset = index * viewportHeight; // 直接按屏幕高度跳转
}
```

### 3. 性能考量

- **单层重绘**：Plan C 下所有笔迹在一个层级，对于 50 页的高负载，建议后续引入 `PictureRecorder` 缓存已滑出的静态页面区域。
- **数据压缩**：存储 Base 坐标而非屏幕坐标，极大减少了 Resize 时的计算开销。

---

## 学习总结

- **统一画布** 解决了多端协作下的比例一致性问题（以宽度为唯一锚点）。
- **动态分页** 兼顾了连贯的阅读手感与完美的视觉填充。
- **坐标分离** 是处理响应式绘图应用的核心命题。
