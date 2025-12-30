# va_edu

国际教育学习工具探索项目（当前阶段：单人黑板 MVP）。

## 文档

- 环境配置：`docs/FLUTTER_ENV_SETUP.md`
- Flutter 项目开发说明书：`docs/FLUTTER_DEV_HANDBOOK.md`
- 项目开发记录：`docs/VA_EDU_DEV_LOG.md`

## 平台目录速查

- Web：`web/`（`web/index.html`、`web/manifest.json`、`web/icons/*`）
- macOS：`macos/`（Xcode 原生壳工程，关键文件清单见 `docs/FLUTTER_DEV_HANDBOOK.md`）

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
```

## 代码入口

- 应用入口：`lib/main.dart`
- 应用壳与路由：`lib/src/app.dart`、`lib/src/routing/app_router.dart`
- 黑板页面：`lib/src/features/blackboard/presentation/blackboard.dart`

## 已实现（当前）

- 无限画布（世界坐标）+ 缩放/平移（`InteractiveViewer`）
- 工具：画笔 / 平移缩放 / 橡皮擦
- 撤销 / 重做 / 清空
- 页数提示（虚拟分页显示）
- Hooks：黑板页面使用 `HookConsumerWidget` 管理控制器生命周期

## 已知缺口（下一步）

- 导出 PNG：目前只做了导出链路占位（SnackBar 显示字节数），未落盘/下载
- 选择/移动/删除：未实现
- 本地保存/加载：未实现（JSON 持久化待做）
