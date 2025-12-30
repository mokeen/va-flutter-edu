import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:va_edu/src/features/blackboard/application/blackboard_state.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_tool.dart';
import 'package:va_edu/src/features/blackboard/domain/stroke.dart';
import 'package:va_edu/src/features/blackboard/domain/wb_point.dart';

part 'blackboard_controller.g.dart';

@riverpod
class BlackboardController extends _$BlackboardController {
  final List<_HistoryEntry> _undoStack = [];
  final List<_HistoryEntry> _redoStack = [];

  @override
  BlackboardState build() {
    return const BlackboardState();
  }

  void setTool(BlackboardTool tool) {
    state = state.copyWith(tool: tool);
  }

  void setStrokeColor(Color color) {
    state = state.copyWith(strokeColorValue: color.toARGB32());
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void startStroke(Offset worldPosition) {
    if (state.tool != BlackboardTool.pen) return;

    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    _redoStack.clear();
    state = state.copyWith(
      activeStroke: Stroke(
        id: nowId,
        colorValue: state.strokeColorValue,
        width: state.strokeWidth,
        points: [WBPoint(x: worldPosition.dx, y: worldPosition.dy)],
      ),
    );
  }

  void addPoint(Offset worldPosition) {
    final activeStroke = state.activeStroke;
    if (state.tool != BlackboardTool.pen || activeStroke == null) return;

    final points = List<WBPoint>.of(activeStroke.points)
      ..add(WBPoint(x: worldPosition.dx, y: worldPosition.dy));

    state = state.copyWith(activeStroke: activeStroke.copyWith(points: points));
  }

  void endStroke() {
    final activeStroke = state.activeStroke;
    if (activeStroke == null) return;

    if (activeStroke.points.length < 2) {
      state = state.copyWith(activeStroke: null);
      return;
    }

    _redoStack.clear();
    _undoStack.add(_HistoryAddStroke(activeStroke));
    state = state.copyWith(
      strokes: [...state.strokes, activeStroke],
      activeStroke: null,
    );
  }

  void eraseAt(Offset worldPosition, {double radius = 18}) {
    if (state.tool != BlackboardTool.eraser) return;

    final radiusSquared = radius * radius;

    int? hitIndex;
    for (var i = state.strokes.length - 1; i >= 0; i--) {
      final stroke = state.strokes[i];
      final didHit = stroke.points.any((p) {
        final dx = p.x - worldPosition.dx;
        final dy = p.y - worldPosition.dy;
        return (dx * dx) + (dy * dy) <= radiusSquared;
      });
      if (didHit) {
        hitIndex = i;
        break;
      }
    }

    if (hitIndex == null) return;

    final removed = state.strokes[hitIndex];
    final nextStrokes = List<Stroke>.of(state.strokes)..removeAt(hitIndex);

    _redoStack.clear();
    _undoStack.add(_HistoryRemoveStroke(index: hitIndex, stroke: removed));
    state = state.copyWith(
      strokes: nextStrokes,
    );
  }

  void undo() {
    if (state.activeStroke != null) {
      state = state.copyWith(activeStroke: null);
      return;
    }

    if (_undoStack.isEmpty) return;

    final entry = _undoStack.removeLast();
    switch (entry) {
      case _HistoryAddStroke(:final stroke):
        final next = List<Stroke>.of(state.strokes);
        final index = next.lastIndexWhere((s) => s.id == stroke.id);
        if (index == -1) return;
        next.removeAt(index);
        _redoStack.add(entry);
        state = state.copyWith(strokes: next);
        return;
      case _HistoryRemoveStroke(:final index, :final stroke):
        final next = List<Stroke>.of(state.strokes);
        final safeIndex = math.max(0, math.min(next.length, index));
        next.insert(safeIndex, stroke);
        _redoStack.add(entry);
        state = state.copyWith(strokes: next);
        return;
      case _HistoryClear(:final previousStrokes):
        _redoStack.add(entry);
        state = state.copyWith(strokes: previousStrokes);
        return;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    final entry = _redoStack.removeLast();
    switch (entry) {
      case _HistoryAddStroke(:final stroke):
        _undoStack.add(entry);
        state = state.copyWith(strokes: [...state.strokes, stroke]);
        return;
      case _HistoryRemoveStroke(:final index, :final stroke):
        final next = List<Stroke>.of(state.strokes);
        final currentIndex = next.indexWhere((s) => s.id == stroke.id);
        if (currentIndex != -1) {
          next.removeAt(currentIndex);
        } else {
          final safeIndex = math.max(0, math.min(next.length - 1, index));
          if (safeIndex >= 0 && safeIndex < next.length) {
            next.removeAt(safeIndex);
          }
        }
        _undoStack.add(entry);
        state = state.copyWith(strokes: next);
        return;
      case _HistoryClear():
        _undoStack.add(entry);
        state = state.copyWith(strokes: const []);
        return;
    }
  }

  void clear() {
    if (state.strokes.isEmpty && state.activeStroke == null) return;
    _redoStack.clear();
    _undoStack.add(_HistoryClear(previousStrokes: state.strokes));
    state = state.copyWith(
      strokes: const [],
      activeStroke: null,
    );
  }

  int clampPageIndex(double pageIndex) {
    return math.max(0, math.min(state.pageCount - 1, pageIndex.floor()));
  }
}

sealed class _HistoryEntry {}

final class _HistoryAddStroke extends _HistoryEntry {
  _HistoryAddStroke(this.stroke);
  final Stroke stroke;
}

final class _HistoryRemoveStroke extends _HistoryEntry {
  _HistoryRemoveStroke({required this.index, required this.stroke});
  final int index;
  final Stroke stroke;
}

final class _HistoryClear extends _HistoryEntry {
  _HistoryClear({required this.previousStrokes});
  final List<Stroke> previousStrokes;
}
