# Flutter 开发常识手册

这份文档只讲 Flutter/Dart 的通用开发常识与常见选择题，尽量保持长期稳定；项目相关的入口、路由、主题、资源、里程碑等信息，请写到 `docs/VA_EDU_DEV_LOG.md`。

## 文档导航

- 环境配置：`docs/FLUTTER_ENV_SETUP.md`
- 项目开发记录：`docs/VA_EDU_DEV_LOG.md`
- 项目入口与运行：`README.md`

---

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
│       └── <feature>/        # 任意业务模块
│           ├── domain/       # 实体与纯模型（可序列化、可测试）
│           ├── data/         # 仓库/数据源（本地存储/网络等）
│           ├── application/  # 业务逻辑与状态（用例/命令/状态机）
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

常用用法约定：

- 读状态：`ref.watch(xxxProvider)`
- 调用命令：`ref.read(xxxProvider.notifier).method()`

### 2.2 路由

- 使用 `go_router` 集中管理路由表（路径、参数、重定向等）
- 约定：尽量使用声明式路由（路径、参数、重定向逻辑集中管理）
- 多 Tab 场景常用：`StatefulShellRoute.indexedStack`（每个 Tab 独立导航栈）

### 2.3 不可变数据与序列化

- 使用 `freezed` + `json_serializable`（`freezed_annotation`/`json_annotation`）
- 约定：生成文件（`*.freezed.dart`/`*.g.dart`）不手改

### 2.4 静态分析

在 `analysis_options.yaml` 启用更严格的 lint（例如 `always_use_package_imports`）。

## 3. 依赖与代码生成

### 3.1 常用依赖（通用示例）

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

常见用法：

```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
```

## 4. Flutter 开发常识（精简版）

这一章面向“初学者 / Web 开发者”：不假设你会 Flutter 或 Dart，只讲到“能看懂项目、能自己写出第一版页面/交互”为止。

建议阅读顺序：按 4.0 → 4.1 → 4.2 … 递进；遇到报错就回到对应小节查关键字。

### 4.0 你需要先建立的 3 个心智模型

#### 模型 A：声明式 UI（像 React）

- 你写的不是“命令式地去摆控件”，而是“描述当前状态下 UI 应该长什么样”。
- 当状态变化时，Flutter 会重新执行 `build()`，生成新的 Widget 树，再高效地更新界面。

#### 模型 B：布局是“约束传递”（像 CSS 但规则更严格）

- 父组件给子组件约束（最小/最大宽高），子组件在约束内决定自己的尺寸。
- 绝大多数布局问题（溢出/不占满）都能用“约束是否合理”解释清楚。

#### 模型 C：一切都是 Widget（像 DOM 节点）

- `Text`/`Padding`/`Row`/`Column`/`Container` 都是 Widget。
- 页面就是一个 Widget 树：从 `MaterialApp` → `Scaffold` → `body` → ……

### 4.1 Dart（只学够写 UI 的那部分）

#### 变量与常量（高频）

- `var`：自动推断类型（新手可用，但别滥用）
- `final`：运行时常量（值只赋一次）
- `const`：编译期常量（更严格，常见报错是 “isn't a const constructor”）

#### 空安全（高频）

- `T?`：可能为空
- `!`：我确定它不为空（用错会崩）
- `??`：为空就用默认值

#### 函数/回调（高频）

- `() {}`：函数体
- `() => expr`：单表达式写法（语法糖）
- `VoidCallback`：无参无返回的回调类型（常见于按钮点击）

### 4.2 Flutter 应用从哪启动（你在项目里能对应上）

- `lib/main.dart`：入口，通常会 `runApp(...)`
- `MaterialApp` / `MaterialApp.router`：整个 App 的根（主题、路由都在这里接入）
- `build(BuildContext context)`：每个 Widget 输出 UI 的地方（类似 React 的 render）

### 4.3 布局入门（先掌握 10 个 Widget 就能做 80% 页面）

对照 Web：

- `Padding` ≈ CSS padding
- `SizedBox` ≈ 固定宽高/占位
- `Container/DecoratedBox` ≈ 一个可设置背景/边框的 div
- `Row/Column` ≈ flex row/column
- `Expanded` ≈ flex: 1（吃掉剩余空间）
- `Stack/Positioned` ≈ position: relative/absolute

**新手最常踩坑：Row/Column 不会自动“撑满剩余空间”**：

- 想让子组件占满剩余空间：用 `Expanded(child: ...)`
- 想让页面能滚动：用 `SingleChildScrollView` 或 `ListView`
- 遇到 overflow：先检查有没有该加 `Expanded` 或滚动容器

### 4.4 Scaffold 是什么（为什么很多页面都用它）

你可以把 `Scaffold` 理解为“Material 风格页面的标准骨架”，它提供了常用槽位与能力：

- `body`：页面主体（你的画布一般在这里）
- `appBar`/`bottomNavigationBar`/`drawer`：常见页面结构
- `SnackBar`（通过 `ScaffoldMessenger`）：提示信息的宿主
- 更易和 SafeArea、主题等配合

### 4.5 Widget、Element、RenderObject（了解即可，不用死记）

- `Widget`：配置（不可变）
- `Element`：运行时实例（把 Widget 挂到树上）
- `RenderObject`：真正负责布局与绘制（渲染层）

理解这三个层次，有助于你在做黑板这种高频绘制场景时选择正确的组件（例如 `CustomPaint`）。

### 4.6 Stateless / Stateful / Hooks（什么时候用哪个）

- `StatelessWidget`：纯展示，数据由外部驱动
- `StatefulWidget`：需要生命周期管理（init/dispose）时使用
- Hooks：用函数式方式管理资源与副作用，减少样板代码（例如 `useEffect`/`useMemoized`/`useListenable`）

### 4.7 BuildContext 注意事项（新手必看）

一句话：`context` 只在“当前这个 Widget 还活着”时可靠；屏幕尺寸/主题等环境信息尽量在一次 `build` 里统一读出来用。

#### 4.7.1 为什么 `await` 之后不要直接用 `context`

你在按钮点击里写了 `await`（网络请求/延迟/文件读写）时，等待期间用户可能已经切走页面或页面被销毁；这时再用 `context` 去弹窗/跳转/提示就可能报错或无效。

做法：每次 `await` 之后，先判断一次：

```dart
await someAsyncWork();
if (!context.mounted) return;
// 这里开始再安全地用 context（showDialog / Navigator / SnackBar 等）
```

#### 4.7.2 为什么 `MediaQuery/Theme` 要在 build 里先读成变量

`MediaQuery`（屏幕尺寸/文字缩放等）和 `Theme` 都是“当前这次 build 的环境信息”。把它们在 `build` 开头读出来，后面统一用变量，能避免到处零散读取、也避免跨异步后读到不一致的环境。

```dart
@override
Widget build(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final theme = Theme.of(context);
  // 后面用 size / theme
  return Text('w=${size.width}', style: theme.textTheme.bodyMedium);
}
```

### 4.8 路由与依赖注入（概念）

- 路由使用 `go_router`，并通过 Riverpod Provider 注入到 `MaterialApp.router`
- `@riverpod` + `part '*.g.dart'`：会生成 `xxxProvider`（生成文件不手改）
- 你在 UI 里用 `ref.watch(xxxProvider)` 获取依赖（例如 `GoRouter`），这就是依赖注入的基本形态

## 5. 常用工具与命令（通用）

更完整的命令与环境说明请看：`docs/FLUTTER_ENV_SETUP.md`。这里仅保留“你经常会用到”的通用命令。

```bash
# 依赖
flutter pub get

# 运行（先用 flutter devices 看可用设备）
flutter run -d chrome
flutter run -d macos

# 静态检查与测试
flutter analyze
flutter test

# 格式化（纯 Dart 工具）
dart format .
```

如果项目用了代码生成（freezed/riverpod/json_serializable 等），会额外用到：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 6. 常用组件选择题（通用）

这部分只记录“什么时候用哪个”，避免背一堆 API。

### 6.1 输入与手势

- `Listener`：更底层，能拿到更完整的 PointerEvent（适合高频采样，例如画线/拖拽）
- `GestureDetector`：更语义化（点击/双击/长按/拖拽等），但在高频点采样场景可能不如 `Listener` 直接

### 6.2 绘制与性能

- `CustomPaint` + `CustomPainter`：自己用 `Canvas` 画（路径/形状/网格等），适合自定义画布
- `RepaintBoundary`：隔离重绘范围；也常用于导出图片（`toImage()`）
- `InteractiveViewer`：快速获得缩放/平移（适合“浏览模式”，复杂画板可后续替换为自定义相机）

### 6.3 叠层与定位

- `Stack`/`Positioned`：叠加浮层（例如工具栏、提示条）
- `Align`：简单的角落对齐（右下角按钮等）

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
