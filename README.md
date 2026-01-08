# va_edu

国际教育学习工具探索项目（当前阶段：单人黑板 MVP）。

## 文档

- 环境配置（macOS）：`docs/FLUTTER_ENV_SETUP_macOS.md`
- 环境配置（Windows）：`docs/FLUTTER_ENV_SETUP_Window.md`
- Flutter 项目开发说明书：`docs/FLUTTER_DEV_HANDBOOK.md`
- Counter Demo 学习讲义（Local vs Riverpod 状态注入）：`docs/COUNTER_DEMO_DOC.md`
- 项目开发记录：`docs/VA_EDU_DEV_LOG.md`
- 画板从 0→1（总纲 TODO #1 细拆）：`docs/BLACKBOARD_0_TO_1.md`

## 平台目录速查

- Web：`web/`（`web/index.html`、`web/manifest.json`、`web/icons/*`）
- macOS：`macos/`（Xcode 原生壳工程，关键文件清单见 `docs/FLUTTER_DEV_HANDBOOK.md`）
- Windows：`windows/`（CMake + Runner 工程；Windows 工具链见 `docs/FLUTTER_ENV_SETUP_Window.md`）

## 快速开始

统一使用 FVM：

```bash
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

运行：

```bash
fvm flutter run -d chrome
fvm flutter run -d macos
fvm flutter run -d windows
```

静态检查与测试：

```bash
fvm flutter analyze
fvm flutter test
```

构建：

```bash
fvm flutter build web
fvm flutter build macos --debug
fvm flutter build windows --release
```

## 代码入口

- 应用入口：`lib/main.dart`
- 应用壳与路由：`lib/src/app.dart`、`lib/src/routing/app_router.dart`
- 黑板页面：`lib/src/features/blackboard/presentation/blackboard_screen.dart`

## 当前状态

- 黑板页面当前为画板占位页，后续将逐步实现画板能力。
- 按 `docs/BLACKBOARD_0_TO_1.md` 从 0→1 实现“画板 MVP”（对应总纲 TODO #1）。

## 已知缺口（下一步）

- 其余能力按总纲 TODO 逐步补齐：`docs/VA_EDU_DEV_LOG.md`
