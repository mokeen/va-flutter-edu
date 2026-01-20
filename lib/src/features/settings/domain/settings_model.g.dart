// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      themeMode:
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.dark,
      exportPath: json['exportPath'] as String? ?? '',
      defaultPenColor: (json['defaultPenColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      defaultPenWidth: (json['defaultPenWidth'] as num?)?.toDouble() ?? 4.0,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'exportPath': instance.exportPath,
      'defaultPenColor': instance.defaultPenColor,
      'defaultPenWidth': instance.defaultPenWidth,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
