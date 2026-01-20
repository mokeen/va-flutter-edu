import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'settings_model.freezed.dart';
part 'settings_model.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.dark) ThemeMode themeMode,
    @Default('') String exportPath,
    @Default(0xFFFFFFFF) int defaultPenColor,
    @Default(4.0) double defaultPenWidth,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}
