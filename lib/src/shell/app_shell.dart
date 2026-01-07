import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:va_edu/src/features/counter/application/counter_controller.dart';
import 'package:va_edu/src/features/counter/application/counter_feature_flags.dart';

import 'package:va_edu/src/theme/app_gradients.dart';

/// AppShell：应用的“壳层”（承载侧边栏/底部导航 + 渐变背景 + 子路由）。
///
/// 这里改成 `ConsumerWidget` 的原因：
/// - 需要在 Shell 层读取 Provider（enabled 开关 + counter 数值）
/// - 用于控制：菜单角标 Badge 的显示与内容（动态更新）
class AppShell extends ConsumerWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  /// GoRouter 的 StatefulShell：每个 tab 有独立导航栈，切换 tab 时能保留各自的路由状态。
  final StatefulNavigationShell navigationShell;

  /// 切换 tab 的统一入口。
  ///
  /// `initialLocation` 的含义：如果点的是当前 tab，则回到该 tab 的初始路由（类似“点一下回顶/回首页”）。
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 是否启用 Riverpod 计数器：决定“计数器 tab 是否显示角标”。
    final countProviderEnabled = ref.watch(counterStateManagementEnabledProvider);
    // 当前计数值：当启用时显示在 Badge 上（动态更新）。
    final count = ref.watch(counterProvider);

    // 简单的响应式布局：宽屏用 NavigationRail，窄屏用 NavigationBar。
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    // 底部导航（窄屏）。
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: '首页',
      ),
      const NavigationDestination(
        icon: Icon(Icons.draw_outlined),
        selectedIcon: Icon(Icons.draw),
        label: '黑板',
      ),
      NavigationDestination(
        // icon / selectedIcon 都做同样的 badge 包装，这样选中/未选中状态都一致显示角标。
        icon: countProviderEnabled ? Badge(
          // offset：相对默认右上角位置的偏移（dx>0 往右，dy<0 往上）。
          offset: const Offset(10, -4),
          // label：角标内容（这里直接显示 count）。
          label: Text('$count'),
          child: const Icon(Icons.add),
        ) : const Icon(Icons.add),
        selectedIcon: countProviderEnabled ? Badge(
          offset: const Offset(10, -4),
          label: Text('$count'),
          child: const Icon(Icons.add_box),
        ) : const Icon(Icons.add_box),
        label: '计数器'
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: '设置',
      ),
    ];

    // 侧边栏导航（宽屏）。
    final railDestinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('首页'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.draw_outlined),
        selectedIcon: Icon(Icons.draw),
        label: Text('黑板'),
      ),
      NavigationRailDestination(
        icon: countProviderEnabled ? Badge(
          offset: const Offset(10, -4),
          label: Text('$count'),
          child: const Icon(Icons.add),
        ) : const Icon(Icons.add),
        selectedIcon: countProviderEnabled ? Badge(
          offset: const Offset(10, -4),
          label: Text('$count'),
          child: const Icon(Icons.add_box),
        ) : const Icon(Icons.add_box),
        label: const Text('计数器')
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('设置'),
      ),
    ];

    if (useRail) {
      return DecoratedBox(
        // Shell 背景渐变（整个应用背景）。
        decoration: const BoxDecoration(gradient: AppGradients.aquaDark),
        child: Scaffold(
          // 透明让渐变透出来（否则 Scaffold 默认背景会盖住）。
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  // 半透明背景，保证图标对比度，同时让渐变可见。
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  labelType: NavigationRailLabelType.all,
                  destinations: railDestinations,
                ),
              ),
              const VerticalDivider(width: 1, color: Colors.white12),
              // Expanded：右侧内容区撑满剩余空间。
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.aquaDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // navigationShell 是 go_router 提供的“当前 tab 内容”。
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.black.withValues(alpha: 0.25),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: destinations,
        ),
      ),
    );
  }
}
