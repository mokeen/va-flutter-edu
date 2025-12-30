import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:va_edu/src/theme/app_gradients.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    final destinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: '首页',
      ),
      NavigationDestination(
        icon: Icon(Icons.draw_outlined),
        selectedIcon: Icon(Icons.draw),
        label: '黑板',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: '设置',
      ),
    ];

    final railDestinations = const <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('首页'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.draw_outlined),
        selectedIcon: Icon(Icons.draw),
        label: Text('黑板'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('设置'),
      ),
    ];

    if (useRail) {
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.aquaDark),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  labelType: NavigationRailLabelType.all,
                  destinations: railDestinations,
                ),
              ),
              const VerticalDivider(width: 1, color: Colors.white12),
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
