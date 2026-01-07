import 'package:flutter/material.dart';

/// Counter 示例页：用最少代码体验 StatefulWidget + setState。
class CounterLocalTemplate extends StatefulWidget {
  /// 组件构造函数：`key` 用于 Flutter 识别/复用 Widget（通常照写即可）。
  const CounterLocalTemplate({super.key, required this.initialCount, required this.onCountChanged});

  /// 外部传入的初始计数值（来自 CounterScreen 的缓存）。
  ///
  /// 用途：从 riverpod 切回 local 时，让 local 的 UI 显示与 riverpod 一致的数字。
  final int initialCount;

  /// 计数变化时的上报回调（把 local 的最新值通知给 CounterScreen）。
  ///
  /// 用途：从 local 切到 riverpod 时，CounterScreen 能拿到最新 localCount 做同步。
  final ValueChanged<int> onCountChanged;

  @override
  /// StatefulWidget 必须实现：返回该 Widget 对应的 State 对象。
  /// 这里的返回类型写成 `State<CounterLocalTemplate>`，避免把私有 State 类型暴露到公开 API。
  State<CounterLocalTemplate> createState() => _CounterLocalTemplateState();
}

/// State 类通常用私有命名（前缀 `_`），表示只在当前文件内使用。
class _CounterLocalTemplateState extends State<CounterLocalTemplate> {
  /// 计数值：放在 State 里，变化时通过 setState 触发刷新 UI。
  ///
  /// 这里用 `late` 是因为值来自 `widget.initialCount`，通常在 `initState` 里初始化更清晰。
  late int _count = 0;

  /// 点击按钮时调用：setState 会让 Flutter 重新执行 build()，从而更新界面上的数字。
  void _operationCounter(String mode) {
    setState(() {
      switch (mode) {
        case 'inc':
          _count++;
          break;
        case 'dec':
          _count--;
          break;
        case 'reset':
          if (_count != 0) {
            _count = 0;
          }
          break;
        default:
          break;
      }
    });
    // setState 后上报最新值给父组件（CounterScreen）。
    // 注意：这里不需要再 setState，一次 setState 就够。
    widget.onCountChanged(_count);
  }

  @override
  void initState() {
    super.initState();
    // 首次创建时，把外部 initialCount 注入到内部状态。
    _count = widget.initialCount;
  }

  @override
  void didUpdateWidget(covariant CounterLocalTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当父组件传入的新 initialCount 发生变化时（例如从 riverpod 切回 local），同步内部 _count。
    // 如果不做这一步，State 会被复用，_count 可能还是旧值。
    if (oldWidget.initialCount != widget.initialCount) {
      setState(() {
        _count = widget.initialCount;
      });
    }
  }

  @override
  /// build：描述“当前状态下 UI 应该长什么样”（声明式）。
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主体内容：居中展示提示文案 + 数字。
        Center(
          /// Center：把子组件放到屏幕中间。
          child: Column(
            /// Column：竖向排列子组件。
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '不启用：你已经按过这个按钮这么多次了',
                style: TextStyle(
                  color: Color.fromARGB(253, 182, 246, 4),
                  fontSize: 16,
                ),
              ),
              Text(
                '$_count',
                /// 从 Theme 里取预设字号样式（不需要你手写 fontSize）。
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2
                ),
              ),
            ],
          ),
        ),
        // 操作按钮层：用 Positioned 固定在右下角，实现“类似 floatingActionButton 的效果”。
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                direction: Axis.vertical,
                spacing: 12,
                children: [
                  FloatingActionButton(
                    /// onPressed：点击回调，触发计数 +1。
                    onPressed: () => _operationCounter('inc'),
                    tooltip: '点击加1',
                    child: const Icon(Icons.exposure_plus_1),
                  ),
                  FloatingActionButton(
                    onPressed: () => _operationCounter('dec'),
                    tooltip: '点击减1',
                    child: const Icon(Icons.exposure_minus_1),
                  ),
                  FloatingActionButton(
                    onPressed: () => _operationCounter('reset'),
                    tooltip: '重置',
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
