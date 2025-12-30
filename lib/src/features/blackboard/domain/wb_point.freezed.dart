// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wb_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WBPoint _$WBPointFromJson(Map<String, dynamic> json) {
  return _WBPoint.fromJson(json);
}

/// @nodoc
mixin _$WBPoint {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;

  /// Serializes this WBPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WBPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WBPointCopyWith<WBPoint> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WBPointCopyWith<$Res> {
  factory $WBPointCopyWith(WBPoint value, $Res Function(WBPoint) then) =
      _$WBPointCopyWithImpl<$Res, WBPoint>;
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class _$WBPointCopyWithImpl<$Res, $Val extends WBPoint>
    implements $WBPointCopyWith<$Res> {
  _$WBPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WBPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null}) {
    return _then(
      _value.copyWith(
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WBPointImplCopyWith<$Res> implements $WBPointCopyWith<$Res> {
  factory _$$WBPointImplCopyWith(
    _$WBPointImpl value,
    $Res Function(_$WBPointImpl) then,
  ) = __$$WBPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class __$$WBPointImplCopyWithImpl<$Res>
    extends _$WBPointCopyWithImpl<$Res, _$WBPointImpl>
    implements _$$WBPointImplCopyWith<$Res> {
  __$$WBPointImplCopyWithImpl(
    _$WBPointImpl _value,
    $Res Function(_$WBPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WBPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null}) {
    return _then(
      _$WBPointImpl(
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WBPointImpl implements _WBPoint {
  const _$WBPointImpl({required this.x, required this.y});

  factory _$WBPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$WBPointImplFromJson(json);

  @override
  final double x;
  @override
  final double y;

  @override
  String toString() {
    return 'WBPoint(x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WBPointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  /// Create a copy of WBPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WBPointImplCopyWith<_$WBPointImpl> get copyWith =>
      __$$WBPointImplCopyWithImpl<_$WBPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WBPointImplToJson(this);
  }
}

abstract class _WBPoint implements WBPoint {
  const factory _WBPoint({required final double x, required final double y}) =
      _$WBPointImpl;

  factory _WBPoint.fromJson(Map<String, dynamic> json) = _$WBPointImpl.fromJson;

  @override
  double get x;
  @override
  double get y;

  /// Create a copy of WBPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WBPointImplCopyWith<_$WBPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
