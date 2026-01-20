import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:va_edu/src/routing/app_router.dart';
import 'package:va_edu/src/features/settings/application/settings_controller.dart';

class VaEduApp extends ConsumerWidget {
  const VaEduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'VA Edu',
      themeMode: settings.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF38BDF8),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0EA5E9),
      ),
      routerConfig: router,
    );
  }
}
