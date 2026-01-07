import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 计数器状态的全局 Provider（Riverpod 版本）。
///
/// - `ref.watch(counterProvider)` 读到的是 `int`（当前计数值）
/// - `ref.read(counterProvider.notifier)` 拿到的是 `CounterNotifier`（调用 inc/dec/reset）
///
/// 这里用 `StateNotifierProvider<CounterNotifier, int>` 的原因：
/// - 状态是 `int`，但操作不止一个（inc/dec/reset/setCount）
/// - 把“怎么改状态”的逻辑集中在 Notifier，UI 只负责触发动作
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) => CounterNotifier());

/// 计数器的“状态机/命令集合”。
///
/// `state` 是当前状态（这里是一个 `int`），每次修改 `state`，所有 watch 该 provider 的 UI 都会自动重建。
class CounterNotifier extends StateNotifier<int> {
  /// 初始计数值为 0。
  CounterNotifier(): super(0);

  /// 加 1。
  void inc() => state++;

  /// 减 1。
  void dec() => state--;

  /// 重置为 0（写成 if 是为了避免重复赋值导致不必要的通知/重建）。
  void reset() {
    if (state != 0) {
      state = 0;
    }
  }

  /// 把计数强制设置为指定值。
  ///
  /// 这个方法用于“local ↔ riverpod 模板切换时同步计数”：
  /// - local -> riverpod：把 local 的值 set 进 provider
  /// - riverpod -> local：读 provider 的值回填到 local
  void setCount(int value) => state = value;
}
