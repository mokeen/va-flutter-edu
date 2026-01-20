// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) {
  return _AppSettings.fromJson(json);
}

/// @nodoc
mixin _$AppSettings {
  ThemeMode get themeMode => throw _privateConstructorUsedError;
  String get exportPath => throw _privateConstructorUsedError;
  int get defaultPenColor => throw _privateConstructorUsedError;
  double get defaultPenWidth => throw _privateConstructorUsedError;

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
    AppSettings value,
    $Res Function(AppSettings) then,
  ) = _$AppSettingsCopyWithImpl<$Res, AppSettings>;
  @useResult
  $Res call({
    ThemeMode themeMode,
    String exportPath,
    int defaultPenColor,
    double defaultPenWidth,
  });
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res, $Val extends AppSettings>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? exportPath = null,
    Object? defaultPenColor = null,
    Object? defaultPenWidth = null,
  }) {
    return _then(
      _value.copyWith(
            themeMode: null == themeMode
                ? _value.themeMode
                : themeMode // ignore: cast_nullable_to_non_nullable
                      as ThemeMode,
            exportPath: null == exportPath
                ? _value.exportPath
                : exportPath // ignore: cast_nullable_to_non_nullable
                      as String,
            defaultPenColor: null == defaultPenColor
                ? _value.defaultPenColor
                : defaultPenColor // ignore: cast_nullable_to_non_nullable
                      as int,
            defaultPenWidth: null == defaultPenWidth
                ? _value.defaultPenWidth
                : defaultPenWidth // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppSettingsImplCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$$AppSettingsImplCopyWith(
    _$AppSettingsImpl value,
    $Res Function(_$AppSettingsImpl) then,
  ) = __$$AppSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ThemeMode themeMode,
    String exportPath,
    int defaultPenColor,
    double defaultPenWidth,
  });
}

/// @nodoc
class __$$AppSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsCopyWithImpl<$Res, _$AppSettingsImpl>
    implements _$$AppSettingsImplCopyWith<$Res> {
  __$$AppSettingsImplCopyWithImpl(
    _$AppSettingsImpl _value,
    $Res Function(_$AppSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? exportPath = null,
    Object? defaultPenColor = null,
    Object? defaultPenWidth = null,
  }) {
    return _then(
      _$AppSettingsImpl(
        themeMode: null == themeMode
            ? _value.themeMode
            : themeMode // ignore: cast_nullable_to_non_nullable
                  as ThemeMode,
        exportPath: null == exportPath
            ? _value.exportPath
            : exportPath // ignore: cast_nullable_to_non_nullable
                  as String,
        defaultPenColor: null == defaultPenColor
            ? _value.defaultPenColor
            : defaultPenColor // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultPenWidth: null == defaultPenWidth
            ? _value.defaultPenWidth
            : defaultPenWidth // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsImpl implements _AppSettings {
  const _$AppSettingsImpl({
    this.themeMode = ThemeMode.dark,
    this.exportPath = '',
    this.defaultPenColor = 0xFFFFFFFF,
    this.defaultPenWidth = 4.0,
  });

  factory _$AppSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsImplFromJson(json);

  @override
  @JsonKey()
  final ThemeMode themeMode;
  @override
  @JsonKey()
  final String exportPath;
  @override
  @JsonKey()
  final int defaultPenColor;
  @override
  @JsonKey()
  final double defaultPenWidth;

  @override
  String toString() {
    return 'AppSettings(themeMode: $themeMode, exportPath: $exportPath, defaultPenColor: $defaultPenColor, defaultPenWidth: $defaultPenWidth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.exportPath, exportPath) ||
                other.exportPath == exportPath) &&
            (identical(other.defaultPenColor, defaultPenColor) ||
                other.defaultPenColor == defaultPenColor) &&
            (identical(other.defaultPenWidth, defaultPenWidth) ||
                other.defaultPenWidth == defaultPenWidth));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    themeMode,
    exportPath,
    defaultPenColor,
    defaultPenWidth,
  );

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      __$$AppSettingsImplCopyWithImpl<_$AppSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsImplToJson(this);
  }
}

abstract class _AppSettings implements AppSettings {
  const factory _AppSettings({
    final ThemeMode themeMode,
    final String exportPath,
    final int defaultPenColor,
    final double defaultPenWidth,
  }) = _$AppSettingsImpl;

  factory _AppSettings.fromJson(Map<String, dynamic> json) =
      _$AppSettingsImpl.fromJson;

  @override
  ThemeMode get themeMode;
  @override
  String get exportPath;
  @override
  int get defaultPenColor;
  @override
  double get defaultPenWidth;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
