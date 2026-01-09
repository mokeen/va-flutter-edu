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
- [ ] TODO #2：撤销 / 重做 / 清空
  - 目标：实现工具栏 UI，完成撤销、重做与清空逻辑
  - 细拆：`docs/BLACKBOARD_1_TO_2.md`
- [ ] TODO #3：橡皮擦（先“命中删除 stroke”，再考虑路径擦除）
- [ ] TODO #4：浏览/滚动（可选：长画布、多页、页数提示）
- [ ] TODO #5：导出 PNG（Web 下载 / 桌面保存）
- [ ] TODO #6：本地保存/加载（JSON）
- [ ] TODO #7：选择/移动/删除（命中、框选、变换）
- [ ] TODO #8：多页黑板/课件叠加（可选）

## 关键决策记录（Decision Log）

- 采用 Riverpod（含代码生成）作为状态管理与依赖注入基础
- 路由采用 GoRouter
- 黑板渲染采用 `CustomPaint` + `Canvas`，交互采用 `Listener`/`PointerEvent`
