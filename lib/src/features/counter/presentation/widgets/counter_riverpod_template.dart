import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:va_edu/src/features/counter/application/counter_controller.dart';

/// Riverpod 版本的计数器模板：
///
/// - `count` 来自 `counterProvider`（全局可共享）
/// - 按钮直接调用 `CounterNotifier` 的方法（inc/dec/reset）
///
/// 这里用 `ConsumerWidget` 的原因：模板内部不需要 `setState`，只需要 `ref.watch/read`。
class CounterRiverpodTemplate extends ConsumerWidget {
  const CounterRiverpodTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听计数值：每次 state 改变，这个模板会自动重建更新数字。
    final int count = ref.watch(counterProvider);
    return Stack(
      children: [
        // 主体内容：居中展示提示文案 + 数字。
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '启用：你已经按过这个按钮这么多次了',
                style: TextStyle(
                  color: Color.fromARGB(255, 237, 167, 4),
                  fontSize: 16,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2
                ),
              )
            ],
          ),
        ),
        // 操作按钮层：固定右下角（与 local 模板保持一致的交互位置）。
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                direction: Axis.vertical,
                spacing: 12,
                children: [
                  FloatingActionButton(
                    // 注意：这里传的是“函数引用”，不带括号；点击时才执行。
                    // read(notifier) 用于调用命令；watch 用于监听值。
                    onPressed: ref.read(counterProvider.notifier).inc,
                    tooltip: '点击加1',
                    child: const Icon(Icons.exposure_plus_1),
                  ),
                  FloatingActionButton(
                    onPressed: ref.read(counterProvider.notifier).dec,
                    tooltip: '点击减1',
                    child: const Icon(Icons.exposure_minus_1),
                  ),
                  FloatingActionButton(
                    onPressed: ref.read(counterProvider.notifier).reset,
                    tooltip: '点击重置',
                    child: const Icon(Icons.refresh),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
