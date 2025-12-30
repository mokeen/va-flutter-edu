# Flutter 项目开发说明书（va-edu）

这份文档是“说明书/手册”性质：介绍项目结构、Flutter 开发常识、常用工具与约定，尽量保持长期稳定；项目进度与变更记录请写到 `docs/VA_EDU_DEV_LOG.md`。

## 文档导航

- 环境配置：`docs/FLUTTER_ENV_SETUP.md`
- 项目开发记录：`docs/VA_EDU_DEV_LOG.md`
- 项目入口与运行：`README.md`

## 1. 项目结构（Feature-First）

目录结构约定：

```text
lib/
├── src/
│   ├── app.dart              # MaterialApp 配置 (Theme, Router)
│   ├── routing/              # 路由配置 (GoRouter)
│   ├── constants/            # 全局常量 (Colors, Styles)
│   ├── utils/                # 通用工具 (Logger, Extensions)
│   └── features/             # 业务模块
│       └── blackboard/       # 黑板模块
│           ├── domain/       # 实体与纯模型 (Freezed/Json)
│           ├── data/         # 仓库/数据源（后续接入持久化/网络）
│           ├── application/  # 业务逻辑与状态（Riverpod）
│           └── presentation/ # UI（Widget/Screen）
└── main.dart                 # 程序入口
```

分层原则（简单版）：

- `presentation`：UI 与交互（不直接写业务规则）
- `application`：状态机/用例/命令（可被 UI 调用）
- `domain`：稳定的核心模型（可序列化、可测试）
- `data`：与外部世界交互（本地存储、文件、网络）

## 2. 技术栈与工程化约定

### 2.1 状态管理与依赖注入

- 推荐组合：`flutter_riverpod` + `riverpod_generator`
- UI 侧常用入口：
  - `ConsumerWidget`/`ConsumerStatefulWidget`：标准 Riverpod 写法
  - `HookConsumerWidget`：当页面需要管理 controller 生命周期时（例如 `TransformationController`、`AnimationController`、订阅/监听）

#### 2.1.1 本项目的状态声明（Provider 清单）

路由与业务状态都通过 Provider 暴露（“声明 + 引用”分离，便于测试与复用）：

- `appRouterProvider`：路由 Provider（类型 `GoRouter`）
  - 声明位置：`lib/src/routing/app_router.dart`
  - 生成文件：`lib/src/routing/app_router.g.dart`（由 build_runner 生成）
  - 使用位置：`lib/src/app.dart` 里 `ref.watch(appRouterProvider)`，注入 `MaterialApp.router`
- `BlackboardControllerProvider`：黑板状态与命令（类型 `BlackboardState`，notifier 为 `BlackboardController`）
  - 声明位置：`lib/src/features/blackboard/application/blackboard_controller.dart`
  - 状态模型：`lib/src/features/blackboard/application/blackboard_state.dart`（Freezed）
  - 使用位置：`lib/src/features/blackboard/presentation/blackboard_screen.dart`

常用用法约定：

- 读状态：`ref.watch(xxxProvider)`
- 调用命令：`ref.read(xxxProvider.notifier).method()`

### 2.2 路由

- 使用 `go_router`，集中在 `lib/src/routing/` 管理路由表
- 约定：尽量使用声明式路由（路径、参数、重定向逻辑集中管理）
- 本项目采用 Tab 导航：`StatefulShellRoute.indexedStack`（每个 Tab 独立导航栈），外壳在 `lib/src/shell/app_shell.dart`

#### 2.2.1 本项目路由声明（Route Map）

路由表在 `lib/src/routing/app_router.dart` 里集中声明：

- 初始路由：`/blackboard`
- Tab（IndexedStack）三段：
  - 首页：`/`
  - 黑板：`/blackboard`
  - 设置：`/settings`
- 兼容重定向：
  - `/blackboard` → `/blackboard`

#### 2.2.2 路由文件之间的关系

- `lib/src/routing/app_router.dart`：路由“数据声明”（路径、Tab 结构、重定向）
- `lib/src/routing/app_router.g.dart`：Riverpod 生成的 Provider 封装（无需手改）
- `lib/src/shell/app_shell.dart`：路由“呈现层”（Tab UI）
  - 宽屏使用 `NavigationRail`
  - 窄屏使用 `NavigationBar`
  - 使用 `StatefulNavigationShell` 的 `goBranch` 切换 Tab

### 2.3 不可变数据与序列化

- 使用 `freezed` + `json_serializable`（`freezed_annotation`/`json_annotation`）
- 约定：生成文件（`*.freezed.dart`/`*.g.dart`）不手改

### 2.4 静态分析

在 `analysis_options.yaml` 启用更严格的 lint（例如 `always_use_package_imports`）。

## 3. 依赖与代码生成

### 3.1 常用依赖（本项目）

`dependencies`：

- `flutter_riverpod`、`hooks_riverpod`、`flutter_hooks`
- `go_router`
- `freezed_annotation`、`json_annotation`、`riverpod_annotation`

`dev_dependencies`：

- `build_runner`
- `freezed`
- `json_serializable`
- `riverpod_generator`

### 3.2 代码生成命令

建议统一用下面两条（项目里推荐 `fvm flutter`）：

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
fvm flutter pub run build_runner watch --delete-conflicting-outputs
```

## 4. Flutter 开发常识（精简版）

### 4.1 Widget、Element、RenderObject

- `Widget`：配置（不可变）
- `Element`：运行时实例（把 Widget 挂到树上）
- `RenderObject`：真正负责布局与绘制

理解这三个层次，有助于你在做黑板这种高频绘制场景时选择正确的组件（例如 `CustomPaint`）。

### 4.2 Stateless / Stateful / Hooks

- `StatelessWidget`：纯展示，数据由外部驱动
- `StatefulWidget`：需要生命周期管理（init/dispose）时使用
- Hooks：用函数式方式管理资源与副作用，减少样板代码（例如 `useEffect`/`useMemoized`/`useListenable`）

### 4.3 BuildContext 注意事项

- 避免“跨 async gap”使用 `context`（需要时用 `if (!context.mounted) return;`）
- 尽量在同一 build 同步阶段读取 `MediaQuery`、主题等信息

## 5. 常用工具与命令（项目开发）

命令速查已整理在 `docs/FLUTTER_ENV_SETUP.md` 的「Flutter 常用命令速查」章节，这里只列项目最常用的：

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter run -d chrome
fvm flutter run -d macos
```

## 5.1 主题与资源（本项目）

- 全局主题：`lib/src/app.dart`（`ThemeData` / `colorSchemeSeed`）
- 渐变背景：`lib/src/shell/app_shell.dart`（Shell 层 `DecoratedBox` + `AppGradients`）
- 海报图（首页）：`lib/src/features/home/presentation/home_screen.dart`
  - 资源位置：`assets/images/poster.png`（没有该文件时会用渐变占位）
  - 资源声明：`pubspec.yaml` 的 `flutter/assets`

## 6. 常用组件/Widget 与使用场景

这部分不是百科，只记录项目里经常会遇到的选择题。

### 6.1 黑板/画布相关

- `Listener`：拿到原始指针事件（鼠标/触控）更完整，适合画板输入
- `GestureDetector`：手势语义更强（双击/长按等），但对高频点采样要谨慎
- `CustomPaint`/`Canvas`：绘制路径、形状、背景网格；高频绘制核心
- `InteractiveViewer`：快速实现缩放/平移（内部基于变换矩阵）
- `RepaintBoundary`：用于局部重绘隔离，也用于导出图片（`toImage()`）

### 6.2 布局与叠层

- `Stack`/`Positioned`：叠加工具栏、浮层提示（例如页数提示）
- `Align`：右侧工具条、角落按钮对齐

## 7. 平台工程速查

### 7.1 Web（`web/`）

- 入口页面：`web/index.html`（`<base href>`、标题、meta、脚本）
- PWA 配置：`web/manifest.json`（name/theme_color/icons/maskable）
- 图标：`web/favicon.png`、`web/icons/*`

### 7.2 macOS（`macos/`）

`macos/` 是 Flutter 的 macOS 桌面端原生壳工程（Xcode 构建/签名/打包时使用）。常用文件：

- 工程入口：`macos/Runner.xcworkspace`
  - 使用场景：用 Xcode 调试/构建 macOS 应用（运行、断点、签名、打包）。
  - 常见操作：改原生代码或排查原生构建问题时打开；一般优先打开 `.xcworkspace`。
- 原生入口与窗口：`macos/Runner/AppDelegate.swift`、`macos/Runner/MainFlutterWindow.swift`
  - 使用场景：接入 macOS 原生能力或处理应用生命周期（启动/激活/窗口行为/菜单等）。
  - 常见操作：原生菜单/快捷键、窗口策略、MethodChannel 入口、系统事件回调。
- 应用信息与权限声明：`macos/Runner/Info.plist`
  - 使用场景：配置应用基础信息与权限说明文案（系统弹窗会展示）。
  - 常见配置：`CFBundleDisplayName`、URL Scheme、相机/麦克风/定位等 Usage Description（按需）。
- 构建配置：`macos/Runner/Configs/*.xcconfig`（Debug/Release/AppInfo 等）
  - 使用场景：集中管理构建参数，减少在 Xcode UI 里手点造成的不一致。
  - 常见配置：Bundle Identifier、版本号、产品名、编译选项；区分 Debug/Release 的参数。
- 沙盒与权限能力：`macos/Runner/DebugProfile.entitlements`、`macos/Runner/Release.entitlements`
  - 使用场景：控制沙盒能力（签名/分发/上架相关）。
  - 常见配置：App Sandbox、网络访问、文件读写范围、Keychain、硬件能力（按需）。
- 应用图标：`macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
  - 使用场景：配置 macOS 应用图标与尺寸资源。
  - 常见操作：替换 `app_icon_*.png` 并保持尺寸/命名一致。
- Flutter 注入配置：`macos/Flutter/Flutter-Debug.xcconfig`、`macos/Flutter/Flutter-Release.xcconfig`
  - 使用场景：Flutter 工具链注入给 Xcode 的构建参数（引擎/产物/搜索路径等）。
  - 常见操作：一般不手改；构建异常优先尝试 `flutter clean`、重新构建。
- 插件注册（自动生成）：`macos/Flutter/GeneratedPluginRegistrant.swift`
  - 使用场景：插件在 macOS 的注册入口。
  - 常见操作：不手改；插件变化后重新 `pub get`/构建会自动更新。
