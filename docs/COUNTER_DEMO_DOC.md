# Counter Demo 说明（Local vs Riverpod 状态注入）

对应核心页面：`lib/src/features/counter/presentation/counter_screen.dart`

这份 Demo 的目的：把「同一个业务（计数）」用两套实现方式跑通，并且能在运行时切换：

- **Local 模板**：`StatefulWidget + setState`（状态只在组件内）
- **Riverpod 模板（状态注入）**：`StateNotifierProvider + ref.watch/read`（状态可跨页面共享）
- **切换时同步计数**：local ↔ riverpod 来回切，数字不跳变
- **外层联动**：当启用 Riverpod 时，`AppShell` 会展示计数角标（证明状态被“注入到更外层”）

---

## 1. Demo 行为说明（你会看到什么）

页面顶部是一个开关：

- 关闭：渲染 `CounterLocalTemplate`，计数只在当前模板内部变化
- 开启：渲染 `CounterRiverpodTemplate`，计数由全局 `counterProvider` 驱动
- 来回切换：会自动把当前计数同步到另一套实现（不丢值、不闪回 0）

同时在应用壳层（底部导航/侧边栏）：

- 关闭：计数器 Tab 不显示角标
- 开启：显示 `Badge(count)`，并随计数变化实时更新（`AppShell` 通过 provider 订阅）

## 2. 文件结构（各自负责什么）

- `lib/src/features/counter/presentation/counter_screen.dart`
  - 负责「开关 + 动态模板切换 + local↔riverpod 同步」的编排层（类似 Vue 动态组件的父组件）
- `lib/src/features/counter/presentation/widgets/counter_local_template.dart`
  - local 版本：用 `setState` 自己维护 `_count`
  - 接收 `initialCount`（从外部“注入初始值”）并通过 `onCountChanged` 把最新值上报给父组件
- `lib/src/features/counter/presentation/widgets/counter_riverpod_template.dart`
  - riverpod 版本：用 `ref.watch(counterProvider)` 读取计数；用 `ref.read(counterProvider.notifier)` 调用命令
- `lib/src/features/counter/application/counter_controller.dart`
  - 计数器领域逻辑（命令集合）：`inc/dec/reset/setCount`
  - 对外暴露 `counterProvider`（`StateNotifierProvider<CounterNotifier, int>`）
- `lib/src/features/counter/application/counter_feature_flags.dart`
  - 全局开关：`counterStateManagementEnabledProvider`（`StateProvider<bool>`）
- `lib/src/shell/app_shell.dart`
  - 读取 `counterStateManagementEnabledProvider` + `counterProvider`，决定是否展示角标以及角标内容

## 3. 我们的“状态注入”落点（Riverpod 从哪开始生效）

Riverpod 的“注入”入口是 `ProviderScope`：

- `lib/main.dart`：`runApp(const ProviderScope(child: VaEduApp()));`

只要 Widget 树被 `ProviderScope` 包住：

- 任意子树里都可以通过 `ConsumerWidget / ConsumerStatefulWidget` 拿到 `ref`
- `ref.watch(...)` 会建立订阅，状态变化时自动刷新 UI

## 4. 特殊组件怎么选（什么场景用哪个）

### 4.1 `StatefulWidget` / `setState`

适合：

- 状态只属于这个组件，离开页面就可以丢
- 不需要跨页面共享、不需要外层联动
- Demo/原型阶段快速验证 UI

对应：`CounterLocalTemplate`（`_count` 完全是内部状态）

### 4.2 `ConsumerWidget`（只用 ref，不用 setState）

适合：

- UI 只依赖 provider（订阅/展示），不需要在组件内部保存额外可变状态
- 事件里只需要调用命令（`ref.read(provider.notifier).xxx()`）

对应：`CounterRiverpodTemplate`、`AppShell`

### 4.3 `ConsumerStatefulWidget`（ref + setState 都要）

适合：

- 既要用 provider（注入/共享），又要维护一些“临时 UI 状态/缓存”（例如：动画、输入中间态、切换同步用的缓存值）

对应：`CounterScreen`（需要 `ref` 读写 provider，同时用 `setState` 保存 `lastCount`）

## 5. 状态如何读取/更新（watch vs read）

### 5.1 读取（建立订阅）：`ref.watch`

在 `build` 里使用，用于让 UI 随状态变化自动重建：

- `ref.watch(counterStateManagementEnabledProvider)` → 监听开关
- `ref.watch(counterProvider)` → 监听计数值

### 5.2 更新（触发命令/写值）：`ref.read`

在点击/回调里使用，用于“执行一次动作”，避免无意义订阅：

- `ref.read(counterProvider.notifier).inc()` / `.dec()` / `.reset()`
- `ref.read(counterProvider.notifier).setCount(lastCount)`（切换同步）
- `ref.read(counterStateManagementEnabledProvider.notifier).state = val`（写开关）

### 5.3 local 版更新：`setState`

`CounterLocalTemplate` 内部通过：

- `setState(() { _count++; })` 触发自身重建
- `widget.onCountChanged(_count)` 把最新值上报给父组件（用于切换同步）

## 6. 动态模板切换与计数同步（关键规则）

切换的唯一入口在 `CounterScreen.onEnabledChanged`：

- **local → riverpod（开启开关）**
  - 把 `lastCount` 写入 `counterProvider`：`setCount(lastCount)`
  - 再把 `counterStateManagementEnabledProvider` 置为 `true`，触发模板切换
- **riverpod → local（关闭开关）**
  - 读取 `counterProvider` 的当前值回填到 `lastCount`
  - 再把开关置为 `false`，触发渲染 local 模板，并把 `initialCount: lastCount` 传入

为保证 local 模板接到新的 `initialCount` 后能正确刷新：

- `CounterLocalTemplate.initState`：首次创建时用 `widget.initialCount` 初始化 `_count`
- `CounterLocalTemplate.didUpdateWidget`：当父组件传入的 `initialCount` 变化时，同步更新 `_count`
  - 这是必要的：Flutter 可能复用旧的 `State`，如果不处理，local 模板会显示旧值

## 7. 注意点（容易踩坑的地方）

- **单一数据源**：同一时刻只有一套实现是“权威状态”
  - 开启时以 `counterProvider` 为准；关闭时以 local `_count` 为准
  - `lastCount` 只是“桥接缓存”，避免切换时丢值
- **避免在 build 里改状态**：provider 写入/`setState` 只放在事件回调里
- **异步场景注意 mounted**：如果以后在点击里引入 `await`，再用 `context` 前要先 `if (!context.mounted) return;`

## 8. 我们的状态注入（本项目的推荐用法）

当某个功能需要「跨组件/跨页面共享」或「由外层壳层联动展示」时，推荐按这个套路落地：

1) 用 `StateProvider` 存“轻量开关/筛选条件”等简单可变值  
   - 例：`counterStateManagementEnabledProvider`（bool 开关）
2) 用 `StateNotifierProvider` 存“有多种操作的业务状态”  
   - 例：`counterProvider`（状态是 int，但操作有 inc/dec/reset/setCount）
3) UI 里遵循：`watch` 订阅、`read` 发命令  
   - 展示层（Template/Shell）尽量用 `ConsumerWidget`
4) 如果需要「兼容旧实现 / 渐进迁移」，用一个编排层做模板切换并做“状态同步”  
   - 例：`CounterScreen` 作为动态组件容器，保证来回切换数值不跳变

---

## 参考定位

- 计数器编排页：`lib/src/features/counter/presentation/counter_screen.dart`
- Riverpod 计数器模板：`lib/src/features/counter/presentation/widgets/counter_riverpod_template.dart`
- Local 计数器模板：`lib/src/features/counter/presentation/widgets/counter_local_template.dart`
- Provider 定义：`lib/src/features/counter/application/counter_controller.dart`
- 开关 Provider：`lib/src/features/counter/application/counter_feature_flags.dart`
- 壳层角标联动：`lib/src/shell/app_shell.dart`
