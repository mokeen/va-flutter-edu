import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('预留：主题、快捷键、导出设置、画笔默认值等。'),
      ),
    );
  }
}
