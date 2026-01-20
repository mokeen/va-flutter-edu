# VA-Edu: Flutter 全栈开发与黑板系统深度学习项目

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-%239B029B.svg?style=flat)](https://riverpod.dev)
[![Learning Project](https://img.shields.io/badge/Project-Experimental%20Learning-orange.svg)]()

本项目是一个深度探索 Flutter 高级特性的**实战学习项目**。以“专业级教育黑板”为业务载体，系统性地沉淀了从基础架构、状态管理、矢量渲染到高质量导出的一整套研发流水线成果。

**核心学习价值 (Learning Value):**

- 🛠️ **全栈架构实战**：基于 `Riverpod` + `GoRouter` + `Provider` 构建的响应式前端架构参考。
- 🎨 **高级图形编程**：深度挖掘 `CustomPainter` 与 `PathMetrics`，实现高性能的手写感算法与图形引擎。
- ⚙️ **工程化实践**：一套完整的 `0 → 8 阶段` 演进文档，还原了一个复杂功能模块从 MVP 到商业级成熟度的全过程。
- 📄 **高保真渲染出口**：攻克了 PDF 矢量生成、PNG 无限高度长图、硬件加速离线渲染等诸多“深水区”技术挑战。

---

## 📚 学习路径与演进文档 (Evolutionary Docs)

本项目的一大特色是提供了完整的**研发全寿命周期记录**，按照开发顺序编排，非常适合 Flutter 开发者进阶学习：

1.  **里程碑总纲**: `docs/VA_EDU_DEV_LOG.md` (项目全景图)
2.  **分阶段演进手册 (全集)**:
    - [x] `docs/BLACKBOARD_0_TO_1.md`: **[MVP]** 基础画板构建、手绘笔迹实现
    - [x] `docs/BLACKBOARD_1_TO_2.md`: **[Command]** 命令模式实现撤销 (Undo) 与重做 (Redo)
    - [x] `docs/BLACKBOARD_2_TO_3.md`: **[Eraser]** 线条对象化关联与像素级擦除碰撞检测
    - [x] `docs/BLACKBOARD_3_TO_4.md`: **[UI/Scroll]** 无限垂直滑动画布、多页管理与层级优化
    - [x] `docs/BLACKBOARD_4_TO_5.md`: **[Select]** 矩阵变换、矩形框选与对象命中算法
    - [x] `docs/BLACKBOARD_5_TO_6.md`: **[Rich Tool]** 几何工具(圆/方/线)、荧光笔渲染、文本工具
    - [x] `docs/BLACKBOARD_6_TO_7.md`: **[Persistence]** 本地 JSON 数据持久化、自动存档与库管理
    - [x] `docs/BLACKBOARD_7_TO_8.md`: **[Export]** 专业级 PDF/PNG 导出，攻克矢量缩放与长图拼接

---

## 🛠️ 技术栈沉淀 (Tech Stack)

- **状态管理**: Riverpod 2.x (核心逻辑全代码生成，强类型安全)
- **图形引擎**: `dart:ui` + `CustomPaint` (深度定制笔迹、虚线、阴影渲染)
- **持久化**: JSON Model 序列化 + 本地文件 IO 操作
- **高级导出**: 基于 `pdf` 库的矢量重写与基于像素测量的自定义 PNG 剪裁算法

---

## 🚀 快速启动

```bash
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
fvm flutter run -d macos    # 体验完整桌面端逻辑
```

---

## 🤝 开源协议与交流

本项目旨在提供优质的 Flutter 学习参考实现。您可以自由引用其中的矢量算法、架构模式或导出逻辑作为您的项目起步模板。

**关键词 (Keywords)**: Flutter 学习项目, 状态管理实战, 矢量渲染引擎, PDF 导出算法, PNG 长图拼接, Riverpod 最佳实践, 跨平台开发参考。
