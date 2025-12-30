import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_tool.dart';
import 'package:va_edu/src/features/blackboard/domain/stroke.dart';

part 'blackboard_state.freezed.dart';

@freezed
class BlackboardState with _$BlackboardState {
  const factory BlackboardState({
    @Default([]) List<Stroke> strokes,
    Stroke? activeStroke,
    @Default(BlackboardTool.pen) BlackboardTool tool,
    @Default(0xFFFFFFFF) int strokeColorValue,
    @Default(3.0) double strokeWidth,
    @Default(1200.0) double pageHeight,
    @Default(50) int pageCount,
    @Default(2400.0) double pageWidth,
  }) = _BlackboardState;
}
