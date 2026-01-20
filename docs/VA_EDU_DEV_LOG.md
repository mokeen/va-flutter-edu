# 项目开发记录（va-edu）

用于记录本项目的总体目标、里程碑、总纲 TODO 与关键决策。每个大 TODO 的细拆会单独落在对应文档中。

## 文档导航

- 环境配置：`docs/FLUTTER_ENV_SETUP_macOS.md`
- Flutter 项目开发说明书：`docs/FLUTTER_DEV_HANDBOOK.md`
- 项目入口与运行：`README.md`
- 画板从 0→1（总纲 TODO #1 的细拆）：`docs/BLACKBOARD_0_TO_1.md`

---

## 项目概况

- **项目名称：**va-edu
- **业务背景：**国际教育企业学习工具探索
- **产品方向：**桌面端 + Web 端优先探索（课堂黑板/画板能力切入）
- **目标平台：**Web + macOS Desktop（后续再评估 iOS/Android）

## 工程信息（项目相关索引）

### 入口与路由

- 应用入口：`lib/main.dart`
- 应用根：`lib/src/app.dart`（`MaterialApp.router`，从 Provider 读取路由并注入）
- 路由声明：`lib/src/routing/app_router.dart`（`go_router` 路由表）
- 路由 Provider（生成）：`lib/src/routing/app_router.g.dart`（自动生成，不手改）
- Shell（承载 Tab/导航 UI）：`lib/src/shell/app_shell.dart`

### 主题与资源

- 全局主题：`lib/src/app.dart`（`ThemeData` / `colorSchemeSeed`）
- 渐变背景：`lib/src/shell/app_shell.dart`（Shell 层背景装饰）
- 首页海报图：`assets/images/poster.png`（缺失时可用占位方案替代）
  - 资源声明：`pubspec.yaml` 的 `flutter/assets`

## 总体目标（长期）

做出可用的单人黑板/画板，并逐步补齐：绘制、擦除、选择、撤销/重做、导出、持久化；优先 Web + macOS Desktop。

## 里程碑（建议，高层）

- M1：画板可用（能画、多笔画、基础样式）
- M2：基础工具（撤销/重做/清空 + 橡皮擦）
- M3：导出与保存（PNG + JSON 持久化）
- M4：编辑能力（选择/移动/删除）
- M5：多页/课件叠加（可选）

## TODO 总纲（大项）

- [x] TODO #1：实现画板（MVP）
  - 目标：能画、能保留多笔画、基本线条样式
  - 细拆：`docs/BLACKBOARD_0_TO_1.md`
- [x] TODO #2：撤销 / 重做 / 清空
  - 目标：实现工具栏 UI，完成撤销、重做与清空逻辑
  - 细拆：`docs/BLACKBOARD_1_TO_2.md`
- [x] TODO #3：橡皮擦
  - 目标：对象擦除（点击/划过线条即可删除）
  - 细拆：`docs/BLACKBOARD_2_TO_3.md`
- [x] TODO #4：视图与页面管理
  - 目标：无限画布（垂直滚动）、多页切换、缩放（可选）
  - 细拆：`docs/BLACKBOARD_3_TO_4.md`
- [x] TODO #5：编辑能力 (Selection & Transformation)
  - 目标：选择、移动、删除、变换（命中与框选）
  - 细拆：`docs/BLACKBOARD_4_TO_5.md`
- [x] TODO #6：功能扩展与体验优化 (Extensions & Polish)
  - 目标：画笔/橡皮参数、几何图形、荧光笔/激光笔、文字编辑、分页预览、对象组合与吸附、浮动工具栏
  - 细拆：`docs/BLACKBOARD_5_TO_6.md`
- [x] TODO #7：本地数据持久化 (Local Persistence)
  - 目标：实现本地 JSON 存档，支持自动保存与多文件管理
  - 细拆：`docs/BLACKBOARD_6_TO_7.md`
- [x] TODO #8：高清导出 (Professional Export)
  - 目标：支持一键导出为高清 PDF 或长图（课件分享）
  - 细拆：`docs/BLACKBOARD_7_TO_8.md`

## 关键决策记录（Decision Log）

- 采用 Riverpod（含代码生成）作为状态管理与依赖注入基础
- 路由采用 GoRouter
- 黑板渲染采用 `CustomPaint` + `Canvas`，交互采用 `Listener`/`PointerEvent`
