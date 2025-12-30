import 'package:freezed_annotation/freezed_annotation.dart';

part 'wb_point.freezed.dart';
part 'wb_point.g.dart';

@freezed
class WBPoint with _$WBPoint {
  const factory WBPoint({
    required double x,
    required double y,
  }) = _WBPoint;

  factory WBPoint.fromJson(Map<String, Object?> json) =>
      _$WBPointFromJson(json);
}

