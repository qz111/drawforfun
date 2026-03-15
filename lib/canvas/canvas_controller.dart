import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

/// Manages drawing state: committed strokes + the in-progress current stroke.
/// Also holds the active brush type and color for touch event handling.
/// Extends ChangeNotifier so widgets can rebuild on change.
class CanvasController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  BrushType _activeBrushType = BrushType.marker;
  Color _activeColor = const Color(0xFFFF0000); // Default: Red

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;
  BrushType get activeBrushType => _activeBrushType;
  Color get activeColor => _activeColor;

  /// Begin a new stroke at [point].
  void startStroke(BrushType type, Color color, Offset point) {
    _currentStroke = Stroke(type: type, color: color, points: [point]);
    notifyListeners();
  }

  /// Append [point] to the active stroke.
  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWithPoint(point);
    notifyListeners();
  }

  /// Commit the active stroke to the history list.
  void endStroke() {
    if (_currentStroke == null) return;
    _strokes.add(_currentStroke!);
    _currentStroke = null;
    notifyListeners();
  }

  /// Remove the most recently committed stroke.
  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  /// Remove all strokes and reset to blank canvas.
  void clear() {
    _strokes.clear();
    _currentStroke = null;
    notifyListeners();
  }

  /// Set the active brush type for new strokes.
  void setActiveBrush(BrushType type) {
    _activeBrushType = type;
    notifyListeners();
  }

  /// Set the active color for new strokes.
  void setActiveColor(Color color) {
    _activeColor = color;
    notifyListeners();
  }

  /// Returns all committed strokes serialized as a JSON-compatible list.
  List<Map<String, dynamic>> strokesToJson() =>
      _strokes.map((s) => s.toJson()).toList();

  /// Replaces the stroke history with [strokes] and notifies listeners.
  /// Clears any in-progress stroke.
  void loadStrokes(List<Stroke> strokes) {
    _strokes
      ..clear()
      ..addAll(strokes);
    _currentStroke = null;
    notifyListeners();
  }
}
