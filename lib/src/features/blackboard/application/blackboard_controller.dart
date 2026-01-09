import 'package:flutter/material.dart';

class BlackboardController extends ChangeNotifier {
  final List<Offset> _currentStroke = [];
  final List<List<Offset>> _historyStrokes = [];
  final List<List<Offset>> _redoStrokes = [];

  List<Offset> get currentStroke => List.unmodifiable(_currentStroke);
  List<List<Offset>> get historyStrokes => List.unmodifiable(_historyStrokes);
  List<List<Offset>> get redoStrokes => List.unmodifiable(_redoStrokes);

  void startStroke(Offset point) {
    _currentStroke.clear();
    _currentStroke.add(point);
    notifyListeners();
  }

  void moveStroke(Offset point) {
    _currentStroke.add(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke.isNotEmpty) {
      _historyStrokes.add(List.from(_currentStroke));
      _currentStroke.clear();
      notifyListeners();
    }
  }

  void undo() {
    if (_historyStrokes.isNotEmpty) {
      _redoStrokes.add(List.from(_historyStrokes.last));
      _historyStrokes.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStrokes.isNotEmpty) {
      _historyStrokes.add(List.from(_redoStrokes.last));
      _redoStrokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _historyStrokes.clear();
    _redoStrokes.clear();
    notifyListeners();
  }
}