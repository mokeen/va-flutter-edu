// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blackboard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BlackboardState {
  List<Stroke> get strokes => throw _privateConstructorUsedError;
  Stroke? get activeStroke => throw _privateConstructorUsedError;
  BlackboardTool get tool => throw _privateConstructorUsedError;
  int get strokeColorValue => throw _privateConstructorUsedError;
  double get strokeWidth => throw _privateConstructorUsedError;
  double get pageHeight => throw _privateConstructorUsedError;
  int get pageCount => throw _privateConstructorUsedError;
  double get pageWidth => throw _privateConstructorUsedError;

  /// Create a copy of BlackboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BlackboardStateCopyWith<BlackboardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BlackboardStateCopyWith<$Res> {
  factory $BlackboardStateCopyWith(
    BlackboardState value,
    $Res Function(BlackboardState) then,
  ) = _$BlackboardStateCopyWithImpl<$Res, BlackboardState>;
  @useResult
  $Res call({
    List<Stroke> strokes,
    Stroke? activeStroke,
    BlackboardTool tool,
    int strokeColorValue,
    double strokeWidth,
    double pageHeight,
    int pageCount,
    double pageWidth,
  });

  $StrokeCopyWith<$Res>? get activeStroke;
}

/// @nodoc
class _$BlackboardStateCopyWithImpl<$Res, $Val extends BlackboardState>
    implements $BlackboardStateCopyWith<$Res> {
  _$BlackboardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BlackboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokes = null,
    Object? activeStroke = freezed,
    Object? tool = null,
    Object? strokeColorValue = null,
    Object? strokeWidth = null,
    Object? pageHeight = null,
    Object? pageCount = null,
    Object? pageWidth = null,
  }) {
    return _then(
      _value.copyWith(
            strokes: null == strokes
                ? _value.strokes
                : strokes // ignore: cast_nullable_to_non_nullable
                      as List<Stroke>,
            activeStroke: freezed == activeStroke
                ? _value.activeStroke
                : activeStroke // ignore: cast_nullable_to_non_nullable
                      as Stroke?,
            tool: null == tool
                ? _value.tool
                : tool // ignore: cast_nullable_to_non_nullable
                      as BlackboardTool,
            strokeColorValue: null == strokeColorValue
                ? _value.strokeColorValue
                : strokeColorValue // ignore: cast_nullable_to_non_nullable
                      as int,
            strokeWidth: null == strokeWidth
                ? _value.strokeWidth
                : strokeWidth // ignore: cast_nullable_to_non_nullable
                      as double,
            pageHeight: null == pageHeight
                ? _value.pageHeight
                : pageHeight // ignore: cast_nullable_to_non_nullable
                      as double,
            pageCount: null == pageCount
                ? _value.pageCount
                : pageCount // ignore: cast_nullable_to_non_nullable
                      as int,
            pageWidth: null == pageWidth
                ? _value.pageWidth
                : pageWidth // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }

  /// Create a copy of BlackboardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StrokeCopyWith<$Res>? get activeStroke {
    if (_value.activeStroke == null) {
      return null;
    }

    return $StrokeCopyWith<$Res>(_value.activeStroke!, (value) {
      return _then(_value.copyWith(activeStroke: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BlackboardStateImplCopyWith<$Res>
    implements $BlackboardStateCopyWith<$Res> {
  factory _$$BlackboardStateImplCopyWith(
    _$BlackboardStateImpl value,
    $Res Function(_$BlackboardStateImpl) then,
  ) = __$$BlackboardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Stroke> strokes,
    Stroke? activeStroke,
    BlackboardTool tool,
    int strokeColorValue,
    double strokeWidth,
    double pageHeight,
    int pageCount,
    double pageWidth,
  });

  @override
  $StrokeCopyWith<$Res>? get activeStroke;
}

/// @nodoc
class __$$BlackboardStateImplCopyWithImpl<$Res>
    extends _$BlackboardStateCopyWithImpl<$Res, _$BlackboardStateImpl>
    implements _$$BlackboardStateImplCopyWith<$Res> {
  __$$BlackboardStateImplCopyWithImpl(
    _$BlackboardStateImpl _value,
    $Res Function(_$BlackboardStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BlackboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strokes = null,
    Object? activeStroke = freezed,
    Object? tool = null,
    Object? strokeColorValue = null,
    Object? strokeWidth = null,
    Object? pageHeight = null,
    Object? pageCount = null,
    Object? pageWidth = null,
  }) {
    return _then(
      _$BlackboardStateImpl(
        strokes: null == strokes
            ? _value._strokes
            : strokes // ignore: cast_nullable_to_non_nullable
                  as List<Stroke>,
        activeStroke: freezed == activeStroke
            ? _value.activeStroke
            : activeStroke // ignore: cast_nullable_to_non_nullable
                  as Stroke?,
        tool: null == tool
            ? _value.tool
            : tool // ignore: cast_nullable_to_non_nullable
                  as BlackboardTool,
        strokeColorValue: null == strokeColorValue
            ? _value.strokeColorValue
            : strokeColorValue // ignore: cast_nullable_to_non_nullable
                  as int,
        strokeWidth: null == strokeWidth
            ? _value.strokeWidth
            : strokeWidth // ignore: cast_nullable_to_non_nullable
                  as double,
        pageHeight: null == pageHeight
            ? _value.pageHeight
            : pageHeight // ignore: cast_nullable_to_non_nullable
                  as double,
        pageCount: null == pageCount
            ? _value.pageCount
            : pageCount // ignore: cast_nullable_to_non_nullable
                  as int,
        pageWidth: null == pageWidth
            ? _value.pageWidth
            : pageWidth // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$BlackboardStateImpl implements _BlackboardState {
  const _$BlackboardStateImpl({
    final List<Stroke> strokes = const [],
    this.activeStroke,
    this.tool = BlackboardTool.pen,
    this.strokeColorValue = 0xFFFFFFFF,
    this.strokeWidth = 3.0,
    this.pageHeight = 1200.0,
    this.pageCount = 50,
    this.pageWidth = 2400.0,
  }) : _strokes = strokes;

  final List<Stroke> _strokes;
  @override
  @JsonKey()
  List<Stroke> get strokes {
    if (_strokes is EqualUnmodifiableListView) return _strokes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_strokes);
  }

  @override
  final Stroke? activeStroke;
  @override
  @JsonKey()
  final BlackboardTool tool;
  @override
  @JsonKey()
  final int strokeColorValue;
  @override
  @JsonKey()
  final double strokeWidth;
  @override
  @JsonKey()
  final double pageHeight;
  @override
  @JsonKey()
  final int pageCount;
  @override
  @JsonKey()
  final double pageWidth;

  @override
  String toString() {
    return 'BlackboardState(strokes: $strokes, activeStroke: $activeStroke, tool: $tool, strokeColorValue: $strokeColorValue, strokeWidth: $strokeWidth, pageHeight: $pageHeight, pageCount: $pageCount, pageWidth: $pageWidth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BlackboardStateImpl &&
            const DeepCollectionEquality().equals(other._strokes, _strokes) &&
            (identical(other.activeStroke, activeStroke) ||
                other.activeStroke == activeStroke) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.strokeColorValue, strokeColorValue) ||
                other.strokeColorValue == strokeColorValue) &&
            (identical(other.strokeWidth, strokeWidth) ||
                other.strokeWidth == strokeWidth) &&
            (identical(other.pageHeight, pageHeight) ||
                other.pageHeight == pageHeight) &&
            (identical(other.pageCount, pageCount) ||
                other.pageCount == pageCount) &&
            (identical(other.pageWidth, pageWidth) ||
                other.pageWidth == pageWidth));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_strokes),
    activeStroke,
    tool,
    strokeColorValue,
    strokeWidth,
    pageHeight,
    pageCount,
    pageWidth,
  );

  /// Create a copy of BlackboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BlackboardStateImplCopyWith<_$BlackboardStateImpl> get copyWith =>
      __$$BlackboardStateImplCopyWithImpl<_$BlackboardStateImpl>(
        this,
        _$identity,
      );
}

abstract class _BlackboardState implements BlackboardState {
  const factory _BlackboardState({
    final List<Stroke> strokes,
    final Stroke? activeStroke,
    final BlackboardTool tool,
    final int strokeColorValue,
    final double strokeWidth,
    final double pageHeight,
    final int pageCount,
    final double pageWidth,
  }) = _$BlackboardStateImpl;

  @override
  List<Stroke> get strokes;
  @override
  Stroke? get activeStroke;
  @override
  BlackboardTool get tool;
  @override
  int get strokeColorValue;
  @override
  double get strokeWidth;
  @override
  double get pageHeight;
  @override
  int get pageCount;
  @override
  double get pageWidth;

  /// Create a copy of BlackboardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BlackboardStateImplCopyWith<_$BlackboardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
