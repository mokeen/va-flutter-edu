# 画板从 0 → 1（对应总纲 TODO #1）

这份文档只拆分“实现画板（MVP）”这一件事：能画、能保留多笔画、基本线条样式。

总纲 TODO 在：`docs/VA_EDU_DEV_LOG.md`。

## 约定

- 每一步只做一件事：尽量只改 1–2 个文件。
- 先跑起来再重构：功能稳定后再把代码“变好看”。
- 生成代码（`*.g.dart`/`*.freezed.dart`）不手改；IDE 已在 `.vscode/settings.json` 隐藏。

## 范围（只做这些）

- 画板画布：能显示背景
- 画笔输入：PointerDown/Move/Up 采样点
- 绘制：能画出当前笔迹、抬笔后能保留多笔画

## 非范围（后续总纲 TODO 再做）

- 撤销/重做/清空
- 橡皮擦
- 滚动/分页/页数提示
- 导出 PNG
- 本地保存/加载（JSON）
- 选择/移动/删除

## Step TODO（画板 MVP）

### Step 1：画板页面骨架（占位 → 画布）

- [ ] 把 `lib/src/features/blackboard/presentation/blackboard_screen.dart` 从占位卡片替换为画布区域（先不接工具栏/按钮）

验收：进入黑板页面能看到“画布区域”，无报错。

### Step 2：最小画布（只画背景）

- [ ] `CustomPaint` + `Canvas.drawRect` 画背景色
- [ ] 明确坐标系：先用屏幕坐标（`event.localPosition`），暂不做世界坐标/缩放

验收：画布背景稳定显示，resize 不崩。

### Step 3：能画一条线（仅当前笔迹）

- [ ] 用 `Listener` 采集 PointerDown/Move/Up
- [ ] 保存点列表（只保存当前笔迹）
- [ ] Painter 里把点连成 Path 画出来

验收：按下拖动能画线，抬起后线消失（因为还没做持久化）。

### Step 4：多笔画（笔迹列表）

- [ ] 抬笔后把当前 stroke 放进 strokes 列表
- [ ] Painter 同时绘制 strokes + activeStroke

验收：多次绘制的线都保留在画布上。

### Step 5：基础线条样式（最小）

- [ ] 线条使用圆角端点/连接（`StrokeCap.round`/`StrokeJoin.round`）
- [ ] 先固定 `strokeWidth` 与颜色常量（不做 UI 调参）

验收：线条视觉更接近真实笔迹；绘制不卡顿。

## 学习建议（读代码顺序）

- 渲染链路：输入（`Listener`）→ 数据（点/笔迹）→ 绘制（`CustomPainter.paint`）
- 边界条件：空点、点过少、抬笔收尾、重绘频率
