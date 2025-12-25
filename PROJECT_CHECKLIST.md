# Flutter 企业级项目工程化清单

在开始写代码之前，我们需要准备好以下基础设施。这些不仅仅是代码，而是支撑一个高质量工程的基石。

## 1. 核心技术栈选型

* **架构模式:** **Riverpod Architecture (Feature-First)**
  * *为什么:* 相比 BLoC 更轻量，相比 Provider 更安全（编译时检查），完美支持依赖注入。
  [codewithandrea](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
* **路由管理:** **GoRouter**
  * *为什么:* 官方推荐，支持深层链接 (Deep Linking)，API 设计符合直觉。
* **不可变数据:** **Freezed + JsonSerializable**
  * *为什么:* Dart 原生不支持 Data Class。Freezed 帮我们自动生成 `copyWith`, `==`, `toString`，避免低级错误。

## 2. 必装依赖包 (pubspec.yaml)

我们将使用以下“全明星”阵容：

### 状态管理与基础

* `flutter_riverpod`: 状态管理核心
* `riverpod_annotation`: 代码生成注解 (减少样板代码)
* `freezed_annotation`: 不可变数据注解
* `json_annotation`: JSON 序列化注解

### UI 与 路由

* `go_router`: 声明式路由
* `flutter_hooks`: React Hooks 的 Dart 实现 (可选，处理 Controller 声明周期神器)

### 工具与开发体验

* `build_runner`: 代码生成运行器 (Dev)
* `riverpod_generator`: Riverpod 代码生成器 (Dev)
* `freezed`: Freezed 代码生成器 (Dev)
* `json_serializable`: JSON 生成器 (Dev)
* `flutter_lints`: 官方推荐的代码规范 (Dev)

## 3. 工程化配置 (Configuration)

### 3.1 静态分析 (analysis_options.yaml)

我们要开启**最严格**的 lint 规则。

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_use_package_imports # 强制使用 package: 导入，避免相对路径混乱
    - prefer_const_constructors # 尽可能使用 const，优化性能
    - prefer_final_locals # 局部变量默认 final
    - unawaited_futures # 防止忘记 await 异步操作
```

### 3.2 依赖注入 (DI)

利用 Riverpod 的 `ProviderScope`，我们不需要 GetIt 这种额外的 Service Locator，Riverpod 本身就是最好的 DI 工具。

## 4. 目录结构预览 (Feature-First)

```text
lib/
├── src/
│   ├── app.dart              # MaterialApp 配置 (Theme, Router)
│   ├── routing/              # 路由配置 (GoRouter)
│   ├── constants/            # 全局常量 (Colors, Styles)
│   ├── utils/                # 通用工具 (Logger, Extensions)
│   └── features/             # === 核心业务 ===
│       ├── authentication/   # 认证模块 (登录/注册)
│       ├── whiteboard/       # 白板模块
│       │   ├── domain/       # 实体 (Point, Stroke)
│       │   ├── data/         # 仓库 (WhiteboardRepository)
│       │   ├── application/  # 逻辑 (WhiteboardController)
│       │   └── presentation/ # UI (WhiteboardScreen, DrawingCanvas)
│       └── settings/         # 设置模块
└── main.dart                 # 程序入口
```

## 5. 待办事项 (Next Steps)

当你消化完环境配置后，我们将按以下顺序施工：

1. **脚手架搭建:** 创建项目，清理默认代码。
2. **依赖注入:** 修改 `pubspec.yaml`，安装上述包。
3. **规范落地:** 配置 `analysis_options.yaml`。
4. **架构铺设:** 创建文件夹结构。
5. **Hello World 2.0:** 用 Riverpod + GoRouter 跑通一个最简单的页面。
