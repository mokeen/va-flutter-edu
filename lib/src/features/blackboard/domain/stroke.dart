import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:va_edu/src/features/blackboard/domain/wb_point.dart';

part 'stroke.freezed.dart';
part 'stroke.g.dart';

@freezed
class Stroke with _$Stroke {
  const factory Stroke({
    required String id,
    required int colorValue,
    required double width,
    required List<WBPoint> points,
  }) = _Stroke;

  factory Stroke.fromJson(Map<String, Object?> json) => _$StrokeFromJson(json);
}
