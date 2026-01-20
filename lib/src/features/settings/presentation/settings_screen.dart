import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:va_edu/src/features/settings/application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(context, '通用设置'),
          _buildThemeCard(context, settings, notifier),
          
          const SizedBox(height: 32),
          _buildSectionHeader(context, '导出设置'),
          _buildExportCard(context, settings, notifier),
          
          const SizedBox(height: 32),
          _buildSectionHeader(context, '黑板默认值'),
          _buildBlackboardCard(context, settings, notifier),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, settings, notifier) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildSettingTile(
              icon: Icons.brightness_6,
              title: '外观主题',
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('跟随系统'), icon: Icon(Icons.settings_brightness)),
                  ButtonSegment(value: ThemeMode.light, label: Text('浅色'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('深色'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) => notifier.setThemeMode(value.first),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, settings, notifier) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildSettingTile(
              icon: Icons.folder_open,
              title: '默认保存路径',
              subtitle: settings.exportPath.isEmpty ? '未设置（每次导出将询问路径）' : settings.exportPath,
              trailing: IconButton(
                icon: const Icon(Icons.edit_note_rounded),
                onPressed: () async {
                  final path = await FilePicker.platform.getDirectoryPath();
                  if (path != null) {
                    await notifier.setExportPath(path);
                  }
                },
              ),
              onTap: () async {
                 final path = await FilePicker.platform.getDirectoryPath();
                  if (path != null) {
                    await notifier.setExportPath(path);
                  }
              }
            ),
            if (settings.exportPath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton.icon(
                  onPressed: () => notifier.setExportPath(''),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('重置为交互模式'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlackboardCard(BuildContext context, settings, notifier) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildSettingTile(
              icon: Icons.line_weight,
              title: '初始画笔粗细',
              subtitle: '${settings.defaultPenWidth.toStringAsFixed(1)} px',
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: settings.defaultPenWidth,
                  min: 1.0,
                  max: 20.0,
                  onChanged: (v) => notifier.setDefaultPen(settings.defaultPenColor, v),
                ),
              ),
            ),
            const Divider(indent: 50),
            _buildSettingTile(
              icon: Icons.palette,
              title: '初始画笔颜色',
              trailing: Wrap(
                spacing: 8,
                children: [
                  0xFFFFFFFF, // White
                  0xFFFF4B4B, // Red
                  0xFF4BFF4B, // Green
                  0xFF4B4BFF, // Blue
                  0xFFFFFF4B, // Yellow
                ].map((c) => GestureDetector(
                  onTap: () => notifier.setDefaultPen(c, settings.defaultPenWidth),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: settings.defaultPenColor == c 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: settings.defaultPenColor == c ? 2 : 1,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return ListTile(
          leading: Icon(icon, size: 24, color: colorScheme.onSurface),
          title: Text(
            title, 
            style: TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            )
          ),
          subtitle: subtitle != null 
            ? Text(
                subtitle, 
                style: TextStyle(
                  fontSize: 13, 
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                )
              ) 
            : null,
          trailing: trailing,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        );
      }
    );
  }
}
