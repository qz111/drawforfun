# Flutter Children's Coloring App Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS-targeted Flutter children's coloring app (ages 3–8) with 5 hardcoded brush types, an on-device photo-to-line-art converter, and a Stack canvas that keeps black line art always visible above the color layer.

**Architecture:** A `Stack` of two layers — a `DrawingPainter` (CustomPainter, bottom) where strokes are painted, and a transparent-background line art `Image` widget (top) that always overlays drawing. Strokes are stored as a `List<Stroke>` in a `CanvasController` (ValueNotifier) and replayed on every repaint. The line art engine processes photos on-device using the `image` package (grayscale → Gaussian blur → Sobel edge detection → threshold → transparent PNG). Development and unit tests run on Windows; visual previews use `flutter run -d windows` or Chrome.

**Tech Stack:** Flutter (Dart), `image ^4.2.0` (pure Dart image processing), `path_provider ^2.1.2` (in-app save), `file_picker ^6.1.1` (photo upload), `image_gallery_saver ^2.0.3` (iOS device library save — guarded by platform check), `provider ^6.1.2` (state)

---

## Chunk 1: Foundation

### Task 1: Project Setup & pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: Update pubspec.yaml dependencies**

```yaml
dependencies:
  flutter:
    sdk: flutter
  image: ^4.2.0
  path_provider: ^2.1.2
  file_picker: ^6.1.1
  image_gallery_saver: ^2.0.3
  provider: ^6.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

- [ ] **Step 2: Create `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'screens/coloring_screen.dart';

class DrawForFunApp extends StatelessWidget {
  const DrawForFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw For Fun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ColoringScreen(),
    );
  }
}
```

- [ ] **Step 3: Create `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const DrawForFunApp());
}
```

- [ ] **Step 4: Run `flutter pub get` and verify**

```bash
flutter pub get
```
Expected: Resolves without errors.

- [ ] **Step 5: Run `flutter analyze` — expect 0 issues**

```bash
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/app.dart
git commit -m "chore: project setup with dependencies"
```

---

### Task 2: Color Palette — Data + Widget

**Files:**
- Create: `lib/palette/color_palette.dart`
- Create: `lib/palette/palette_widget.dart`
- Create: `test/palette/color_palette_test.dart`

- [ ] **Step 1: Write failing tests for `color_palette.dart`**

Create `test/palette/color_palette_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/palette/color_palette.dart';

void main() {
  group('ColorPalette', () {
    test('has exactly 24 colors', () {
      expect(ColorPalette.swatches.length, 24);
    });

    test('all colors are fully opaque', () {
      for (final color in ColorPalette.swatches) {
        expect(color.alpha, 255, reason: 'Color $color should be opaque');
      }
    });

    test('eraser color is white', () {
      expect(ColorPalette.eraser, Colors.white);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/palette/color_palette_test.dart -v
```
Expected: FAIL — `color_palette.dart` not found.

- [ ] **Step 3: Implement `lib/palette/color_palette.dart`**

```dart
import 'package:flutter/material.dart';

class ColorPalette {
  ColorPalette._();

  static const Color eraser = Colors.white;

  /// 24 crayola-inspired swatches for children.
  static const List<Color> swatches = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF4500), // Orange-Red
    Color(0xFFFF8C00), // Dark Orange
    Color(0xFFFFD700), // Gold
    Color(0xFFFFFF00), // Yellow
    Color(0xFF9ACD32), // Yellow-Green
    Color(0xFF00AA00), // Green
    Color(0xFF006400), // Dark Green
    Color(0xFF00CED1), // Dark Turquoise
    Color(0xFF1E90FF), // Dodger Blue
    Color(0xFF0000CD), // Medium Blue
    Color(0xFF4B0082), // Indigo
    Color(0xFF8A2BE2), // Blue-Violet
    Color(0xFFDA70D6), // Orchid
    Color(0xFFFF69B4), // Hot Pink
    Color(0xFFFF1493), // Deep Pink
    Color(0xFF8B4513), // Saddle Brown
    Color(0xFFD2691E), // Chocolate
    Color(0xFFFFA07A), // Light Salmon
    Color(0xFF808080), // Gray
    Color(0xFFC0C0C0), // Silver
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFFFFFACD), // Lemon Chiffon
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/palette/color_palette_test.dart -v
```
Expected: PASS (3 tests).

- [ ] **Step 5: Implement `lib/palette/palette_widget.dart`**

```dart
import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Grid of 24 color swatches + eraser. Calls [onColorSelected] on tap.
class PaletteWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const PaletteWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allColors = [...ColorPalette.swatches, ColorPalette.eraser];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allColors.map((color) => _ColorSwatch(
        color: color,
        isSelected: color == selectedColor,
        onTap: () => onColorSelected(color),
      )).toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade400,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run `flutter analyze`**

```bash
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 7: Commit**

```bash
git add lib/palette/ test/palette/
git commit -m "feat: color palette with 24 swatches and palette widget"
```

---

### Task 3: Stroke Model & BrushType Enum

**Files:**
- Create: `lib/brushes/brush_type.dart`
- Create: `lib/brushes/stroke.dart`
- Create: `test/brushes/stroke_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/brushes/stroke_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('BrushType', () {
    test('has exactly 5 values', () {
      expect(BrushType.values.length, 5);
    });

    test('contains all required brush names', () {
      final names = BrushType.values.map((e) => e.name).toSet();
      expect(names, containsAll(['pencil', 'marker', 'airbrush', 'pattern', 'splatter']));
    });
  });

  group('Stroke', () {
    test('stores type, color, and points', () {
      final stroke = Stroke(
        type: BrushType.pencil,
        color: Colors.red,
        points: [const Offset(10, 20), const Offset(30, 40)],
      );
      expect(stroke.type, BrushType.pencil);
      expect(stroke.color, Colors.red);
      expect(stroke.points.length, 2);
    });

    test('copyWith adds a point', () {
      final stroke = Stroke(
        type: BrushType.marker,
        color: Colors.blue,
        points: [const Offset(0, 0)],
      );
      final updated = stroke.copyWithPoint(const Offset(5, 5));
      expect(updated.points.length, 2);
      expect(updated.points.last, const Offset(5, 5));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/brushes/stroke_test.dart -v
```
Expected: FAIL — files not found.

- [ ] **Step 3: Implement `lib/brushes/brush_type.dart`**

```dart
/// The 5 supported brush types. No thickness variation — each has hardcoded behavior.
enum BrushType { pencil, marker, airbrush, pattern, splatter }
```

- [ ] **Step 4: Implement `lib/brushes/stroke.dart`**

```dart
import 'package:flutter/material.dart';
import 'brush_type.dart';

/// Immutable record of one continuous touch gesture.
class Stroke {
  final BrushType type;
  final Color color;
  final List<Offset> points;

  const Stroke({
    required this.type,
    required this.color,
    required this.points,
  });

  /// Returns a new Stroke with [point] appended to the points list.
  Stroke copyWithPoint(Offset point) {
    return Stroke(
      type: type,
      color: color,
      points: [...points, point],
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/brushes/stroke_test.dart -v
```
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/brush_type.dart lib/brushes/stroke.dart test/brushes/stroke_test.dart
git commit -m "feat: BrushType enum and Stroke model"
```

---

## Chunk 2: Brush Engine

### Task 4: Brush Engine — All 5 Brushes

**Files:**
- Create: `lib/brushes/brush_engine.dart`
- Create: `test/brushes/brush_engine_test.dart`

The brush engine is a pure function dispatcher — it takes a `Canvas`, `Size`, and `Stroke`, and paints it. Each brush has hardcoded visual parameters (no sliders).

**Brush specifications:**

| Brush | strokeWidth | opacity | Special |
|-------|------------|---------|---------|
| Pencil | 3.0 | 0.7–1.0 jitter | Rough, dotted feel |
| Marker | 18.0 | 0.55 | Flat, builds up |
| Airbrush | n/a | 0.04 per dot | Soft radial dots at each point |
| Pattern | n/a | 1.0 | Star icon stamped every 24px |
| Splatter | 2–5 random | 0.6–0.9 random | 8–14 random dots around each point |

- [ ] **Step 1: Write failing tests for brush engine**

Create `test/brushes/brush_engine_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_engine.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('BrushEngine', () {
    // We can't easily assert Canvas output, so we verify no exceptions are thrown
    // when painting each brush type. Visual QA is done via flutter run.

    late PictureRecorder recorder;
    late Canvas canvas;

    setUp(() {
      recorder = PictureRecorder();
      canvas = Canvas(recorder);
    });

    tearDown(() {
      recorder.endRecording();
    });

    final testPoints = [
      const Offset(10, 10),
      const Offset(20, 20),
      const Offset(30, 15),
      const Offset(50, 40),
    ];

    for (final type in BrushType.values) {
      test('paints $type brush without throwing', () {
        final stroke = Stroke(type: type, color: Colors.red, points: testPoints);
        expect(
          () => BrushEngine.paint(canvas, stroke),
          returnsNormally,
        );
      });
    }

    test('paintStroke with single point does not throw', () {
      final stroke = Stroke(
        type: BrushType.pencil,
        color: Colors.blue,
        points: [const Offset(5, 5)],
      );
      expect(() => BrushEngine.paint(canvas, stroke), returnsNormally);
    });

    test('paintStroke with empty points does not throw', () {
      final stroke = Stroke(
        type: BrushType.marker,
        color: Colors.green,
        points: [],
      );
      expect(() => BrushEngine.paint(canvas, stroke), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/brushes/brush_engine_test.dart -v
```
Expected: FAIL — `brush_engine.dart` not found.

- [ ] **Step 3: Implement `lib/brushes/brush_engine.dart`**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'brush_type.dart';
import 'stroke.dart';

/// Stateless brush renderer. All visual parameters are hardcoded per brush type.
class BrushEngine {
  BrushEngine._();

  static final _rng = Random();

  /// Entry point: dispatches to the correct brush painter.
  static void paint(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    switch (stroke.type) {
      case BrushType.pencil:   _paintPencil(canvas, stroke);   break;
      case BrushType.marker:   _paintMarker(canvas, stroke);   break;
      case BrushType.airbrush: _paintAirbrush(canvas, stroke); break;
      case BrushType.pattern:  _paintPattern(canvas, stroke);  break;
      case BrushType.splatter: _paintSplatter(canvas, stroke); break;
    }
  }

  // ---------------------------------------------------------------------------
  // PENCIL — thin, slightly rough strokes with opacity jitter
  // ---------------------------------------------------------------------------
  static void _paintPencil(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) {
      // Single dot
      canvas.drawCircle(
        stroke.points.first,
        1.5,
        Paint()..color = stroke.color.withOpacity(0.8),
      );
      return;
    }

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final opacity = 0.7 + _rng.nextDouble() * 0.3; // 0.7–1.0 jitter
      final paint = Paint()
        ..color = stroke.color.withOpacity(opacity)
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
        Paint()..color = stroke.color.withOpacity(0.55),
      );
      return;
    }

    final paint = Paint()
      ..color = stroke.color.withOpacity(0.55)
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
  // AIRBRUSH — soft radial gradient dots accumulate at each point
  // ---------------------------------------------------------------------------
  static void _paintAirbrush(Canvas canvas, Stroke stroke) {
    const radius = 28.0;
    for (final point in stroke.points) {
      final rect = Rect.fromCircle(center: point, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            stroke.color.withOpacity(0.10),
            stroke.color.withOpacity(0.0),
          ],
        ).createShader(rect)
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(point, radius, paint);
    }
  }

  // ---------------------------------------------------------------------------
  // PATTERN — repeating star icon stamped at 24px intervals along path
  // ---------------------------------------------------------------------------
  static void _paintPattern(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    double distanceAccumulator = 0.0;
    const stampInterval = 24.0;
    const iconSize = 14.0;

    // Stamp at the very first point
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

  /// Draws a 5-pointed star centered at [center].
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
  // SPLATTER — random dots scattered around each touch point
  // ---------------------------------------------------------------------------
  static void _paintSplatter(Canvas canvas, Stroke stroke) {
    for (final point in stroke.points) {
      // Only splatter on every 3rd point to avoid over-density
      if (_rng.nextInt(3) != 0) continue;

      final dotCount = 8 + _rng.nextInt(7); // 8–14 dots
      for (int i = 0; i < dotCount; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final distance = 8 + _rng.nextDouble() * 30; // 8–38px radius
        final dotOffset = Offset(
          point.dx + distance * cos(angle),
          point.dy + distance * sin(angle),
        );
        final dotRadius = 1.5 + _rng.nextDouble() * 3.0; // 1.5–4.5px
        final opacity = 0.6 + _rng.nextDouble() * 0.3;   // 0.6–0.9
        canvas.drawCircle(
          dotOffset,
          dotRadius,
          Paint()..color = stroke.color.withOpacity(opacity),
        );
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/brushes/brush_engine_test.dart -v
```
Expected: PASS (7 tests).

- [ ] **Step 5: Run `flutter analyze`**

```bash
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/brush_engine.dart test/brushes/brush_engine_test.dart
git commit -m "feat: brush engine with all 5 hardcoded brush types"
```

---

## Chunk 3: Canvas & Controller

### Task 5: Canvas Controller (State)

**Files:**
- Create: `lib/canvas/canvas_controller.dart`
- Create: `test/canvas/canvas_controller_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/canvas/canvas_controller_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';
import 'package:drawforfun/brushes/brush_type.dart';

void main() {
  group('CanvasController', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with empty strokes and no current stroke', () {
      expect(controller.strokes, isEmpty);
      expect(controller.currentStroke, isNull);
    });

    test('startStroke creates a new current stroke', () {
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(10, 10));
      expect(controller.currentStroke, isNotNull);
      expect(controller.currentStroke!.type, BrushType.pencil);
      expect(controller.currentStroke!.points.length, 1);
    });

    test('addPoint appends to current stroke', () {
      controller.startStroke(BrushType.marker, Colors.blue, const Offset(0, 0));
      controller.addPoint(const Offset(5, 5));
      controller.addPoint(const Offset(10, 10));
      expect(controller.currentStroke!.points.length, 3);
    });

    test('endStroke commits current stroke to strokes list', () {
      controller.startStroke(BrushType.pencil, Colors.green, const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      expect(controller.strokes.length, 1);
      expect(controller.currentStroke, isNull);
    });

    test('undo removes the last committed stroke', () {
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(0, 0));
      controller.endStroke();
      controller.startStroke(BrushType.marker, Colors.blue, const Offset(5, 5));
      controller.endStroke();
      controller.undo();
      expect(controller.strokes.length, 1);
    });

    test('clear removes all strokes', () {
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(0, 0));
      controller.endStroke();
      controller.clear();
      expect(controller.strokes, isEmpty);
    });

    test('undo on empty list does not throw', () {
      expect(() => controller.undo(), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/canvas/canvas_controller_test.dart -v
```
Expected: FAIL.

- [ ] **Step 3: Implement `lib/canvas/canvas_controller.dart`**

```dart
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

/// Manages drawing state: committed strokes + the in-progress current stroke.
/// Extends ChangeNotifier so widgets can rebuild on change.
class CanvasController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  List<Stroke> get strokes => List.unmodifiable(_strokes);
  Stroke? get currentStroke => _currentStroke;

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
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/canvas/canvas_controller_test.dart -v
```
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/canvas/canvas_controller.dart test/canvas/canvas_controller_test.dart
git commit -m "feat: CanvasController with stroke history, undo, clear"
```

---

### Task 6: DrawingPainter (CustomPainter)

**Files:**
- Create: `lib/canvas/drawing_painter.dart`
- Create: `test/canvas/drawing_painter_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/canvas/drawing_painter_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/canvas/drawing_painter.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('DrawingPainter', () {
    test('shouldRepaint returns true when strokes change', () {
      final stroke = Stroke(type: BrushType.pencil, color: Colors.red, points: [Offset.zero]);
      final oldPainter = DrawingPainter(strokes: [], currentStroke: null);
      final newPainter = DrawingPainter(strokes: [stroke], currentStroke: null);
      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when currentStroke changes', () {
      final stroke = Stroke(type: BrushType.pencil, color: Colors.red, points: [Offset.zero]);
      final oldPainter = DrawingPainter(strokes: [], currentStroke: null);
      final newPainter = DrawingPainter(strokes: [], currentStroke: stroke);
      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns false when nothing changed', () {
      final painter = DrawingPainter(strokes: [], currentStroke: null);
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('paint does not throw with multiple brush types', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final strokes = BrushType.values.map((type) => Stroke(
        type: type,
        color: Colors.blue,
        points: [const Offset(10, 10), const Offset(50, 50)],
      )).toList();

      final painter = DrawingPainter(strokes: strokes, currentStroke: null);
      expect(
        () => painter.paint(canvas, const Size(400, 400)),
        returnsNormally,
      );
      recorder.endRecording();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/canvas/drawing_painter_test.dart -v
```

- [ ] **Step 3: Implement `lib/canvas/drawing_painter.dart`**

```dart
import 'package:flutter/material.dart';
import '../brushes/brush_engine.dart';
import '../brushes/stroke.dart';

/// CustomPainter that renders all committed strokes plus the active stroke.
/// This is the BOTTOM layer of the canvas Stack — sits under the line art.
class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  const DrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Committed strokes
    for (final stroke in strokes) {
      BrushEngine.paint(canvas, stroke);
    }

    // In-progress stroke (drawn on top)
    if (currentStroke != null) {
      BrushEngine.paint(canvas, currentStroke!);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/canvas/drawing_painter_test.dart -v
```
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/canvas/drawing_painter.dart test/canvas/drawing_painter_test.dart
git commit -m "feat: DrawingPainter CustomPainter rendering all brush types"
```

---

## Chunk 4: Line Art Engine

### Task 7: On-Device Photo → Line Art Converter

**Files:**
- Create: `lib/line_art/line_art_engine.dart`
- Create: `test/line_art/line_art_engine_test.dart`

The algorithm:
1. Decode image bytes using `image` package
2. Resize to max 1024px (longest edge) for performance
3. Convert to grayscale
4. Apply Gaussian blur (radius 1) to reduce noise
5. Sobel edge detection — compute gradient magnitude per pixel
6. Threshold: pixels with magnitude > 40 → black (0,0,0,255); else → transparent (0,0,0,0)
7. Encode result as PNG bytes

- [ ] **Step 1: Write failing tests**

Create `test/line_art/line_art_engine_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:drawforfun/line_art/line_art_engine.dart';

Uint8List _makeSolidColorPng(int width, int height, img.ColorRgb8 color) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: color);
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('LineArtEngine', () {
    test('returns non-empty bytes for a valid image', () async {
      final inputBytes = _makeSolidColorPng(100, 100, img.ColorRgb8(200, 150, 100));
      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('returns null for invalid bytes', () async {
      final result = await LineArtEngine.convert(Uint8List.fromList([0, 1, 2, 3]));
      expect(result, isNull);
    });

    test('output is a valid PNG (starts with PNG magic bytes)', () async {
      final inputBytes = _makeSolidColorPng(80, 80, img.ColorRgb8(255, 0, 0));
      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);
      // PNG magic: 137 80 78 71 13 10 26 10
      expect(result![0], 137);
      expect(result[1], 80);
      expect(result[2], 78);
      expect(result[3], 71);
    });

    test('solid color image produces mostly transparent output (no edges)', () async {
      // A solid color image has no edges — output should be nearly all transparent
      final inputBytes = _makeSolidColorPng(50, 50, img.ColorRgb8(128, 128, 128));
      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);

      final outputImage = img.decodePng(result!)!;
      int opaquePixels = 0;
      for (final pixel in outputImage) {
        if (pixel.a > 0) opaquePixels++;
      }
      // Very few opaque pixels expected (edge artifacts only at border)
      expect(opaquePixels, lessThan(outputImage.width * 2));
    });

    test('image is resized to max 1024px on longest edge', () async {
      // Create a 2000x500 image
      final large = img.Image(width: 2000, height: 500);
      img.fill(large, color: img.ColorRgb8(100, 100, 100));
      final inputBytes = Uint8List.fromList(img.encodePng(large));

      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);

      final outputImage = img.decodePng(result!)!;
      // Longest edge should be <= 1024
      expect(outputImage.width, lessThanOrEqualTo(1024));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/line_art/line_art_engine_test.dart -v
```
Expected: FAIL.

- [ ] **Step 3: Implement `lib/line_art/line_art_engine.dart`**

```dart
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts an uploaded photo (any format) to a transparent-background,
/// black-line-art PNG suitable for use as a coloring page overlay.
class LineArtEngine {
  LineArtEngine._();

  static const int _maxSize = 1024;
  static const int _edgeThreshold = 40;

  /// Converts [inputBytes] to a transparent line art PNG.
  /// Returns null if decoding fails.
  static Future<Uint8List?> convert(Uint8List inputBytes) async {
    // 1. Decode
    final source = img.decodeImage(inputBytes);
    if (source == null) return null;

    // 2. Resize to max 1024px (longest edge)
    final resized = _resize(source);

    // 3. Grayscale
    final gray = img.grayscale(resized);

    // 4. Gaussian blur to reduce noise
    final blurred = img.gaussianBlur(gray, radius: 1);

    // 5 & 6. Sobel edge detection → threshold → transparent PNG
    final lineArt = _sobelToTransparent(blurred);

    // 7. Encode as PNG
    return Uint8List.fromList(img.encodePng(lineArt));
  }

  static img.Image _resize(img.Image src) {
    final longest = max(src.width, src.height);
    if (longest <= _maxSize) return src;
    final scale = _maxSize / longest;
    return img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Applies a Sobel operator and returns a new RGBA image where:
  /// - Strong edges → black (0, 0, 0, 255)
  /// - Weak areas → transparent (0, 0, 0, 0)
  static img.Image _sobelToTransparent(img.Image gray) {
    final w = gray.width;
    final h = gray.height;
    final out = img.Image(width: w, height: h, numChannels: 4);

    // Sobel kernels
    const gx = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]];
    const gy = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        double sumX = 0, sumY = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = gray.getPixel(x + kx, y + ky);
            // In a grayscale image all channels are equal; use red channel
            final brightness = pixel.r.toDouble();
            sumX += brightness * gx[ky + 1][kx + 1];
            sumY += brightness * gy[ky + 1][kx + 1];
          }
        }

        final magnitude = sqrt(sumX * sumX + sumY * sumY);

        if (magnitude > _edgeThreshold) {
          out.setPixelRgba(x, y, 0, 0, 0, 255); // black, opaque
        } else {
          out.setPixelRgba(x, y, 0, 0, 0, 0); // transparent
        }
      }
    }

    return out;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/line_art/line_art_engine_test.dart -v
```
Expected: PASS (5 tests).

- [ ] **Step 5: Run `flutter analyze`**

```bash
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add lib/line_art/line_art_engine.dart test/line_art/line_art_engine_test.dart
git commit -m "feat: on-device photo to line art converter using Sobel edge detection"
```

---

## Chunk 5: Save & UI Assembly

### Task 8: Save Manager

**Files:**
- Create: `lib/save/save_manager.dart`
- Create: `test/save/save_manager_test.dart`
- Modify: `ios/Runner/Info.plist` (add photo library permission)

The save manager captures the drawing canvas (both layers composited) and saves it:
- **In-app**: PNG file in app's documents directory
- **Device library**: Uses `image_gallery_saver` (iOS/Android only — guarded by `Platform.isIOS`)

On Windows (development), device library save is skipped gracefully.

- [ ] **Step 1: Add iOS photo library permissions to `ios/Runner/Info.plist`**

Add these keys inside the `<dict>` tag:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your coloring to your photo library</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Access your photo library to open photos for coloring</string>
```

- [ ] **Step 2: Write failing tests for save manager**

Create `test/save/save_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/save/save_manager.dart';

void main() {
  group('SaveManager', () {
    test('generateFilename returns a .png string with timestamp', () {
      final name = SaveManager.generateFilename();
      expect(name.endsWith('.png'), isTrue);
      expect(name.startsWith('coloring_'), isTrue);
    });

    test('generateFilename produces unique names', () {
      final a = SaveManager.generateFilename();
      // Small delay isn't guaranteed in unit tests, so just check format
      expect(a, matches(RegExp(r'^coloring_\d{8}_\d{6}\.png$')));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/save/save_manager_test.dart -v
```

- [ ] **Step 4: Implement `lib/save/save_manager.dart`**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

// image_gallery_saver is only available on iOS/Android
// Import conditionally at runtime via Platform check
import 'package:image_gallery_saver/image_gallery_saver.dart'
    if (dart.library.html) 'package:drawforfun/save/stub_gallery_saver.dart';

class SaveManager {
  SaveManager._();

  /// Generates a timestamped filename like `coloring_20260314_143022.png`.
  static String generateFilename() {
    final now = DateTime.now();
    final date =
        '${now.year}${_pad(now.month)}${_pad(now.day)}';
    final time =
        '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    return 'coloring_${date}_$time.png';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Captures [repaintKey]'s render object as PNG bytes.
  static Future<Uint8List?> captureCanvas(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Saves [bytes] as a PNG to the app's documents directory.
  /// Returns the saved file path on success, null on failure.
  static Future<String?> saveToAppDocuments(Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${generateFilename()}');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Saves [bytes] to the device photo library.
  /// On Windows (dev environment) this is a no-op that returns false.
  static Future<bool> saveToGallery(Uint8List bytes) async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 95,
        name: generateFilename(),
      );
      return result['isSuccess'] == true;
    } catch (e) {
      return false;
    }
  }
}
```

- [ ] **Step 5: Create stub for web/Windows compatibility**

Create `lib/save/stub_gallery_saver.dart`:

```dart
/// Stub for platforms where image_gallery_saver is unavailable.
class ImageGallerySaver {
  static Future<Map<String, dynamic>> saveImage(
    dynamic bytes, {
    int quality = 80,
    String? name,
  }) async {
    return {'isSuccess': false, 'filePath': null};
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/save/save_manager_test.dart -v
```
Expected: PASS (2 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/save/ test/save/ ios/Runner/Info.plist
git commit -m "feat: save manager for in-app and device gallery export"
```

---

### Task 9: Canvas Stack Widget

**Files:**
- Create: `lib/canvas/canvas_stack_widget.dart`

This widget is the heart of the app — it stacks the drawing layer beneath the line art overlay and handles all touch events.

- [ ] **Step 1: Implement `lib/canvas/canvas_stack_widget.dart`**

No unit test here — this is a pure UI widget. Visual QA via `flutter run -d windows`.

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (bottom) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// Optional line art PNG bytes. When null, shows blank canvas.
  final Uint8List? lineArtBytes;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtBytes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => controller.startStroke(
        controller.activeBrushType,
        controller.activeColor,
        d.localPosition,
      ),
      onPanUpdate: (d) => controller.addPoint(d.localPosition),
      onPanEnd: (_) => controller.endStroke(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Drawing (colors)
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              painter: DrawingPainter(
                strokes: controller.strokes,
                currentStroke: controller.currentStroke,
              ),
            ),
          ),

          // Layer 1: Line art (always on top — lines never covered)
          if (lineArtBytes != null)
            Image.memory(
              lineArtBytes!,
              fit: BoxFit.contain,
              // Transparent pixels in the PNG let the drawing layer show through
              gaplessPlayback: true,
            ),
        ],
      ),
    );
  }
}
```

> **Note:** The above references `controller.activeBrushType` and `controller.activeColor` — add these fields to `CanvasController` in the next step.

- [ ] **Step 2: Update `CanvasController` to hold active brush & color**

Add to `lib/canvas/canvas_controller.dart`:

```dart
// Add these fields and methods to CanvasController:

BrushType _activeBrushType = BrushType.marker;
Color _activeColor = const Color(0xFFFF0000); // Default: Red

BrushType get activeBrushType => _activeBrushType;
Color get activeColor => _activeColor;

void setActiveBrush(BrushType type) {
  _activeBrushType = type;
  notifyListeners();
}

void setActiveColor(Color color) {
  _activeColor = color;
  notifyListeners();
}
```

(Also add `import '../brushes/brush_type.dart';` if not already imported.)

- [ ] **Step 3: Run all tests to verify nothing broke**

```bash
flutter test -v
```
Expected: All previously passing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add lib/canvas/canvas_stack_widget.dart lib/canvas/canvas_controller.dart
git commit -m "feat: canvas stack widget with drawing + line art layers"
```

---

### Task 10: Brush Selector Widget

**Files:**
- Create: `lib/widgets/brush_selector_widget.dart`

- [ ] **Step 1: Implement `lib/widgets/brush_selector_widget.dart`**

```dart
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';

/// Row of 5 large brush selector buttons. No sliders — tap to select.
class BrushSelectorWidget extends StatelessWidget {
  final BrushType selectedBrush;
  final ValueChanged<BrushType> onBrushSelected;

  const BrushSelectorWidget({
    super.key,
    required this.selectedBrush,
    required this.onBrushSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: BrushType.values.map((type) => _BrushButton(
        type: type,
        isSelected: type == selectedBrush,
        onTap: () => onBrushSelected(type),
      )).toList(),
    );
  }
}

class _BrushButton extends StatelessWidget {
  final BrushType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushButton({required this.type, required this.isSelected, required this.onTap});

  static const _icons = {
    BrushType.pencil:   Icons.edit,
    BrushType.marker:   Icons.brush,
    BrushType.airbrush: Icons.blur_on,
    BrushType.pattern:  Icons.star,
    BrushType.splatter: Icons.scatter_plot,
  };

  static const _labels = {
    BrushType.pencil:   'Pencil',
    BrushType.marker:   'Marker',
    BrushType.airbrush: 'Air',
    BrushType.pattern:  'Stars',
    BrushType.splatter: 'Splat',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icons[type], size: 28, color: isSelected ? Colors.deepPurple : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              _labels[type]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/brush_selector_widget.dart
git commit -m "feat: brush selector widget with 5 brush type buttons"
```

---

### Task 11: Main Coloring Screen + Photo Upload

**Files:**
- Create: `lib/screens/coloring_screen.dart`

This is the full assembly: toolbar (top), canvas (center), palette + brush selector (bottom).

- [ ] **Step 1: Implement `lib/screens/coloring_screen.dart`**

```dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../line_art/line_art_engine.dart';
import '../palette/color_palette.dart';
import '../palette/palette_widget.dart';
import '../save/save_manager.dart';
import '../widgets/brush_selector_widget.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _controller = CanvasController();
  final _repaintKey = GlobalKey();
  Uint8List? _lineArtBytes;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndConvertPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _isProcessing = true);
    final lineArt = await LineArtEngine.convert(result.files.single.bytes!);
    setState(() {
      _lineArtBytes = lineArt;
      _isProcessing = false;
    });
  }

  Future<void> _saveArtwork() async {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null || !mounted) return;

    // Save in-app
    final path = await SaveManager.saveToAppDocuments(bytes);

    // Save to device gallery (iOS only; no-op on Windows)
    await SaveManager.saveToGallery(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Saved!' : 'Save failed'),
          backgroundColor: path != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('Draw For Fun', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.photo_library), onPressed: _pickAndConvertPhoto, tooltip: 'Load photo'),
          IconButton(icon: const Icon(Icons.undo), onPressed: _controller.undo, tooltip: 'Undo'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _showClearDialog(context), tooltip: 'Clear'),
          IconButton(icon: const Icon(Icons.save_alt), onPressed: _saveArtwork, tooltip: 'Save'),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : CanvasStackWidget(
                          controller: _controller,
                          lineArtBytes: _lineArtBytes,
                        ),
                ),
              ),
            ),
          ),

          // ── Bottom Panel ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brush selector
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => BrushSelectorWidget(
                    selectedBrush: _controller.activeBrushType,
                    onBrushSelected: _controller.setActiveBrush,
                  ),
                ),
                const SizedBox(height: 10),
                // Color palette
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => PaletteWidget(
                    selectedColor: _controller.activeColor,
                    onColorSelected: _controller.setActiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text('This will erase everything. Are you sure?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```bash
flutter analyze
```
Expected: 0 errors.

- [ ] **Step 3: Run all tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 4: Run visual preview on Windows Desktop**

```bash
flutter run -d windows
```
Expected: App launches. Verify:
- [ ] 5 brush buttons visible
- [ ] 24 color swatches visible
- [ ] Drawing on canvas works
- [ ] Undo removes last stroke
- [ ] Clear resets canvas
- [ ] Photo pick converts to line art and overlays on canvas
- [ ] Colors paint below line art (lines always visible on top)

- [ ] **Step 5: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat: main coloring screen with toolbar, canvas, brushes, and palette"
```

---

### Task 12: Final Polish & Integration Verification

- [ ] **Step 1: Run full test suite**

```bash
flutter test -v
```
Expected: All tests pass, 0 failures.

- [ ] **Step 2: Run Flutter analyze**

```bash
flutter analyze
```
Expected: 0 issues.

- [ ] **Step 3: Visual QA checklist (Windows Desktop)**

Run `flutter run -d windows` and verify:
- [ ] Pencil: thin scratchy strokes
- [ ] Marker: bold semi-transparent strokes that build up on overlap
- [ ] Airbrush: soft, spray-paint-like accumulation
- [ ] Pattern: star icons stamped along stroke path
- [ ] Splatter: random scattered dots around touch point
- [ ] Color swatches update the active brush color
- [ ] White swatch acts as eraser
- [ ] Photo upload: photo converted to B&W line art, overlaid on canvas
- [ ] Line art stays on top — colors paint under the lines
- [ ] Undo works stroke by stroke
- [ ] Clear resets everything with confirmation dialog
- [ ] Save (in-app path logged to console)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: final integration and visual QA complete"
```

---

## File Map Summary

```
lib/
├── main.dart                          Entry point
├── app.dart                           MaterialApp shell
├── brushes/
│   ├── brush_type.dart                BrushType enum (5 values)
│   ├── stroke.dart                    Stroke data model
│   └── brush_engine.dart              All 5 brush painters (pure functions)
├── canvas/
│   ├── canvas_controller.dart         ChangeNotifier: strokes, undo, clear, active brush/color
│   ├── drawing_painter.dart           CustomPainter (bottom canvas layer)
│   └── canvas_stack_widget.dart       Stack: drawing layer + line art overlay
├── line_art/
│   └── line_art_engine.dart           On-device Sobel edge detection + PNG export
├── palette/
│   ├── color_palette.dart             24 hardcoded swatches + eraser
│   └── palette_widget.dart            Circular swatch grid UI
├── save/
│   ├── save_manager.dart              In-app + device gallery save
│   └── stub_gallery_saver.dart        Windows/Web stub
├── screens/
│   └── coloring_screen.dart           Main screen (full assembly)
└── widgets/
    └── brush_selector_widget.dart     5-button brush selector

test/
├── brushes/
│   ├── stroke_test.dart
│   └── brush_engine_test.dart
├── canvas/
│   ├── canvas_controller_test.dart
│   └── drawing_painter_test.dart
├── line_art/
│   └── line_art_engine_test.dart
├── palette/
│   └── color_palette_test.dart
└── save/
    └── save_manager_test.dart
```

---

## Known Constraints

- **Windows dev environment**: Never run `pod install`, `xcodebuild`, or iOS simulator commands. Use `flutter run -d windows` or `flutter run -d chrome` for visual preview.
- **Visual QA is manual**: All brush realism, edge detection quality, and UI aesthetics require human review via `flutter run`. Do not assert visual outcomes.
- **`image_gallery_saver` is iOS/Android only**: The Platform guard in `SaveManager` handles this. On Windows, gallery save silently returns false.
- **Package additions**: Always ask before adding packages beyond those listed in Task 1.
