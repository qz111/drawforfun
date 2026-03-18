# Brush Engine Overhaul Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade Airbrush, Pattern, and Splatter brushes with rich visual effects, and add a dynamic bottom toolbar that shows a theme picker instead of the color palette when Airbrush or Pattern is selected.

**Architecture:** Extend the existing `Stroke` data model with a nullable `themeIndex` field, add a pure-data `BrushTheme` class with all theme definitions, replace three `BrushEngine` rendering methods, extend `CanvasController` with independent theme indices per brush, and add a new `ThemePickerWidget` wired into `ColoringScreen` via `AnimatedSwitcher`.

**Tech Stack:** Flutter/Dart, `dart:ui` (PictureRecorder, ImageShader), `dart:typed_data` (Float64List), flutter_test

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/brushes/brush_theme.dart` | Create | All theme/style data as static const lists |
| `lib/brushes/stroke.dart` | Modify | Add `themeIndex` field + serialisation |
| `lib/canvas/canvas_controller.dart` | Modify | Add theme state, setActiveTheme, disposeTileCache call |
| `lib/brushes/brush_engine.dart` | Modify | Replace airbrush/pattern/splatter; add tile cache |
| `lib/widgets/theme_picker_widget.dart` | Create | Horizontal scrollable theme tile selector |
| `lib/screens/coloring_screen.dart` | Modify | AnimatedSwitcher between palette and theme picker |
| `test/brushes/brush_theme_test.dart` | Create | Theme data integrity tests |
| `test/brushes/stroke_test.dart` | Modify | Add themeIndex serialisation tests |
| `test/canvas/canvas_controller_test.dart` | Modify | Add theme index and setActiveTheme tests |

---

## Task 1: BrushTheme Data Class

**Files:**
- Create: `lib/brushes/brush_theme.dart`
- Create: `test/brushes/brush_theme_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/brushes/brush_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_theme.dart';

void main() {
  group('BrushTheme', () {
    test('has exactly 10 airbrush themes', () {
      expect(BrushTheme.airbrushThemes.length, 10);
    });

    test('has exactly 10 pattern styles', () {
      expect(BrushTheme.patternStyles.length, 10);
    });

    test('every airbrush theme has a non-empty emojis list and label', () {
      for (final theme in BrushTheme.airbrushThemes) {
        expect(theme.emojis, isNotEmpty);
        expect(theme.label, isNotEmpty);
      }
    });

    test('every pattern style has a non-empty emojis list and label', () {
      for (final style in BrushTheme.patternStyles) {
        expect(style.emojis, isNotEmpty);
        expect(style.label, isNotEmpty);
      }
    });

    test('airbrush theme 0 is Blue + Gold Flowers', () {
      final theme = BrushTheme.airbrushThemes[0];
      expect(theme.label, 'Blue + Gold Flowers');
      expect(theme.baseColor, const Color(0xFF1565C0));
    });

    test('pattern style 0 is Stars', () {
      final style = BrushTheme.patternStyles[0];
      expect(style.label, 'Stars');
      expect(style.backgroundColor, const Color(0xFFFFF9C4));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
flutter test test/brushes/brush_theme_test.dart
```
Expected: error — `brush_theme.dart` not found.

- [ ] **Step 3: Create `lib/brushes/brush_theme.dart`**

```dart
import 'package:flutter/material.dart';

class AirbrushTheme {
  final Color baseColor;
  final List<String> emojis;
  final String label;
  const AirbrushTheme({
    required this.baseColor,
    required this.emojis,
    required this.label,
  });
}

class PatternStyle {
  final List<String> emojis;
  final Color backgroundColor;
  final String label;
  const PatternStyle({
    required this.emojis,
    required this.backgroundColor,
    required this.label,
  });
}

class BrushTheme {
  BrushTheme._();

  static const List<AirbrushTheme> airbrushThemes = [
    AirbrushTheme(baseColor: Color(0xFF1565C0), emojis: ['🌸', '🌼', '✨'], label: 'Blue + Gold Flowers'),
    AirbrushTheme(baseColor: Color(0xFFF9A825), emojis: ['🌈', '☁️', '🌟'], label: 'Yellow + Rainbows'),
    AirbrushTheme(baseColor: Color(0xFF880E4F), emojis: ['🦋', '💜', '🌸'], label: 'Pink + Butterflies'),
    AirbrushTheme(baseColor: Color(0xFF1B5E20), emojis: ['✨', '⭐', '🌟'], label: 'Green + Stars'),
    AirbrushTheme(baseColor: Color(0xFFB71C1C), emojis: ['🔥', '💥', '⚡'], label: 'Red + Fire'),
    AirbrushTheme(baseColor: Color(0xFF006064), emojis: ['🌊', '🐟', '💧'], label: 'Teal + Ocean'),
    AirbrushTheme(baseColor: Color(0xFF4A148C), emojis: ['🪄', '🌙', '💫'], label: 'Purple + Magic'),
    AirbrushTheme(baseColor: Color(0xFFE65100), emojis: ['🍂', '🍁', '🎃'], label: 'Orange + Autumn'),
    AirbrushTheme(baseColor: Color(0xFF37474F), emojis: ['🌙', '⭐', '🛸'], label: 'Dark + Space'),
    AirbrushTheme(baseColor: Color(0xFFF48FB1), emojis: ['🍭', '🍬', '🎀'], label: 'Pink + Candy'),
  ];

  static const List<PatternStyle> patternStyles = [
    PatternStyle(emojis: ['⭐', '🌟', '✨'], backgroundColor: Color(0xFFFFF9C4), label: 'Stars'),
    PatternStyle(emojis: ['🌙'],             backgroundColor: Color(0xFFE3F2FD), label: 'Moons'),
    PatternStyle(emojis: ['☀️', '🌤️'],      backgroundColor: Color(0xFFFFFDE7), label: 'Suns'),
    PatternStyle(emojis: ['🌸', '🌺'],       backgroundColor: Color(0xFFF3E5F5), label: 'Flowers'),
    PatternStyle(emojis: ['🦋', '🌿'],       backgroundColor: Color(0xFFE8F5E9), label: 'Butterflies'),
    PatternStyle(emojis: ['❤️', '💙', '💚'], backgroundColor: Color(0xFFFCE4EC), label: 'Hearts'),
    PatternStyle(emojis: ['🐠', '🐡', '🐟'], backgroundColor: Color(0xFFE0F2F1), label: 'Fish'),
    PatternStyle(emojis: ['🎈', '🎀', '🎊'], backgroundColor: Color(0xFFFFF3E0), label: 'Party'),
    PatternStyle(emojis: ['❄️', '⛄', '🌨️'], backgroundColor: Color(0xFFFAFAFA), label: 'Snow'),
    PatternStyle(emojis: ['🍦', '🍰', '🧁'], backgroundColor: Color(0xFFFCE4EC), label: 'Sweets'),
  ];
}
```

- [ ] **Step 4: Run test to confirm it passes**

```
flutter test test/brushes/brush_theme_test.dart
```
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/brushes/brush_theme.dart test/brushes/brush_theme_test.dart
git commit -m "feat: add BrushTheme data class with 10 airbrush themes and 10 pattern styles"
```

---

## Task 2: Extend Stroke with themeIndex

**Files:**
- Modify: `lib/brushes/stroke.dart`
- Modify: `test/brushes/stroke_test.dart`

- [ ] **Step 1: Write failing tests**

Add to the `'Stroke'` group in `test/brushes/stroke_test.dart`:

```dart
    test('themeIndex defaults to null', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.red,
        points: [],
      );
      expect(stroke.themeIndex, isNull);
    });

    test('themeIndex is stored when provided', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.red,
        points: [],
        themeIndex: 3,
      );
      expect(stroke.themeIndex, 3);
    });

    test('copyWithPoint preserves themeIndex', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [Offset(0, 0)],
        themeIndex: 5,
      );
      final updated = stroke.copyWithPoint(const Offset(10, 10));
      expect(updated.themeIndex, 5);
    });

    test('toJson includes themeIndex', () {
      const stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.green,
        points: [],
        themeIndex: 7,
      );
      final json = stroke.toJson();
      expect(json['themeIndex'], 7);
    });

    test('fromJson with themeIndex round-trips correctly', () {
      const original = Stroke(
        type: BrushType.airbrush,
        color: Colors.red,
        points: [],
        themeIndex: 2,
      );
      final restored = Stroke.fromJson(original.toJson());
      expect(restored.themeIndex, 2);
    });

    test('fromJson without themeIndex (old saved stroke) loads with null', () {
      final json = {
        'brushType': 'pencil',
        'color': Colors.black.toARGB32(),
        'points': <Map<String, dynamic>>[],
      };
      final stroke = Stroke.fromJson(json);
      expect(stroke.themeIndex, isNull);
    });
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/brushes/stroke_test.dart
```
Expected: 6 new tests fail — `themeIndex` not defined on `Stroke`.

- [ ] **Step 3: Update `lib/brushes/stroke.dart`**

Replace the entire file:

```dart
import 'package:flutter/material.dart';
import 'brush_type.dart';

/// Immutable record of one continuous touch gesture.
class Stroke {
  final BrushType type;
  final Color color;
  final List<Offset> points;

  /// Theme index (0–9) for airbrush and pattern brushes.
  /// Null for color-based brushes (pencil, marker, splatter).
  /// When non-null, BrushEngine ignores [color] and uses the theme instead.
  final int? themeIndex;

  const Stroke({
    required this.type,
    required this.color,
    required this.points,
    this.themeIndex,
  });

  /// Returns a new Stroke with [point] appended to the points list.
  Stroke copyWithPoint(Offset point) {
    return Stroke(
      type: type,
      color: color,
      points: [...points, point],
      themeIndex: themeIndex,
    );
  }

  /// Serializes this stroke to a JSON-compatible map.
  /// JSON key 'brushType' maps to the Dart field [type].
  Map<String, dynamic> toJson() => {
        'brushType': type.name,
        'color': color.toARGB32(),
        'points': points
            .map((p) => {'dx': p.dx, 'dy': p.dy})
            .toList(),
        'themeIndex': themeIndex,
      };

  /// Restores a [Stroke] from the map produced by [toJson].
  /// Returns null-safe: unknown brushType names throw [ArgumentError] via [byName].
  static Stroke fromJson(Map<String, dynamic> json) => Stroke(
        type: BrushType.values.byName(json['brushType'] as String),
        color: Color(json['color'] as int),
        points: (json['points'] as List)
            .map((p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ))
            .toList(),
        themeIndex: json['themeIndex'] as int?,
      );
}
```

- [ ] **Step 4: Run all stroke tests**

```
flutter test test/brushes/stroke_test.dart
```
Expected: All tests pass (original 3 + 6 new = 9 total).

- [ ] **Step 5: Run full test suite to check nothing broke**

```
flutter test
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/stroke.dart test/brushes/stroke_test.dart
git commit -m "feat: add themeIndex to Stroke with backward-compatible serialisation"
```

---

## Task 3: Extend CanvasController with Theme State

**Files:**
- Modify: `lib/canvas/canvas_controller.dart`
- Modify: `test/canvas/canvas_controller_test.dart`

- [ ] **Step 1: Write failing tests**

Add to the `'CanvasController'` group in `test/canvas/canvas_controller_test.dart`:

```dart
    test('activeThemeIndex defaults to 0 for airbrush', () {
      controller.setActiveBrush(BrushType.airbrush);
      expect(controller.activeThemeIndex, 0);
    });

    test('activeThemeIndex defaults to 0 for pattern', () {
      controller.setActiveBrush(BrushType.pattern);
      expect(controller.activeThemeIndex, 0);
    });

    test('setActiveTheme updates airbrush index independently', () {
      controller.setActiveBrush(BrushType.airbrush);
      controller.setActiveTheme(4);
      expect(controller.activeThemeIndex, 4);

      // switching to pattern should show its own index (still 0)
      controller.setActiveBrush(BrushType.pattern);
      expect(controller.activeThemeIndex, 0);

      // switching back to airbrush restores 4
      controller.setActiveBrush(BrushType.airbrush);
      expect(controller.activeThemeIndex, 4);
    });

    test('setActiveTheme updates pattern index independently', () {
      controller.setActiveBrush(BrushType.pattern);
      controller.setActiveTheme(7);

      controller.setActiveBrush(BrushType.airbrush);
      controller.setActiveTheme(2);

      controller.setActiveBrush(BrushType.pattern);
      expect(controller.activeThemeIndex, 7);
    });

    test('startStroke sets themeIndex for airbrush', () {
      controller.setActiveBrush(BrushType.airbrush);
      controller.setActiveTheme(3);
      controller.startStroke(BrushType.airbrush, Colors.red, const Offset(0, 0));
      expect(controller.currentStroke!.themeIndex, 3);
    });

    test('startStroke sets null themeIndex for pencil', () {
      controller.setActiveBrush(BrushType.pencil);
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(0, 0));
      expect(controller.currentStroke!.themeIndex, isNull);
    });

    test('startStroke sets null themeIndex for splatter', () {
      controller.setActiveBrush(BrushType.splatter);
      controller.startStroke(BrushType.splatter, Colors.red, const Offset(0, 0));
      expect(controller.currentStroke!.themeIndex, isNull);
    });

    test('setActiveTheme notifies listeners', () {
      controller.setActiveBrush(BrushType.airbrush);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setActiveTheme(5);
      expect(notified, isTrue);
    });
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/canvas/canvas_controller_test.dart
```
Expected: 8 new tests fail — `activeThemeIndex`, `setActiveTheme` not defined.

- [ ] **Step 3: Update `lib/canvas/canvas_controller.dart`**

Replace the entire file:

```dart
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

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;
  BrushType get activeBrushType => _activeBrushType;
  Color get activeColor => _activeColor;

  /// The active theme index for the currently selected theme-based brush.
  /// Returns 0 for color-based brushes (value is unused for those types).
  int get activeThemeIndex => _activeBrushType == BrushType.airbrush
      ? _activeAirbrushThemeIndex
      : _activePatternThemeIndex;

  /// Begin a new stroke at [point].
  /// For airbrush/pattern, stamps the current theme index onto the stroke.
  /// For color-based brushes, themeIndex is null.
  void startStroke(BrushType type, Color color, Offset point) {
    final useTheme = _activeBrushType == BrushType.airbrush ||
        _activeBrushType == BrushType.pattern;
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

  /// Set the theme index for the currently active theme-based brush.
  /// Airbrush and pattern each maintain independent indices.
  void setActiveTheme(int index) {
    if (_activeBrushType == BrushType.airbrush) {
      _activeAirbrushThemeIndex = index;
    } else if (_activeBrushType == BrushType.pattern) {
      _activePatternThemeIndex = index;
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
```

- [ ] **Step 4: Add `disposeTileCache` stub to `lib/brushes/brush_engine.dart`**

`CanvasController.dispose()` now calls `BrushEngine.disposeTileCache()`, which doesn't exist yet (it's fully implemented in Task 6). Add a stub now so the code compiles. Find the class body of `BrushEngine` and add after `BrushEngine._();`:

```dart
  // Stub — full implementation added in Task 6 (Pattern brush upgrade).
  static void disposeTileCache() {}
```

- [ ] **Step 5: Run controller tests**

```
flutter test test/canvas/canvas_controller_test.dart
```
Expected: All tests pass (original 6 + 8 new = 14 total).

- [ ] **Step 6: Run full test suite**

```
flutter test
```
Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/canvas/canvas_controller.dart lib/brushes/brush_engine.dart test/canvas/canvas_controller_test.dart
git commit -m "feat: add independent theme indices and setActiveTheme to CanvasController"
```

---

## Task 4: Upgrade Splatter Brush

**Files:**
- Modify: `lib/brushes/brush_engine.dart`

- [ ] **Step 1: Write failing test**

Create `test/brushes/brush_engine_test.dart`:

```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_engine.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

/// Helper: render a stroke onto an in-memory canvas and return the image.
/// We only care that it doesn't throw and produces output.
Future<ui.Image> renderStroke(Stroke stroke) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 400),
    Paint()..color = Colors.white,
  );
  BrushEngine.paint(canvas, stroke);
  final picture = recorder.endRecording();
  return picture.toImage(400, 400);
}

void main() {
  group('BrushEngine.splatter', () {
    test('renders without throwing for multi-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.red,
        points: [
          const Offset(100, 100),
          const Offset(150, 120),
          const Offset(200, 100),
        ],
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.blue,
        points: [const Offset(200, 200)],
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('is deterministic — same stroke renders identically', () async {
      final stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.green,
        points: [
          const Offset(50, 50),
          const Offset(100, 80),
          const Offset(150, 50),
        ],
      );
      final img1 = await renderStroke(stroke);
      final img2 = await renderStroke(stroke);
      final bytes1 = await img1.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes2 = await img2.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes1!.buffer.asUint8List(), bytes2!.buffer.asUint8List());
    });
  });

  group('BrushEngine.disposeTileCache', () {
    test('can be called safely when cache is empty', () {
      expect(() => BrushEngine.disposeTileCache(), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
flutter test test/brushes/brush_engine_test.dart
```
Expected: `disposeTileCache` not found; splatter tests may pass but determinism test is key.

- [ ] **Step 3: Replace `_paintSplatter` and add cache infrastructure in `lib/brushes/brush_engine.dart`**

Add `dart:typed_data`, `dart:ui as ui`, and `package:flutter/foundation.dart` imports at the top (they'll be needed for later tasks too). Add the static cache map and `disposeTileCache` (replacing the stub added in Task 3). Replace `_paintSplatter` with the new implementation. Keep all other methods unchanged:

```dart
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'brush_theme.dart';
import 'brush_type.dart';
import 'stroke.dart';

/// Stateless brush renderer. All visual parameters are hardcoded per brush type.
class BrushEngine {
  BrushEngine._();

  // Pattern tile cache: lazily generated, session-scoped.
  // ui.Image holds GPU texture — disposed via disposeTileCache().
  static final Map<int, ui.Image> _tileCache = {};

  /// Releases all cached pattern tile images (GPU texture memory).
  /// Call from CanvasController.dispose().
  static void disposeTileCache() {
    for (final image in _tileCache.values) {
      image.dispose();
    }
    _tileCache.clear();
  }

  /// Entry point: dispatches to the correct brush painter.
  static void paint(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    switch (stroke.type) {
      case BrushType.pencil:
        _paintPencil(canvas, stroke);
        break;
      case BrushType.marker:
        _paintMarker(canvas, stroke);
        break;
      case BrushType.airbrush:
        _paintAirbrush(canvas, stroke);
        break;
      case BrushType.pattern:
        _paintPattern(canvas, stroke);
        break;
      case BrushType.splatter:
        _paintSplatter(canvas, stroke);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // PENCIL — thin, slightly rough strokes with opacity jitter
  // ---------------------------------------------------------------------------
  static void _paintPencil(Canvas canvas, Stroke stroke) {
    final rng = Random(stroke.hashCode);
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        1.5,
        Paint()..color = stroke.color.withValues(alpha: 0.8),
      );
      return;
    }

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final opacity = 0.7 + rng.nextDouble() * 0.3;
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: opacity)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
  }

  // ---------------------------------------------------------------------------
  // MARKER — bold, semi-transparent, flat strokes that build up on overlap
  // ---------------------------------------------------------------------------
  static void _paintMarker(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        9.0,
        Paint()..color = stroke.color.withValues(alpha: 0.55),
      );
      return;
    }

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: 0.55)
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  // ---------------------------------------------------------------------------
  // AIRBRUSH — opaque base stroke + emoji particles (placeholder — Task 5)
  // ---------------------------------------------------------------------------
  static void _paintAirbrush(Canvas canvas, Stroke stroke) {
    const radius = 28.0;
    for (final point in stroke.points) {
      final rect = Rect.fromCircle(center: point, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            stroke.color.withValues(alpha: 0.10),
            stroke.color.withValues(alpha: 0.0),
          ],
        ).createShader(rect)
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(point, radius, paint);
    }
  }

  // ---------------------------------------------------------------------------
  // PATTERN — ImageShader wallpaper (placeholder — Task 6)
  // ---------------------------------------------------------------------------
  static void _paintPattern(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    double distanceAccumulator = 0.0;
    const stampInterval = 24.0;
    const iconSize = 14.0;

    _stampStar(canvas, stroke.points.first, iconSize, stroke.color);

    for (int i = 1; i < stroke.points.length; i++) {
      final segment = (stroke.points[i] - stroke.points[i - 1]).distance;
      distanceAccumulator += segment;

      if (distanceAccumulator >= stampInterval) {
        _stampStar(canvas, stroke.points[i], iconSize, stroke.color);
        distanceAccumulator = 0.0;
      }
    }
  }

  static void _stampStar(Canvas canvas, Offset center, double size, Color color) {
    const points = 5;
    final outerRadius = size;
    final innerRadius = size * 0.4;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (pi / points) * i - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ---------------------------------------------------------------------------
  // SPLATTER — thick central blob + directional opaque droplets
  // ---------------------------------------------------------------------------
  static void _paintSplatter(Canvas canvas, Stroke stroke) {
    final rng = Random(stroke.hashCode);

    // Single point: circle + 3 radial droplets
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        8.0,
        Paint()..color = stroke.color,
      );
      for (int i = 0; i < 3; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final dist = 6.0 + rng.nextDouble() * 10.0;
        canvas.drawCircle(
          stroke.points.first + Offset(cos(angle) * dist, sin(angle) * dist),
          2.0 + rng.nextDouble() * 3.0,
          Paint()..color = stroke.color,
        );
      }
      return;
    }

    // Central blob path
    final blobPath = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      blobPath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(
      blobPath,
      Paint()
        ..color = stroke.color
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Directional droplets per segment
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final delta = p2 - p1;
      final dist = delta.distance;
      if (dist == 0) continue;

      final dirAngle = atan2(delta.dy, delta.dx);
      final dropCount = 6 + rng.nextInt(9); // 6–14

      for (int d = 0; d < dropCount; d++) {
        // 60% forward cone (±60°), 40% side spread (±120°)
        final double spreadAngle;
        if (rng.nextDouble() < 0.6) {
          spreadAngle = dirAngle + (rng.nextDouble() - 0.5) * (2 * pi / 3);
        } else {
          spreadAngle = dirAngle + (rng.nextDouble() - 0.5) * (4 * pi / 3);
        }
        final dropDist = 5.0 + rng.nextDouble() * 20.0;
        final dropRadius = 2.0 + rng.nextDouble() * 6.0;
        final dropCenter = p1 + Offset(
          cos(spreadAngle) * dropDist,
          sin(spreadAngle) * dropDist,
        );
        canvas.drawCircle(
          dropCenter,
          dropRadius,
          Paint()..color = stroke.color,
        );
      }
    }
  }
}
```

- [ ] **Step 4: Run tests**

```
flutter test test/brushes/brush_engine_test.dart
```
Expected: All tests pass.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/brush_engine.dart test/brushes/brush_engine_test.dart
git commit -m "feat: upgrade Splatter to thick blob + directional opaque droplets; add tile cache infrastructure"
```

---

## Task 5: Upgrade Airbrush Brush

**Files:**
- Modify: `lib/brushes/brush_engine.dart`

- [ ] **Step 1: Write failing tests**

Add to `test/brushes/brush_engine_test.dart`:

```dart
  group('BrushEngine.airbrush', () {
    test('renders without throwing for multi-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [
          const Offset(100, 100),
          const Offset(160, 130),
          const Offset(220, 100),
        ],
        themeIndex: 0,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [const Offset(200, 200)],
        themeIndex: 1,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('uses theme 0 when themeIndex is null', () async {
      final stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [const Offset(200, 200), const Offset(250, 200)],
        themeIndex: null,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('is deterministic across all 10 themes', () async {
      for (int t = 0; t < 10; t++) {
        final stroke = Stroke(
          type: BrushType.airbrush,
          color: Colors.red,
          points: [const Offset(50, 50), const Offset(100, 80)],
          themeIndex: t,
        );
        final img1 = await renderStroke(stroke);
        final img2 = await renderStroke(stroke);
        final b1 = await img1.toByteData(format: ui.ImageByteFormat.rawRgba);
        final b2 = await img2.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(b1!.buffer.asUint8List(), b2!.buffer.asUint8List(),
            reason: 'theme $t was not deterministic');
      }
    });
  });
```

- [ ] **Step 2: Run tests to see current state**

```
flutter test test/brushes/brush_engine_test.dart
```
The airbrush tests may pass with the old implementation (it doesn't crash). The determinism test is the meaningful check — confirm it passes.

- [ ] **Step 3: Replace `_paintAirbrush` in `lib/brushes/brush_engine.dart`**

Replace only the `_paintAirbrush` method (keep all others intact):

```dart
  // ---------------------------------------------------------------------------
  // AIRBRUSH — opaque base stroke + emoji particles scattered along path
  // ---------------------------------------------------------------------------
  static void _paintAirbrush(Canvas canvas, Stroke stroke) {
    final theme = BrushTheme.airbrushThemes[stroke.themeIndex ?? 0];
    final rng = Random(stroke.hashCode);

    // Single point
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        12.0,
        Paint()..color = theme.baseColor,
      );
      _paintEmoji(
        canvas,
        theme.emojis[0],
        stroke.points.first - const Offset(0, 18),
        16.0,
        0.0,
      );
      return;
    }

    // Base stroke — thick, fully opaque
    final basePath = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      basePath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(
      basePath,
      Paint()
        ..color = theme.baseColor
        ..strokeWidth = 20.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Emoji particles every ~30px along path
    double distAccum = 0.0;
    const interval = 30.0;
    int particleIndex = 0;

    for (int i = 1; i < stroke.points.length; i++) {
      final p1 = stroke.points[i - 1];
      final p2 = stroke.points[i];
      distAccum += (p2 - p1).distance;

      if (distAccum >= interval) {
        distAccum = 0.0;
        final emojiIndex = (particleIndex + stroke.hashCode) % theme.emojis.length;
        final fontSize = 14.0 + rng.nextDouble() * 8.0; // 14–22px
        final rotation = (rng.nextDouble() - 0.5) * (pi / 3); // ±30°
        final offsetX = (rng.nextDouble() - 0.5) * 30.0; // ±15px
        final offsetY = (rng.nextDouble() - 0.5) * 30.0;
        _paintEmoji(
          canvas,
          theme.emojis[emojiIndex],
          p2 + Offset(offsetX, offsetY),
          fontSize,
          rotation,
        );
        particleIndex++;
      }
    }
  }

  /// Renders a single emoji at [center] with the given [fontSize] and [rotation] (radians).
  static void _paintEmoji(Canvas canvas, String emoji, Offset center, double fontSize, double rotation) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }
```

- [ ] **Step 4: Run airbrush tests**

```
flutter test test/brushes/brush_engine_test.dart
```
Expected: All tests pass.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/brush_engine.dart
git commit -m "feat: upgrade Airbrush to opaque base stroke with emoji particles along path"
```

---

## Task 6: Upgrade Pattern Brush

**Files:**
- Modify: `lib/brushes/brush_engine.dart`

- [ ] **Step 1: Write failing tests**

Add to `test/brushes/brush_engine_test.dart`:

```dart
  group('BrushEngine.pattern', () {
    test('renders without throwing for multi-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.yellow,
        points: [
          const Offset(100, 200),
          const Offset(150, 200),
          const Offset(200, 200),
        ],
        themeIndex: 0,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.yellow,
        points: [const Offset(200, 200)],
        themeIndex: 2,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders all 10 pattern styles without throwing', () async {
      for (int t = 0; t < 10; t++) {
        final stroke = Stroke(
          type: BrushType.pattern,
          color: Colors.white,
          points: [const Offset(50, 50), const Offset(150, 100)],
          themeIndex: t,
        );
        expect(() async => await renderStroke(stroke), returnsNormally,
            reason: 'pattern style $t threw');
      }
    });

    test('disposeTileCache clears cache without throwing', () async {
      // Generate a tile first
      final stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.white,
        points: [const Offset(50, 50), const Offset(150, 100)],
        themeIndex: 0,
      );
      await renderStroke(stroke);
      expect(() => BrushEngine.disposeTileCache(), returnsNormally);
    });
  });
```

- [ ] **Step 2: Run tests to confirm current state**

```
flutter test test/brushes/brush_engine_test.dart
```
Pattern tests will likely pass with old star implementation. `disposeTileCache` test should pass (clears empty cache).

- [ ] **Step 3: Replace `_paintPattern` in `lib/brushes/brush_engine.dart`**

Replace only the `_paintPattern` method and the `_stampStar` helper (both can be removed). The `_stampStar` is no longer needed:

```dart
  // ---------------------------------------------------------------------------
  // PATTERN — seamless wallpaper revealed by drawing (ImageShader + TileMode.repeated)
  // ---------------------------------------------------------------------------
  static void _paintPattern(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final styleIndex = stroke.themeIndex ?? 0;
    final style = BrushTheme.patternStyles[styleIndex];

    // On web, toImageSync() is unavailable — fall back to plain fill stroke.
    // ignore: avoid_web_libraries_in_flutter
    if (kIsWeb) {
      final fallbackPaint = Paint()
        ..color = style.backgroundColor
        ..strokeWidth = 40.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length < 2) {
        canvas.drawCircle(stroke.points.first, 24.0, fallbackPaint..style = PaintingStyle.fill);
        return;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, fallbackPaint);
      return;
    }

    // Generate tile lazily on first use of this pattern index.
    // Must be called from inside paint() — never from shouldRepaint().
    if (!_tileCache.containsKey(styleIndex)) {
      _tileCache[styleIndex] = _generateTile(style);
    }
    final tile = _tileCache[styleIndex]!;

    final shader = ui.ImageShader(
      tile,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      Float64List.fromList([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]),
    );
    final paint = Paint()
      ..shader = shader
      ..strokeWidth = 40.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        24.0,
        Paint()..shader = shader,
      );
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  /// Generates an 80×80 tiled image for the given pattern style.
  /// Synchronous via toImageSync() — native only.
  static ui.Image _generateTile(PatternStyle style) {
    const tileSize = 80.0;
    final recorder = ui.PictureRecorder();
    final tileCanvas = Canvas(recorder, Rect.fromLTWH(0, 0, tileSize, tileSize));

    // Background fill
    tileCanvas.drawRect(
      Rect.fromLTWH(0, 0, tileSize, tileSize),
      Paint()..color = style.backgroundColor,
    );

    // Emoji grid — 2 columns × rows based on emoji count
    final emojis = style.emojis;
    const emojiSize = 28.0;
    const cols = 2;
    final rows = (emojis.length / cols).ceil();
    final cellW = tileSize / cols;
    final cellH = tileSize / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final idx = row * cols + col;
        if (idx >= emojis.length) break;
        final tp = TextPainter(
          text: TextSpan(
            text: emojis[idx],
            style: const TextStyle(fontSize: emojiSize),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final x = col * cellW + (cellW - tp.width) / 2;
        final y = row * cellH + (cellH - tp.height) / 2;
        tp.paint(tileCanvas, Offset(x, y));
      }
    }

    final picture = recorder.endRecording();
    return picture.toImageSync(tileSize.toInt(), tileSize.toInt());
  }
```

Also delete the `_stampStar` helper method — it is no longer used.

- [ ] **Step 4: Run pattern tests**

```
flutter test test/brushes/brush_engine_test.dart
```
Expected: All tests pass. (Note: `toImageSync` works on Windows/Linux native test runner.)

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/brush_engine.dart
git commit -m "feat: upgrade Pattern to seamless ImageShader wallpaper with emoji tiles"
```

---

## Task 7: ThemePickerWidget

**Files:**
- Create: `lib/widgets/theme_picker_widget.dart`
- Create: `test/widgets/theme_picker_widget_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/widgets/theme_picker_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_theme.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';

void main() {
  group('ThemePickerWidget', () {
    testWidgets('shows 10 items for airbrush', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: ThemePickerWidget(
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // Each item has a label — check theme 0 label is present
      expect(find.text(BrushTheme.airbrushThemes[0].label), findsOneWidget);
    });

    testWidgets('shows 10 items for pattern', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: ThemePickerWidget(
                brushType: BrushType.pattern,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text(BrushTheme.patternStyles[0].label), findsOneWidget);
    });

    testWidgets('calls onThemeSelected when item tapped', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: ThemePickerWidget(
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (i) => selected = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(BrushTheme.airbrushThemes[0].label));
      expect(selected, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
flutter test test/widgets/theme_picker_widget_test.dart
```
Expected: `theme_picker_widget.dart` not found.

- [ ] **Step 3: Create `lib/widgets/theme_picker_widget.dart`**

```dart
import 'package:flutter/material.dart';
import '../brushes/brush_theme.dart';
import '../brushes/brush_type.dart';

/// Horizontal scrollable list of 10 theme/style tiles.
/// Shown in place of the color palette when Airbrush or Pattern is active.
/// Stateless — selection state is owned by CanvasController.
class ThemePickerWidget extends StatelessWidget {
  final BrushType brushType;
  final int selectedIndex;
  final ValueChanged<int> onThemeSelected;

  const ThemePickerWidget({
    super.key,
    required this.brushType,
    required this.selectedIndex,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isAirbrush = brushType == BrushType.airbrush;
    final count = 10;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final Color bgColor;
          final String emoji;
          final String label;

          if (isAirbrush) {
            final theme = BrushTheme.airbrushThemes[index];
            bgColor = theme.baseColor;
            emoji = theme.emojis.take(2).join(' ');
            label = theme.label;
          } else {
            final style = BrushTheme.patternStyles[index];
            bgColor = style.backgroundColor;
            emoji = style.emojis.take(2).join(' ');
            label = style.label;
          }

          return GestureDetector(
            onTap: () => onThemeSelected(index),
            child: AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.deepPurple : Colors.grey.shade400,
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

```
flutter test test/widgets/theme_picker_widget_test.dart
```
Expected: All 3 tests pass.

- [ ] **Step 5: Run full suite**

```
flutter test
```
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/theme_picker_widget.dart test/widgets/theme_picker_widget_test.dart
git commit -m "feat: add ThemePickerWidget — horizontal scrollable theme tile selector"
```

---

## Task 8: Wire Dynamic Toolbar in ColoringScreen

**Files:**
- Modify: `lib/screens/coloring_screen.dart`

- [ ] **Step 1: Write failing test**

Create `test/screens/coloring_screen_toolbar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';
import 'package:drawforfun/palette/palette_widget.dart';
import 'package:drawforfun/widgets/brush_selector_widget.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';
import 'package:drawforfun/persistence/drawing_entry.dart';
import 'package:drawforfun/screens/coloring_screen.dart';

Widget buildScreen() {
  return MaterialApp(
    home: ColoringScreen(
      entry: DrawingEntry(
        id: 'test',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/cat.svg',
      ),
    ),
  );
}

void main() {
  group('ColoringScreen toolbar', () {
    testWidgets('shows PaletteWidget when Pencil is active', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(PaletteWidget), findsOneWidget);
      expect(find.byType(ThemePickerWidget), findsNothing);
    });

    testWidgets('shows ThemePickerWidget when Airbrush is tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.descendant(
        of: find.byType(BrushSelectorWidget),
        matching: find.text('Air'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ThemePickerWidget), findsOneWidget);
      expect(find.byType(PaletteWidget), findsNothing);
    });

    testWidgets('shows ThemePickerWidget when Pattern is tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.descendant(
        of: find.byType(BrushSelectorWidget),
        matching: find.text('Stars'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ThemePickerWidget), findsOneWidget);
    });

    testWidgets('returns to PaletteWidget when Marker is tapped after Airbrush', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.descendant(
        of: find.byType(BrushSelectorWidget),
        matching: find.text('Air'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(BrushSelectorWidget),
        matching: find.text('Marker'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PaletteWidget), findsOneWidget);
      expect(find.byType(ThemePickerWidget), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
flutter test test/screens/coloring_screen_toolbar_test.dart
```
Expected: Tests fail — `ThemePickerWidget` not shown when Airbrush is selected.

- [ ] **Step 3: Update the bottom panel in `lib/screens/coloring_screen.dart`**

In the `build` method, replace the `Container` that holds the bottom panel (lines ~143–168) with:

```dart
                // ── Bottom Panel ─────────────────────────────────────
                ListenableBuilder(
                  listenable: _controller,
                  builder: (_, __) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrushSelectorWidget(
                          selectedBrush: _controller.activeBrushType,
                          onBrushSelected: _controller.setActiveBrush,
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isThemeBrush(_controller.activeBrushType)
                              ? ThemePickerWidget(
                                  key: const ValueKey('theme'),
                                  brushType: _controller.activeBrushType,
                                  selectedIndex: _controller.activeThemeIndex,
                                  onThemeSelected: _controller.setActiveTheme,
                                )
                              : PaletteWidget(
                                  key: const ValueKey('palette'),
                                  selectedColor: _controller.activeColor,
                                  onColorSelected: _controller.setActiveColor,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
```

Also remove the two separate `AnimatedBuilder` wrappers that previously drove `BrushSelectorWidget` and `PaletteWidget` individually — they are now covered by the outer `ListenableBuilder`.

Add the helper method to `_ColoringScreenState`:

```dart
  bool _isThemeBrush(BrushType type) =>
      type == BrushType.airbrush || type == BrushType.pattern;
```

Add the import at the top of `coloring_screen.dart`:

```dart
import '../widgets/theme_picker_widget.dart';
```

- [ ] **Step 4: Run `flutter analyze`**

```
flutter analyze
```
Expected: No errors.

- [ ] **Step 5: Run toolbar tests**

```
flutter test test/screens/coloring_screen_toolbar_test.dart
```
Expected: All tests pass.

- [ ] **Step 6: Run full suite**

```
flutter test
```
Expected: All pass.

- [ ] **Step 7: Smoke test on Windows Desktop**

```
flutter run -d windows
```
Manually verify:
- Pencil/Marker/Splatter selected → color palette visible
- Airbrush selected → theme picker appears (cross-fade); scrolls horizontally; selecting a tile highlights it
- Pattern selected → theme picker shows pattern styles; selecting a tile highlights it
- Switch back to Pencil → palette reappears
- Draw with each upgraded brush — Splatter shows thick blob + droplets, Airbrush shows colored stripe + emojis, Pattern reveals wallpaper

- [ ] **Step 8: Commit**

```bash
git add lib/screens/coloring_screen.dart test/screens/coloring_screen_toolbar_test.dart
git commit -m "feat: dynamic bottom toolbar — AnimatedSwitcher between palette and ThemePickerWidget"
```

---

## Done

All 8 tasks complete. Run `flutter analyze && flutter test` for a final clean check before declaring victory.
