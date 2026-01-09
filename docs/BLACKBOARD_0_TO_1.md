# 画板从 0 → 1（对应总纲 TODO #1）

这份文档只拆分“实现画板（MVP）”这一件事：能画、能保留多笔画、基本线条样式。

总纲 TODO 在：`docs/VA_EDU_DEV_LOG.md`。

---

## 约定

- 每一步只做一件事：尽量只改 1–2 个文件。
- 先跑起来再重构：功能稳定后再把代码“变好看”。
- 生成代码（`*.g.dart`/`*.freezed.dart`）不手改；IDE 已在 `.vscode/settings.json` 隐藏。

## 范围（只做这些）

- 画板画布：能显示背景
- 画笔输入：PointerDown/Move/Up 采样点
- 绘制：能画出当前笔迹、抬笔后能保留多笔画

---

## Step TODO（画板 MVP）—— 已完成

### Step 1：画板页面骨架（占位 → 画布）

- [x] 把 `lib/src/features/blackboard/presentation/blackboard_screen.dart` 从占位卡片替换为画布区域
- 核心代码：
```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        // 使用 Listener 监听原始指针事件（比 GestureDetector 更底层，无延迟）
        child: Listener(
          // ... 交互事件
          // CustomPaint 是连接逻辑层与渲染层的桥梁
          child: CustomPaint(
            // 将数据（State）传递给 Painter（View）
            // 只要 points 或 historyStrokes 发生变化，Painter 就会被触发重绘
            painter: BlackboardPainter(
              currentStroke: currentStroke,
              historyStrokes: historyStrokes,
            ),
          ),
        ),
      ),
    );
  }
```

### Step 2：最小画布（只画背景）

- [x] `CustomPaint` + `Canvas.drawRect` 画背景色
- [x] 明确坐标系
- 核心代码 (`BlackboardPainter`)：
```dart
    // 1. 绘制背景
    // 使用 Paint 对象的级联操作 (..) 快速配置属性
    final backgroundPaint = Paint()..color = const Color.fromARGB(255, 88, 72, 72);
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    // drawRect: 填充整个画布区域
    canvas.drawRect(rect, backgroundPaint);
```

### Step 3：能画一条线（仅当前笔迹）

- [x] 用 `Listener` 采集 PointerDown/Move/Up
- [x] 保存点列表（只保存当前笔迹）
- 核心代码 (`BlackboardScreen`)：
```dart
          onPointerDown: (event) {
            // 手指按下：开始新的一笔
            setState(() {
              // 初始化当前笔迹，存入起始点
              currentStroke = [event.localPosition];
            });
          },
          onPointerMove: (event) {
            // 手指移动：持续收集点
            setState(() {
              // 将新采集的点追加到当前笔迹中
              // 注意：频繁 setState 会触发重绘，这是实时的关键
              currentStroke.add(event.localPosition);
            });
          },
```
- 核心代码 (`BlackboardPainter`)：
```dart
    // 2. 绘制当前正在画的那一笔
    if (currentStroke.isNotEmpty) {
      // ... 配置 Paint ...
      // 使用 PointMode.polygon 将点依次连接成线
      canvas.drawPoints(PointMode.polygon, currentStroke, strokePaint);
    }
```

### Step 4：多笔画（笔迹列表）

- [x] 抬笔后把当前 stroke 放进 strokes 列表
- [x] Painter 同时绘制 strokes + activeStroke
- 核心代码 (`BlackboardScreen`)：
```dart
          onPointerUp: (event) {
            // 手指抬起：结束当前笔，归档到历史
            setState(() {
              // 将 currentStroke 添加到历史记录中
              historyStrokes.add(currentStroke);
              // 清空 currentStroke，准备下一次绘制
              // 注意：这里必须重新赋值一个新列表，避免引用问题
              currentStroke = [];
            });
          },
```
- 核心代码 (`BlackboardPainter`)：
```dart
    // 3. 绘制所有历史笔迹
    // TODO(Optimization): 当笔迹较多时，应考虑使用 RepaintBoundary 分层渲染，避免重绘历史笔迹
    for (final stroke in historyStrokes) {
      // ... 配置 Paint ...
      canvas.drawPoints(PointMode.polygon, stroke, historyStrokePaint);
    }
```

### Step 5：基础线条样式（最小）

- [x] 线条使用圆角端点/连接（`StrokeCap.round`/`StrokeJoin.round`）
- 核心代码 (`BlackboardPainter`)：
```dart
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke // 显式声明为描边模式
        ..strokeCap = StrokeCap.round  // 线段端点圆滑处理
        ..strokeJoin = StrokeJoin.round; // 线段连接处圆角处理
```
