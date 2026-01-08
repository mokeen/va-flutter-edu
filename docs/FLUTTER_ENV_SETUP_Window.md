# Flutter 开发环境配置指南 (Windows)

这份文档用于在 Windows 10/11 上从零搭建 Flutter 开发环境，覆盖：

- Android（真机/模拟器）
- Windows 桌面端（Windows）
- Web（Chrome）

> 本项目建议统一使用 FVM 管理 Flutter 版本；文档中命令以 `fvm flutter ...` 举例。如果你不使用 FVM，把它替换成 `flutter` 即可。

---

## 0. 开始前你需要知道

- 最终以 `flutter doctor -v`（或 `fvm flutter doctor -v`）全绿为准。
- Windows 上常见“坑”集中在：PATH 冲突、长路径、Android SDK/License、Windows 桌面编译工具链（Visual Studio）。
- 国内网络环境如果遇到 `pub get` / `flutter doctor` 下载卡住，可跳到「常见问题」设置镜像。

---

## 1. 核心依赖安装

### 1.1 启用 Windows 长路径支持（推荐）

Flutter/Dart 依赖目录较深，Windows 默认的路径长度限制可能导致解压/拉取依赖失败。

1) 打开「本地组策略编辑器」(`gpedit.msc`)  
2) 路径：计算机配置 → 管理模板 → 系统 → 文件系统  
3) 启用：`启用 Win32 长路径`

如果你的系统没有 `gpedit.msc`（如部分家庭版），可用注册表方式：

1) 打开注册表编辑器 `regedit`  
2) 定位到：`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem`  
3) 设置 `LongPathsEnabled` 为 `1`（DWORD）  
4) 重启电脑

> 说明：完成 Git 安装后，建议再执行一次 `git config --global core.longpaths true`，避免仓库路径过长导致的异常。

### 1.2 安装 Git

安装 Git（二选一）：

- 方案 A：官网下载 Git for Windows 并安装（推荐）
  - <https://git-scm.com/download/win>
- 方案 B：使用 `winget`（如果系统已自带）

```powershell
winget install --id Git.Git -e
```

验证：

```powershell
git --version
```

建议开启 Git 长路径支持（只需一次）：

```powershell
git config --global core.longpaths true
```

### 1.3 获取 Flutter SDK（推荐使用 FVM）

在 Windows 上推荐用 FVM 做“版本隔离”，避免多个项目互相影响。

> 提示：FVM 本质是一个命令行工具，它依赖 Dart 运行时。最省事的方式是先装一次 Flutter（手动方式），拿到 `dart`，再用 `dart pub global activate fvm` 安装 FVM，然后交给 FVM 管理 Flutter 版本。

#### 方案 A：先装 Flutter（手动）→ 再安装/切换到 FVM（推荐）

##### Step 1：下载并解压 Flutter

1) 打开官方安装页（Windows）：  
   <https://docs.flutter.dev/get-started/install/windows>
2) 下载 stable 版 zip  
3) 解压到一个“路径短且无空格/中文”的目录，例如：
   - `C:\src\flutter`
   - `D:\dev\flutter`

##### Step 2：配置 Flutter 到 PATH

把 `...\flutter\bin` 加到用户 PATH：

1) 打开：系统设置 → 系统 → 关于 → 高级系统设置  
2) 环境变量 → 用户变量 → Path → 编辑 → 新建  
3) 添加：`C:\src\flutter\bin`（按你的实际目录）

关闭并重新打开终端后验证：

```powershell
flutter --version
where.exe flutter
```

##### Step 3：安装 FVM

```powershell
dart pub global activate fvm
```

把 Dart 全局可执行目录加到 PATH（非常关键）：

- 路径通常是：`C:\Users\<你的用户名>\AppData\Local\Pub\Cache\bin`

验证：

```powershell
fvm --version
where.exe fvm
```

##### Step 4：用 FVM 安装并设置 Flutter

```powershell
fvm install stable
fvm global stable
```

把 FVM 的默认 Flutter 加到 PATH（建议放在 Flutter 手动路径之前，避免冲突）：

- `C:\Users\<你的用户名>\fvm\default\bin`

重新打开终端验证：

```powershell
flutter --version
where.exe flutter
```

> 如果 `where.exe flutter` 显示多个路径，优先确保 `...\fvm\default\bin\flutter` 排在最前面；否则可能出现“看起来装对了，但实际跑的是另一个 Flutter”的问题。

#### 方案 B：只用手动 Flutter（不启用 FVM）

如果你暂时不想引入版本管理工具，直接用官方手动安装即可：

- 下载并解压 Flutter（同上）
- 配置 `...\flutter\bin` 到 PATH
- 后续统一用 `flutter ...` 命令

### 1.4 FVM 常用命令与最佳实践

- 给项目指定版本（在项目根目录）：

```powershell
cd path\to\project
fvm use stable
```

这会在项目根目录生成 `.fvm/`。项目内推荐统一使用：

```powershell
fvm flutter pub get
fvm flutter run -d chrome
```

- 查看已安装版本：

```powershell
fvm list
```

- 安装特定版本：

```powershell
fvm install 3.19.0
```

- 移除某个版本：

```powershell
fvm remove 3.19.0
```

---

## 2. 平台支持配置

### 2.1 Android（真机/模拟器）

#### Step 1：安装 Android Studio

1) 下载并安装 Android Studio：  
   <https://developer.android.com/studio>
2) 首次打开按向导安装：Android SDK / Platform Tools / Emulator

#### Step 2：安装必要的 SDK 组件

打开 Android Studio → `Settings`：

- `Appearance & Behavior` → `System Settings` → `Android SDK`
  - 勾选一个稳定的 Android SDK Platform（建议较新的稳定版）
  - 确保安装：`Android SDK Platform-Tools`

#### Step 3：接受 Android licenses

```powershell
flutter doctor --android-licenses
```

#### Step 4：创建并启动模拟器（可选）

Android Studio → `Device Manager`：

1) `Create device`
2) 选择机型（如 Pixel）
3) 下载并选择一个系统镜像（建议 x86_64）
4) 启动模拟器

验证 Flutter 设备：

```powershell
flutter devices
```

> 真机调试：开启开发者选项 + USB 调试；部分机型需要安装厂商 USB Driver。

### 2.2 Web（Chrome）

1) 安装 Chrome：  
   <https://www.google.com/chrome/>
2) 启用 Web（通常默认已启用）：

```powershell
flutter config --enable-web
```

运行到 Web：

```powershell
flutter run -d chrome
```

> 画布/高频绘制场景建议用 CanvasKit 做性能与效果验证：  
> `flutter run -d chrome --web-renderer canvaskit`

### 2.3 Windows 桌面端（Windows）

Flutter Windows 桌面端依赖 Visual Studio 的 C++ 工具链（不是 VS Code）。

#### Step 1：安装 Visual Studio 2022（Community 即可）

下载并安装：  
<https://visualstudio.microsoft.com/vs/>

在 Visual Studio Installer 中勾选工作负载：

- `Desktop development with C++`（必选）

并在右侧“单个组件”确认包含（通常自动带上）：

- Windows 10/11 SDK
- MSVC v143（或更新）编译工具
- CMake tools（建议）

#### Step 2：启用 Windows desktop 支持

```powershell
flutter config --enable-windows-desktop
```

运行到 Windows：

```powershell
flutter run -d windows
```

---

## 3. IDE 开发工具配置（VS Code）

1) 安装 VS Code：  
   <https://code.visualstudio.com/>
2) 安装插件：
   - Flutter（会自动带 Dart）
   - Dart
   - Flutter Intl（可选）
   - Pubspec Assist（可选）

### 3.1 配合 FVM 使用 VS Code（推荐）

如果你使用 FVM，VS Code 可能需要明确 Flutter SDK 路径：

1) VS Code 设置中搜索：`dart.flutterSdkPaths`
2) 添加一项路径（示例）：
   - `C:\\Users\\<你的用户名>\\fvm\\versions`

> 小技巧：在项目根目录运行 `fvm use stable` 会生成 `.fvm/`，不少情况下 VS Code 会自动识别项目使用的 Flutter。

---

## 4. 环境自检

```powershell
flutter doctor -v
```

如果你使用的是项目绑定的版本：

```powershell
fvm flutter doctor -v
```

重点关注：

- `Flutter` / `Dart` 是否正常
- `Android toolchain` 是否缺 SDK/licenses
- `Chrome` 是否可用
- `Visual Studio` 是否被识别（做 Windows 桌面端必须）

---

## 5. 项目级运行与调试（va-edu）

在本项目里建议统一使用 FVM：

```powershell
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

运行：

```powershell
fvm flutter run -d chrome
fvm flutter run -d windows
```

黑板/画布场景在 Web 端调试时建议指定渲染器：

```powershell
fvm flutter run -d chrome --web-renderer canvaskit
```

> 说明：`--web-renderer` 是 `flutter run` 的参数；`flutter build web` 不提供该参数。

---

## 6. Flutter 常用命令速查

建议在本机与项目里统一使用 FVM（下文用 `fvm flutter` 举例；如果你不使用 FVM，把它替换成 `flutter` 即可）。

### 6.1 依赖管理（装包/更新/检查）

- 安装依赖：`fvm flutter pub get`
- 添加依赖：`fvm flutter pub add <package>`
- 移除依赖：`fvm flutter pub remove <package>`
- 升级依赖：`fvm flutter pub upgrade`
- 查看可升级依赖：`fvm flutter pub outdated`

### 6.2 运行与设备

- 环境检查：`fvm flutter doctor -v`
- 查看可用设备：`fvm flutter devices`
- 运行到 Web：`fvm flutter run -d chrome`
- 运行到 Windows：`fvm flutter run -d windows`
- Web 指定渲染器（画布场景建议 CanvasKit）：`fvm flutter run -d chrome --web-renderer canvaskit`

### 6.3 构建与打包

- 构建 Web：`fvm flutter build web`
- 构建 Windows（Debug）：`fvm flutter build windows --debug`
- 构建 Windows（Release）：`fvm flutter build windows --release`

### 6.4 质量检查与测试

- 静态分析：`fvm flutter analyze`
- 运行测试：`fvm flutter test`

### 6.5 代码生成（Riverpod / Freezed / JsonSerializable）

- 生成一次：`fvm flutter pub run build_runner build --delete-conflicting-outputs`
- 持续监听：`fvm flutter pub run build_runner watch --delete-conflicting-outputs`

### 6.6 常用排错

- 清理构建缓存：`fvm flutter clean`（之后通常需要再跑 `fvm flutter pub get`）
- 查看 Flutter/Dart 版本：`fvm flutter --version`

---

## 7. 常见问题（Troubleshooting）

### 7.1 `flutter` / `fvm` 命令找不到

- 检查 PATH 是否配置完成（新增 PATH 后需要重新打开终端）
- 用下面命令确认实际命令指向哪里：

```powershell
where.exe flutter
where.exe fvm
```

### 7.2 `where.exe flutter` 出现多个路径（版本冲突）

优先保证顺序：

1) `...\fvm\default\bin\flutter`（如果你使用 FVM）
2) 其他历史 Flutter 路径尽量从 PATH 移除或排到后面

### 7.3 `Android toolchain` 报错 / licenses 未接受

```powershell
flutter doctor --android-licenses
flutter doctor -v
```

如果仍报找不到 SDK，检查 Android Studio 的 SDK 安装位置，或在环境变量里设置 `ANDROID_SDK_ROOT`（一般不必手动设置，但遇到异常可用）。

### 7.4 国内网络 `pub get` 很慢 / 下载失败（可选）

可设置国内镜像（写入用户环境变量，重开终端生效）：

```cmd
setx PUB_HOSTED_URL https://pub.flutter-io.cn
setx FLUTTER_STORAGE_BASE_URL https://storage.flutter-io.cn
```

然后重试：

```powershell
flutter doctor
flutter pub get
```

> 如果你在公司网络有代理/证书拦截，可能还需要额外配置代理或关掉拦截；以 `flutter doctor -v` 的报错信息为准排查。
