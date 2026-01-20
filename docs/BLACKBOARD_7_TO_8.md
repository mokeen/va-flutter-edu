# 画板从 7 → 8 (TODO #8：高清导出与空间无损渲染)

本阶段致力于将画板内容转化为可分享、可打印的专业级资产。通过重构 PDF 和 PNG 导出引擎，解决内容截断、比例失调及视觉丢失等核心痛点。

---

## 🏗️ 核心目标 (Goals)

1.  **高保真 PDF 导出**：支持矢量图形、原生虚线、多行文本及针对打印模式的智能颜色反转（白底黑字）。
2.  **无限长图 PNG 导出**：彻底移除高度限制，支持捕获超长课件，并解决垂直偏移与空间压缩问题。
3.  **国际化文件名支持**：支持中文课件名及特殊字符处理，并集成时间戳。
4.  **交互体验优化**：新增“导出后一键直达目录”功能，实现流畅的生产力闭环。

---

## 📐 技术方案 (Technical Approach)

### 1. PDF 渲染引擎重构

- **坐标校准**：弃用简单的 PDF 容器缩放，改为在 `PdfGraphics` 层面手动计算坐标，解决 Y 轴反转与图形偏移。
- **混合渲染**：手绘笔迹使用路径渲染，矩形与圆形使用原生 PDF 函数以获得最高清晰度。
- **字体集成**：通过 `rootBundle` 嵌入 NotoSansSC 字体，并提供 Google Fonts 网络下载备选方案，解决中文乱码与崩溃风险。

### 2. PNG 空间拓扑优化

- **无损垂直映射**：建立 `minPage` 到 `maxPage` 的连续页面序列，确保 PNG 的物理高度与黑板的逻辑坐标 100% 对齐。
- **绘制原子化**：移除绘图循环中的 `yield`（Future.delayed），确保在单帧快照中完成超长图绘制，防止 UI 状态干扰。
- **虚线支持**：基于 `PathMetrics` 实现自定义虚线路径算法，填补 Canvas 原生虚线 API 的缺失。

---

## 📝 Step TODO List

### Step 1: PDF 高保真重构 (PDF Refactor) [DONE]

- [x] 实现 `_PdfStrokesWidget` 及其原生坐标计算逻辑。
- [x] 支持多行文本拆分渲染。
- [x] 实现 PDF 打印模式：白底背景 + 智能深色转换。
- [x] 支持 native dash pattern (`setLineDashPattern`)。

### Step 2: PNG 无限长度适配 (Unlimited PNG) [DONE]

- [x] 修改 `exportToPng` 的 `totalHeight` 计算公式，引入缩放因子。
- [x] 实现连续页面分配算法，保留页面间的物理垂直间隙。
- [x] 支持负坐标（Negative Y）内容的包含与渲染。

### Step 3: 交互与流程增强 (UX Flow) [DONE]

- [x] 优化 `_performExport` 的 Loading 状态与文件名生成正则。
- [x] 实现 macOS `open -R` / Windows `explorer /select` 原生 reveal 逻辑。
- [x] 更新 SnackBar，添加“打开目录”快速操作按钮。

---

## 💡 关键代码预览 (Key Implementation Highlights)

### 1. PNG 虚线路径计算 (解决原生 Canvas 缺失问题)

由于 Flutter `Canvas` 导出至 `ui.Image` 时缺乏原生的 `setDashPath` 接口，采用了基于像素路径测量的手动采样算法。

```dart
static void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  const double dashWidth = 10.0;
  const double dashSpace = 8.0;

  final ui.Path dashPath = ui.Path();
  for (final ui.PathMetric pathMetric in path.computeMetrics()) {
    double distance = 0.0;
    while (distance < pathMetric.length) {
      final double nextDistance = distance + dashWidth;
      // 提取片段并重建路径
      dashPath.addPath(
        pathMetric.extractPath(distance, nextDistance),
        ui.Offset.zero,
      );
      distance = nextDistance + dashSpace;
    }
  }
  canvas.drawPath(dashPath, paint);
}
```

### 2. PDF 多行文本精确排版 (解决字号与换行偏移)

针对 PDF 导出不支持 `\n` 的问题，手动计算 Ascender 偏移并在 Y 轴递减渲染。

```dart
final lines = stroke.text!.split('\n');
final fontSize = stroke.style.width * scale;
final lineHeight = fontSize * 1.2;

for (int i = 0; i < lines.length; i++) {
  // PDF 坐标系从左下角起算，换行需 Y 轴向下递减
  final lineY = p.y - fontSize - (i * lineHeight);
  canvas.drawString(font!.getFont(context), fontSize, lines[i], p.x, lineY);
}
```

### 3. PNG 导出高度缩放校准 (解决 37.5% 画幅缺失)

修复了逻辑坐标与物理像素混用导致的内容截断。

```dart
final scale = width / 1000.0;
// 核心修复：画布总高度必须同步乘以 Scale，否则下方内容会被 Canvas 裁剪
final double totalHeight = data.pages.length * pageHeight * scale;
```

### 4. 空间拓扑分配 (支持负坐标与空页)

```dart
// PNG: 强制包含 minIdx 到 maxIdx 的所有空间，不进行空页压缩
exportPages = List.generate(maxIdx - minIdx + 1, (i) {
  final actualIdx = minIdx + i;
  final startY = actualIdx * controller.logicalPageHeight;
  return (pageMap[actualIdx] ?? []).map((s) => s.copyWith(
    points: s.points.map((p) => Offset(p.dx, p.dy - startY)).toList(),
  )).toList();
});
```

---

## ✅ 最终实现 (Final Implementation)

### 1. 导出保真度

通过精准的 `scale` 与 `offset` 映射，彻底解决了由于计算误差导致导出的内容缺失（由于垂直像素点与逻辑点换算出错，之前每页下半部分 30% 被裁掉）的顽疾。

### 2. 功能完备性

- **PDF**：具备了完美的打印阅读能力，支持中文渲染与深色模式转换。
- **PNG**：对标 ClassIn 的长图模式，支持无限长、不丢笔画、不压缩黑板空间。

### 3. 系统集成

通过 `interactiveSave` 结合系统对话框与原生文件夹打开功能，使得导出流程具备了专业生产力前端应用的成熟感。
