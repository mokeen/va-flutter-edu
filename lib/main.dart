import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:va_edu/src/app.dart';
import 'package:va_edu/src/features/settings/application/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  // 初始化设置
  await container.read(settingsControllerProvider.notifier).init();
  
  runApp(UncontrolledProviderScope(
    container: container,
    child: const VaEduApp(),
  ));
}
