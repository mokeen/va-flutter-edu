// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stroke.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Stroke _$StrokeFromJson(Map<String, dynamic> json) {
  return _Stroke.fromJson(json);
}

/// @nodoc
mixin _$Stroke {
  String get id => throw _privateConstructorUsedError;
  int get colorValue => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  List<WBPoint> get points => throw _privateConstructorUsedError;

  /// Serializes this Stroke to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StrokeCopyWith<Stroke> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StrokeCopyWith<$Res> {
  factory $StrokeCopyWith(Stroke value, $Res Function(Stroke) then) =
      _$StrokeCopyWithImpl<$Res, Stroke>;
  @useResult
  $Res call({String id, int colorValue, double width, List<WBPoint> points});
}

/// @nodoc
class _$StrokeCopyWithImpl<$Res, $Val extends Stroke>
    implements $StrokeCopyWith<$Res> {
  _$StrokeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? colorValue = null,
    Object? width = null,
    Object? points = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            colorValue: null == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                      as int,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as double,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as List<WBPoint>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StrokeImplCopyWith<$Res> implements $StrokeCopyWith<$Res> {
  factory _$$StrokeImplCopyWith(
    _$StrokeImpl value,
    $Res Function(_$StrokeImpl) then,
  ) = __$$StrokeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, int colorValue, double width, List<WBPoint> points});
}

/// @nodoc
class __$$StrokeImplCopyWithImpl<$Res>
    extends _$StrokeCopyWithImpl<$Res, _$StrokeImpl>
    implements _$$StrokeImplCopyWith<$Res> {
  __$$StrokeImplCopyWithImpl(
    _$StrokeImpl _value,
    $Res Function(_$StrokeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? colorValue = null,
    Object? width = null,
    Object? points = null,
  }) {
    return _then(
      _$StrokeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        colorValue: null == colorValue
            ? _value.colorValue
            : colorValue // ignore: cast_nullable_to_non_nullable
                  as int,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as double,
        points: null == points
            ? _value._points
            : points // ignore: cast_nullable_to_non_nullable
                  as List<WBPoint>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StrokeImpl implements _Stroke {
  const _$StrokeImpl({
    required this.id,
    required this.colorValue,
    required this.width,
    required final List<WBPoint> points,
  }) : _points = points;

  factory _$StrokeImpl.fromJson(Map<String, dynamic> json) =>
      _$$StrokeImplFromJson(json);

  @override
  final String id;
  @override
  final int colorValue;
  @override
  final double width;
  final List<WBPoint> _points;
  @override
  List<WBPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  @override
  String toString() {
    return 'Stroke(id: $id, colorValue: $colorValue, width: $width, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StrokeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            (identical(other.width, width) || other.width == width) &&
            const DeepCollectionEquality().equals(other._points, _points));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    colorValue,
    width,
    const DeepCollectionEquality().hash(_points),
  );

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StrokeImplCopyWith<_$StrokeImpl> get copyWith =>
      __$$StrokeImplCopyWithImpl<_$StrokeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StrokeImplToJson(this);
  }
}

abstract class _Stroke implements Stroke {
  const factory _Stroke({
    required final String id,
    required final int colorValue,
    required final double width,
    required final List<WBPoint> points,
  }) = _$StrokeImpl;

  factory _Stroke.fromJson(Map<String, dynamic> json) = _$StrokeImpl.fromJson;

  @override
  String get id;
  @override
  int get colorValue;
  @override
  double get width;
  @override
  List<WBPoint> get points;

  /// Create a copy of Stroke
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StrokeImplCopyWith<_$StrokeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
