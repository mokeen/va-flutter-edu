# 项目开发记录（va-edu）

用于记录本项目的目标、范围、里程碑、已实现功能、待办与关键决策。偏“过程文档”，会随着迭代持续更新。

## 文档导航

- 环境配置：`docs/FLUTTER_ENV_SETUP.md`
- Flutter 项目开发说明书：`docs/FLUTTER_DEV_HANDBOOK.md`
- 项目入口与运行：`README.md`

## 项目概况

- **项目名称：**va-edu
- **业务背景：**国际教育企业学习工具探索
- **产品方向：**桌面端 + Web 端优先探索（课堂黑板/画板能力切入）
- **目标平台：**Web + macOS Desktop（后续再评估 iOS/Android）

## 当前阶段目标（MVP）

做出可用的单人黑板：画、擦、选、撤销、导出。

### MVP 范围（第一阶段）

- 画布：无限画布（世界坐标）+ 缩放/平移（相机/视口）
  - 可选：虚拟分页（页数提示，例如 `12.5/50`），连续滚动
- 工具：
  - 指针/选择：选择笔迹/元素、移动、删除（待做）
  - 画笔：自由绘制（已实现，平滑可选优化）
  - 橡皮擦：命中删除 stroke（已实现；按路径擦除待优化）
  - 形状/文本：可选（待做）
- 输出：导出 PNG（链路已打通，占位；下载/保存待做），可选导出 JSON（待做）
- 持久化：本地保存（Web `localStorage` / 桌面文件）（待做）

### 非目标（先不做）

- 实时多人同步、音视频、课堂编排、IM
- 权限系统/账号体系（除非明确要做）

## 里程碑（建议）

- M1：单页黑板（画笔 + 撤销/重做 + 清空）
- M2：工具栏（选择/移动 + 橡皮擦）+ 导出 PNG
- M3：形状/文本（可选）+ 本地保存/加载（JSON）
- M4：多页黑板/课件叠加（可选）
- M5：多人协作（可选：WebSocket/CRDT/事件流回放）

## 当前实现状态（已落地）

### 入口与路由

- 应用入口：`lib/main.dart`（`ProviderScope`）
- 应用壳：`lib/src/app.dart`（`MaterialApp.router`）
- 路由：`lib/src/routing/app_router.dart`（Tab：`/`、`/blackboard`、`/settings`；默认 `initialLocation: /blackboard`；`/blackboard` 重定向）

### 黑板能力

- 无限画布（世界坐标）+ 缩放/平移（`InteractiveViewer`）
- 工具：画笔 / 平移缩放 / 橡皮擦（命中删除 stroke）
- 撤销 / 重做 / 清空
- 页数提示（基于视口中心的世界坐标计算）
- Hooks：黑板页面使用 `HookConsumerWidget` 管理控制器生命周期

### 快捷键（macOS / Web）

- 撤销：`Cmd/Ctrl + Z`
- 重做：`Cmd/Ctrl + Shift + Z`
- 工具切换：`P`（画笔）/ `H`（平移缩放）/ `E`（橡皮擦）

### 已知缺口（待做）

- 导出 PNG：当前仅打通 `RepaintBoundary -> toImage`，未实现 Web 下载与桌面端保存文件
- 选择/移动/删除：未实现
- 本地保存/加载：未实现（JSON 持久化待做）

## 待办（Next）

- 导出 PNG 落地：Web 下载 + macOS 保存文件
- 本地保存/加载：JSON 持久化（Web `localStorage` / 桌面文件）
- 选择/移动/删除：笔迹命中、框选、变换
- 橡皮擦：从“命中删除 stroke”升级为“按路径擦除/切割 stroke”

## 关键决策记录（Decision Log）

- 采用 Riverpod（含代码生成）作为状态管理与依赖注入基础
- 路由采用 GoRouter
- 黑板渲染采用 `CustomPaint` + `Canvas`，交互采用 `Listener`/`PointerEvent`
