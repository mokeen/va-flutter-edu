import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:va_edu/src/features/counter/application/counter_controller.dart';
import 'package:va_edu/src/features/counter/application/counter_feature_flags.dart';
import 'package:va_edu/src/features/counter/presentation/widgets/counter_local_template.dart';
import 'package:va_edu/src/features/counter/presentation/widgets/counter_riverpod_template.dart';

/// Counter Demo 总页面：
///
/// - 顶部开关：选择启用/不启用 Riverpod（相当于“动态组件切换”）
/// - 下方区域：根据开关渲染 local 模板 或 riverpod 模板
/// - 切换时：同步两边的 count，保证数值不跳变
class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key});

  @override
  /// 返回对应的 State。因为要同时用到：
  /// - `ref.watch/read`（读写 provider）
  /// - `setState`（保存 localCount 缓存）
  /// 所以用 `ConsumerStatefulWidget + ConsumerState` 组合。
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  /// 切换开关的回调：这里是“同步发生的唯一入口”。
  ///
  /// 规则（当前的设计）：
  /// - 开启（local -> riverpod）：把 local 的 lastCount 写进 provider
  /// - 关闭（riverpod -> local）：把 provider 的当前值读出来回填给 local
  void onEnabledChanged (bool val) {
    if (val) {
      // local -> riverpod：把 local 缓存值写入 provider，让 riverpod 模板一显示就用到正确计数。
      ref.read(counterProvider.notifier).setCount(lastCount);
    } else {
      // riverpod -> local：把 provider 的值回填到 localCount。
      // 这里要用 setState，否则 localCount 变化不会触发 CounterScreen 重建。
      setState(() {
        lastCount = ref.read(counterProvider);
      });
    }
    // 最后更新“启用状态管理”的开关（这个 provider 会驱动模板切换）。
    ref.read(counterStateManagementEnabledProvider.notifier).state = val;
  }

  /// local 模板的“最近一次计数值”缓存。
  ///
  /// 作用：
  /// - local -> riverpod 时：作为 setCount 的输入
  /// - riverpod -> local 时：作为 local 模板 initialCount 的输入
  int lastCount = 0;

  /// local 模板每次计数变化都会回调到这里。
  /// 必须 setState：让 CounterScreen 能拿到最新 lastCount（用于切换同步）。
  void onCountChanged(int v) {
    setState(() {
      lastCount = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听开关：改变时会触发 CounterScreen 重建，从而切换模板。
    final enabled = ref.watch(counterStateManagementEnabledProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('官方计数器Demo'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(32),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: (
              Text('区分两种场景：启用/不启用Riverpod')
            ),
          ),
        ),
      ),
      body: (
        Column(
          children: [
            const SizedBox(height: 36),
            Align(
              alignment: AlignmentGeometry.center,
              child: (
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: (
                    SwitchListTile(
                      title: const Text('是否启用Riverpod'),
                      // Switch 的 value 绑定 enabled，保证 UI 与 provider 状态一致。
                      value: enabled, 
                      // onChanged 里做“同步 + 切换”。
                      onChanged: onEnabledChanged
                    )
                  ),
                )
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: (
                // 动态模板切换（类似 Vue 的动态组件）：enabled 决定渲染哪一套实现。
                enabled ? const CounterRiverpodTemplate() : CounterLocalTemplate(initialCount: lastCount, onCountChanged: onCountChanged,)
              ),
            )
          ],
        )
      ),
    );
  }
}
