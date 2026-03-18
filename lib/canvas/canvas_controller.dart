import 'package:flutter/material.dart';
import '../brushes/brush_engine.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

/// Manages drawing state: committed strokes + the in-progress current stroke.
/// Also holds the active brush type, color, and theme index for touch event handling.
/// Extends ChangeNotifier so widgets can rebuild on change.
class CanvasController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  BrushType _activeBrushType = BrushType.marker;
  Color _activeColor = const Color(0xFFFF0000); // Default: Red

  // Independent theme indices for airbrush and pattern so switching between
  // them does not reset the other's selection.
  int _activeAirbrushThemeIndex = 0;
  int _activePatternThemeIndex = 0;
  int _activeEraserSizeIndex = 1; // default Medium (0=S, 1=M, 2=L)

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;
  BrushType get activeBrushType => _activeBrushType;
  Color get activeColor => _activeColor;

  /// The active sub-index for the currently selected brush:
  /// - airbrush: theme index (0–9)
  /// - pattern: theme index (0–9)
  /// - eraser: size index (0 = S, 1 = M, 2 = L)
  /// Returns 0 for color-based brushes (pencil, marker, splatter) — unused for those.
  int get activeThemeIndex {
    if (_activeBrushType == BrushType.airbrush) return _activeAirbrushThemeIndex;
    if (_activeBrushType == BrushType.pattern)  return _activePatternThemeIndex;
    if (_activeBrushType == BrushType.eraser)   return _activeEraserSizeIndex;
    return 0;
  }

  /// Begin a new stroke at [point].
  /// For airbrush/pattern/eraser, stamps the current theme/size index onto the stroke.
  /// For color-based brushes, themeIndex is null.
  void startStroke(BrushType type, Color color, Offset point) {
    final useTheme = _activeBrushType == BrushType.airbrush ||
        _activeBrushType == BrushType.pattern ||
        _activeBrushType == BrushType.eraser;
    _currentStroke = Stroke(
      type: type,
      color: color,
      points: [point],
      themeIndex: useTheme ? activeThemeIndex : null,
    );
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

  /// Set the sub-index for the currently active brush.
  /// For airbrush/pattern: theme index. For eraser: size index (0=S, 1=M, 2=L).
  void setActiveTheme(int index) {
    if (_activeBrushType == BrushType.airbrush) {
      _activeAirbrushThemeIndex = index;
    } else if (_activeBrushType == BrushType.pattern) {
      _activePatternThemeIndex = index;
    } else if (_activeBrushType == BrushType.eraser) {
      _activeEraserSizeIndex = index;
    }
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

  @override
  void dispose() {
    BrushEngine.disposeTileCache();
    super.dispose();
  }
}
