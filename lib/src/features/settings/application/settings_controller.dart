import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:va_edu/src/features/settings/domain/settings_model.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  static const _themeKey = 'settings_theme';
  static const _exportPathKey = 'settings_export_path';
  static const _penColorKey = 'settings_pen_color';
  static const _penWidthKey = 'settings_pen_width';

  @override
  AppSettings build() {
    // 初始状态，稍后在 main 中初始化 SharedPreferences
    return const AppSettings();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.dark.index;
    final exportPath = prefs.getString(_exportPathKey) ?? '';
    final penColor = prefs.getInt(_penColorKey) ?? 0xFFFFFFFF;
    final penWidth = prefs.getDouble(_penWidthKey) ?? 4.0;

    state = AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      exportPath: exportPath,
      defaultPenColor: penColor,
      defaultPenWidth: penWidth,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setExportPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exportPathKey, path);
    state = state.copyWith(exportPath: path);
  }

  Future<void> setDefaultPen(int color, double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_penColorKey, color);
    await prefs.setDouble(_penWidthKey, width);
    state = state.copyWith(defaultPenColor: color, defaultPenWidth: width);
  }
}
