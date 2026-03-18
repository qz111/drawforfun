# Eraser Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a child-friendly Eraser tool to the coloring canvas that clears painted strokes using `BlendMode.clear`, with S/M/L size selection in the dynamic bottom toolbar.

**Architecture:** Add `BrushType.eraser` to the enum; repurpose the existing `Stroke.themeIndex` field to encode eraser size (0=S, 1=M, 2=L); wrap `DrawingPainter` stroke rendering in `saveLayer` so `BlendMode.clear` punches holes in the coloring layer without touching the line-art overlay above. The line-art overlay is a separate Flutter widget (Layer 2) and is architecturally unreachable by the eraser.

**Tech Stack:** Flutter/Dart, `CustomPainter`, `BlendMode.clear`, `canvas.saveLayer`, `flutter_test` widget tests.

**Spec:** `docs/superpowers/specs/2026-03-18-eraser-tool-design.md`

---

## File Map

| File | Action |
|------|--------|
| `lib/brushes/brush_type.dart` | Add `eraser` to enum |
| `lib/brushes/stroke.dart` | Update `themeIndex` comment |
| `lib/brushes/brush_engine.dart` | Add no-op `eraser` case to switch |
| `lib/canvas/canvas_controller.dart` | Add `_activeEraserSizeIndex`; extend `activeThemeIndex`, `setActiveTheme`, `startStroke` |
| `lib/canvas/drawing_painter.dart` | Wrap strokes in `saveLayer`; dispatch eraser to `_paintEraser` |
| `lib/widgets/eraser_size_picker_widget.dart` | **NEW** — 3-tile S/M/L size picker |
| `lib/widgets/brush_selector_widget.dart` | Add eraser to `_icons` and `_labels` maps |
| `lib/screens/coloring_screen.dart` | Add eraser branch to `AnimatedSwitcher` |
| `test/brushes/brush_engine_test.dart` | Add eraser no-op test |
| `test/canvas/canvas_controller_test.dart` | Add eraser size-index tests |
| `test/canvas/drawing_painter_test.dart` | Update description; add eraser-path test |
| `test/brushes/stroke_serialization_test.dart` | Update test name (5→6 brush types) |
| `test/widgets/eraser_size_picker_widget_test.dart` | **NEW** — widget tests |
| `test/widgets/brush_selector_widget_test.dart` | **NEW** — eraser button appearance test |

---

## Task 1: Add `eraser` to the type system

**Files:**
- Modify: `lib/brushes/brush_type.dart`
- Modify: `lib/brushes/stroke.dart`
- Modify: `lib/brushes/brush_engine.dart`
- Modify: `test/brushes/brush_engine_test.dart`
- Modify: `test/brushes/stroke_serialization_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/brushes/brush_engine_test.dart` inside `main()`, after the existing groups:

```dart
group('BrushEngine.eraser', () {
  test('eraser stroke is a no-op — does not throw', () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
    final stroke = Stroke(
      type: BrushType.eraser,
      color: Colors.red,
      points: const [Offset(100, 100), Offset(200, 200)],
      themeIndex: 1,
    );
    expect(() => BrushEngine.paint(canvas, stroke), returnsNormally);
    recorder.endRecording();
  });
});
```

- [ ] **Step 2: Run the test to confirm it fails**

```
flutter test test/brushes/brush_engine_test.dart
```

Expected: compile error — `BrushType.eraser` does not exist.

- [ ] **Step 3: Add `eraser` to `BrushType`**

`lib/brushes/brush_type.dart`:
```dart
/// The 6 supported brush types. No thickness variation — each has hardcoded behavior.
/// Eraser uses BlendMode.clear to wipe the coloring layer; line-art is unaffected.
enum BrushType { pencil, marker, airbrush, pattern, splatter, eraser }
```

- [ ] **Step 4: Add no-op `eraser` case to `BrushEngine`**

In `lib/brushes/brush_engine.dart`, inside the `switch (stroke.type)` block in `paint()`, add after the splatter case:

```dart
case BrushType.eraser:
  break; // handled by DrawingPainter before reaching BrushEngine — unreachable
```

- [ ] **Step 5: Update the `themeIndex` comment in `Stroke`**

In `lib/brushes/stroke.dart`, replace the existing `themeIndex` doc comment:

```dart
  /// Theme index (0–9) for airbrush and pattern brushes.
  /// For eraser strokes, encodes size: 0 = Small, 1 = Medium, 2 = Large.
  /// Null for other color-based brushes (pencil, marker, splatter).
  /// When non-null, BrushEngine ignores [color] and uses the index instead.
  final int? themeIndex;
```

- [ ] **Step 6: Update the serialization test description**

In `test/brushes/stroke_serialization_test.dart`, update the test name from `'roundtrips all 5 brush types'` to `'roundtrips all brush types'`. The test body uses `BrushType.values` dynamically so it already covers eraser — no other change needed.

- [ ] **Step 7: Run all tests — expect green**

```
flutter test
```

Expected: all pass. The existing `drawing_painter_test.dart` test `'paint does not throw with multiple brush types'` already iterates `BrushType.values` and will include an eraser stroke. With the no-op BrushEngine case it returns without throwing.

- [ ] **Step 8: Analyze**

```
flutter analyze
```

Expected: no issues.

- [ ] **Step 9: Commit**

```bash
git add lib/brushes/brush_type.dart lib/brushes/brush_engine.dart lib/brushes/stroke.dart \
        test/brushes/brush_engine_test.dart test/brushes/stroke_serialization_test.dart
git commit -m "feat: add BrushType.eraser to type system — no-op in BrushEngine"
```

---

## Task 2: Extend `CanvasController` for eraser size

**Files:**
- Modify: `lib/canvas/canvas_controller.dart`
- Modify: `test/canvas/canvas_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Add to `test/canvas/canvas_controller_test.dart` inside the `'CanvasController'` group, after the existing `setActiveTheme` tests:

```dart
test('activeThemeIndex defaults to 1 (Medium) for eraser', () {
  controller.setActiveBrush(BrushType.eraser);
  expect(controller.activeThemeIndex, 1);
});

test('setActiveTheme updates eraser size index independently', () {
  controller.setActiveBrush(BrushType.eraser);
  controller.setActiveTheme(0); // Small
  expect(controller.activeThemeIndex, 0);

  // switching away and back preserves eraser index
  controller.setActiveBrush(BrushType.airbrush);
  controller.setActiveBrush(BrushType.eraser);
  expect(controller.activeThemeIndex, 0);
});

test('eraser size index is independent of airbrush/pattern indices', () {
  controller.setActiveBrush(BrushType.airbrush);
  controller.setActiveTheme(5);

  controller.setActiveBrush(BrushType.eraser);
  controller.setActiveTheme(2); // Large

  controller.setActiveBrush(BrushType.airbrush);
  expect(controller.activeThemeIndex, 5); // airbrush unaffected

  controller.setActiveBrush(BrushType.eraser);
  expect(controller.activeThemeIndex, 2); // eraser preserved
});

test('startStroke stamps themeIndex for eraser', () {
  controller.setActiveBrush(BrushType.eraser);
  controller.setActiveTheme(2); // Large
  controller.startStroke(BrushType.eraser, Colors.red, const Offset(0, 0));
  expect(controller.currentStroke!.type, BrushType.eraser);
  expect(controller.currentStroke!.themeIndex, 2);
});

test('startStroke uses size index 1 (default) when no size set', () {
  controller.setActiveBrush(BrushType.eraser);
  controller.startStroke(BrushType.eraser, Colors.red, const Offset(0, 0));
  expect(controller.currentStroke!.themeIndex, 1);
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/canvas/canvas_controller_test.dart
```

Expected: FAIL — `activeThemeIndex` returns `_activePatternThemeIndex` (0) for eraser, not 1.

- [ ] **Step 3: Update `CanvasController`**

In `lib/canvas/canvas_controller.dart`:

**Add the new field** (after `_activePatternThemeIndex`):
```dart
int _activeEraserSizeIndex = 1; // default Medium (0=S, 1=M, 2=L)
```

**Replace `activeThemeIndex` getter** entirely:
```dart
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
```

**Replace `setActiveTheme`** entirely:
```dart
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
```

**Update `startStroke`** — add `eraser` to the `useTheme` check:
```dart
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
```

- [ ] **Step 4: Run tests — expect green**

```
flutter test test/canvas/canvas_controller_test.dart
```

Expected: all pass including new eraser tests.

- [ ] **Step 5: Run all tests**

```
flutter test
```

Expected: all pass.

- [ ] **Step 6: Analyze**

```
flutter analyze
```

Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add lib/canvas/canvas_controller.dart test/canvas/canvas_controller_test.dart
git commit -m "feat: extend CanvasController with eraser size index"
```

---

## Task 3: Update `DrawingPainter` with `saveLayer` + eraser rendering

**Files:**
- Modify: `lib/canvas/drawing_painter.dart`
- Modify: `test/canvas/drawing_painter_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/canvas/drawing_painter_test.dart` inside the `'DrawingPainter'` group:

```dart
test('paint handles eraser stroke without throwing', () {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const eraser = Stroke(
    type: BrushType.eraser,
    color: Colors.red, // ignored by eraser renderer
    points: [Offset(50, 50), Offset(150, 150)],
    themeIndex: 1, // Medium
  );
  const painter = DrawingPainter(strokes: [eraser], currentStroke: null);
  expect(
    () => painter.paint(canvas, const Size(400, 400)),
    returnsNormally,
  );
  recorder.endRecording();
});

test('paint handles eraser single-point tap without throwing', () {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const eraser = Stroke(
    type: BrushType.eraser,
    color: Colors.blue,
    points: [Offset(200, 200)],
    themeIndex: 2, // Large
  );
  const painter = DrawingPainter(strokes: [eraser], currentStroke: null);
  expect(
    () => painter.paint(canvas, const Size(400, 400)),
    returnsNormally,
  );
  recorder.endRecording();
});

test('paint handles eraser with null themeIndex (defaults to Medium)', () {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  const eraser = Stroke(
    type: BrushType.eraser,
    color: Colors.green,
    points: [Offset(10, 10), Offset(100, 100)],
    // themeIndex omitted → null → defaults to index 1 (Medium)
  );
  const painter = DrawingPainter(strokes: [eraser], currentStroke: null);
  expect(
    () => painter.paint(canvas, const Size(400, 400)),
    returnsNormally,
  );
  recorder.endRecording();
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/canvas/drawing_painter_test.dart
```

Expected: FAIL — `DrawingPainter.paint()` currently calls `BrushEngine.paint()` for all strokes; eraser hits the no-op case and doesn't throw, so these tests might pass. If they pass, that's fine — proceed to step 3 to apply the real `saveLayer` + eraser dispatch architecture.

- [ ] **Step 3: Rewrite `DrawingPainter`**

Replace `lib/canvas/drawing_painter.dart` entirely:

```dart
import 'package:flutter/material.dart';
import '../brushes/brush_engine.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

/// CustomPainter that renders all committed strokes plus the active stroke.
/// This is the BOTTOM layer of the canvas Stack — sits under the line art.
///
/// All stroke rendering happens inside [canvas.saveLayer] so that
/// eraser strokes using [BlendMode.clear] punch holes in the coloring layer
/// without affecting the line-art overlay widget above.
class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  /// When false, the white background fill is skipped (used when a background
  /// image is rendered as a separate widget below this painter).
  final bool paintBackground;

  // Stroke widths for the three eraser sizes: Small / Medium / Large.
  static const _eraserWidths = [20.0, 40.0, 70.0];

  const DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    this.paintBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // White background drawn OUTSIDE saveLayer — acts as the "erased-to" canvas floor.
    // Eraser holes in the saveLayer reveal this white rect below.
    // Skipped for rawImport entries (paintBackground=false) so erased areas instead
    // show through to the background photo widget (Layer 0 in CanvasStackWidget).
    if (paintBackground) {
      canvas.drawRect(bounds, Paint()..color = Colors.white);
    }

    // saveLayer isolates this layer so BlendMode.clear punches holes in the
    // coloring strokes without clearing the widget tree above (line-art overlay).
    canvas.saveLayer(bounds, Paint());

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.type == BrushType.eraser) {
      _paintEraser(canvas, stroke);
    } else {
      BrushEngine.paint(canvas, stroke);
    }
  }

  /// Renders an eraser stroke using BlendMode.clear to punch transparent holes
  /// in the coloring layer. Size is encoded in [Stroke.themeIndex] (0=S, 1=M, 2=L).
  void _paintEraser(Canvas canvas, Stroke stroke) {
    final w = _eraserWidths[stroke.themeIndex ?? 1];

    // Single-point tap: fill circle.
    // PaintingStyle.fill with radius w/2 matches the visual endpoint size of
    // a stroke path with strokeWidth=w (cap radius = w/2).
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        w / 2,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final p in stroke.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.paintBackground != paintBackground;
  }
}
```

- [ ] **Step 4: Run drawing_painter tests**

```
flutter test test/canvas/drawing_painter_test.dart
```

Expected: all pass including the new eraser tests.

- [ ] **Step 5: Run all tests**

```
flutter test
```

Expected: all pass.

- [ ] **Step 6: Analyze**

```
flutter analyze
```

Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add lib/canvas/drawing_painter.dart test/canvas/drawing_painter_test.dart
git commit -m "feat: add saveLayer + eraser rendering to DrawingPainter"
```

---

## Task 4: Create `EraserSizePickerWidget`

**Files:**
- Create: `lib/widgets/eraser_size_picker_widget.dart`
- Create: `test/widgets/eraser_size_picker_widget_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/widgets/eraser_size_picker_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/widgets/eraser_size_picker_widget.dart';

void main() {
  group('EraserSizePickerWidget', () {
    testWidgets('shows all three size labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: EraserSizePickerWidget(
                selectedIndex: 1,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('calls onSizeSelected with correct index when tapped', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: EraserSizePickerWidget(
                selectedIndex: 1,
                onSizeSelected: (i) => tapped = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('S'));
      expect(tapped, 0);

      await tester.tap(find.text('L'));
      expect(tapped, 2);
    });

    testWidgets('selected tile shows deepPurple highlight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: EraserSizePickerWidget(
                selectedIndex: 0,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // The 'S' tile should be selected — find its container with deepPurple background.
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('S'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.deepPurple.shade100);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/widgets/eraser_size_picker_widget_test.dart
```

Expected: compile error — `EraserSizePickerWidget` does not exist.

- [ ] **Step 3: Create `EraserSizePickerWidget`**

Create `lib/widgets/eraser_size_picker_widget.dart`:

```dart
import 'package:flutter/material.dart';

/// Three-tile S/M/L eraser size selector.
/// Appears in the coloring screen's bottom toolbar Row 2 when the Eraser brush is active.
/// Styled to match ThemePickerWidget's tile layout and deepPurple selection highlight.
class EraserSizePickerWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSizeSelected;

  const EraserSizePickerWidget({
    super.key,
    required this.selectedIndex,
    required this.onSizeSelected,
  });

  // Visual circle diameters for S / M / L — proportional to eraser stroke widths.
  static const _circleDiameters = [16.0, 28.0, 44.0];
  static const _labels = ['S', 'M', 'L'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _SizeTile(
            label: _labels[i],
            circleDiameter: _circleDiameters[i],
            isSelected: i == selectedIndex,
            onTap: () => onSizeSelected(i),
          ),
        )),
      ),
    );
  }
}

class _SizeTile extends StatelessWidget {
  final String label;
  final double circleDiameter;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeTile({
    required this.label,
    required this.circleDiameter,
    required this.isSelected,
    required this.onTap,
  });

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
            Container(
              width: circleDiameter,
              height: circleDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
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

- [ ] **Step 4: Run widget tests**

```
flutter test test/widgets/eraser_size_picker_widget_test.dart
```

Expected: all pass.

- [ ] **Step 5: Run all tests**

```
flutter test
```

Expected: all pass.

- [ ] **Step 6: Analyze**

```
flutter analyze
```

Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/eraser_size_picker_widget.dart test/widgets/eraser_size_picker_widget_test.dart
git commit -m "feat: add EraserSizePickerWidget — S/M/L tile selector"
```

---

## Task 5: Add eraser to `BrushSelectorWidget`

**Files:**
- Modify: `lib/widgets/brush_selector_widget.dart`
- Create: `test/widgets/brush_selector_widget_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widgets/brush_selector_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/brush_selector_widget.dart';

void main() {
  group('BrushSelectorWidget', () {
    testWidgets('shows a button for every BrushType including eraser', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrushSelectorWidget(
              selectedBrush: BrushType.pencil,
              onBrushSelected: (_) {},
            ),
          ),
        ),
      );
      // Every BrushType must have a label — missing entry crashes with null assertion.
      expect(find.text('Pencil'), findsOneWidget);
      expect(find.text('Marker'), findsOneWidget);
      expect(find.text('Air'),    findsOneWidget);
      expect(find.text('Stars'),  findsOneWidget);
      expect(find.text('Splat'),  findsOneWidget);
      expect(find.text('Erase'),  findsOneWidget); // eraser
    });

    testWidgets('calls onBrushSelected with eraser when eraser tapped', (tester) async {
      BrushType? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrushSelectorWidget(
              selectedBrush: BrushType.pencil,
              onBrushSelected: (t) => selected = t,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Erase'));
      expect(selected, BrushType.eraser);
    });

    testWidgets('eraser button shows selected highlight when active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrushSelectorWidget(
              selectedBrush: BrushType.eraser,
              onBrushSelected: (_) {},
            ),
          ),
        ),
      );
      // The 'Erase' tile container should carry deepPurple background.
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('Erase'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.deepPurple.shade100);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/widgets/brush_selector_widget_test.dart
```

Expected: FAIL — `find.text('Erase')` finds nothing; eraser is not yet in the maps.

- [ ] **Step 3: Add eraser to both maps in `BrushSelectorWidget`**

In `lib/widgets/brush_selector_widget.dart`, update `_icons` and `_labels`:

```dart
static const _icons = {
  BrushType.pencil:   Icons.edit,
  BrushType.marker:   Icons.brush,
  BrushType.airbrush: Icons.blur_on,
  BrushType.pattern:  Icons.star,
  BrushType.splatter: Icons.scatter_plot,
  BrushType.eraser:   Icons.auto_fix_normal,
};

static const _labels = {
  BrushType.pencil:   'Pencil',
  BrushType.marker:   'Marker',
  BrushType.airbrush: 'Air',
  BrushType.pattern:  'Stars',
  BrushType.splatter: 'Splat',
  BrushType.eraser:   'Erase',
};
```

- [ ] **Step 4: Run widget tests**

```
flutter test test/widgets/brush_selector_widget_test.dart
```

Expected: all pass.

- [ ] **Step 5: Run all tests**

```
flutter test
```

Expected: all pass.

- [ ] **Step 6: Analyze**

```
flutter analyze
```

Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/brush_selector_widget.dart test/widgets/brush_selector_widget_test.dart
git commit -m "feat: add Eraser button to BrushSelectorWidget"
```

---

## Task 6: Wire eraser into `ColoringScreen`

**Files:**
- Modify: `lib/screens/coloring_screen.dart`

- [ ] **Step 1: Update the `AnimatedSwitcher` in `ColoringScreen`**

In `lib/screens/coloring_screen.dart`, locate the `AnimatedSwitcher` block (currently inside `ListenableBuilder`). Add the eraser branch as the first condition and add the import for `EraserSizePickerWidget`.

**Add import** at the top:
```dart
import '../widgets/eraser_size_picker_widget.dart';
```

**Replace the `AnimatedSwitcher` child** (the current ternary that checks `_isThemeBrush`):
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: _controller.activeBrushType == BrushType.eraser
      ? EraserSizePickerWidget(
          key: const ValueKey('eraser'),
          selectedIndex: _controller.activeThemeIndex,
          onSizeSelected: _controller.setActiveTheme,
        )
      : _isThemeBrush(_controller.activeBrushType)
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
```

`_isThemeBrush` remains unchanged (airbrush + pattern only):
```dart
bool _isThemeBrush(BrushType type) =>
    type == BrushType.airbrush || type == BrushType.pattern;
```

- [ ] **Step 2: Run all tests**

```
flutter test
```

Expected: all pass.

- [ ] **Step 3: Analyze**

```
flutter analyze
```

Expected: no issues.

- [ ] **Step 4: Run the app on Windows Desktop for manual visual QA**

```
flutter run -d windows
```

Verify manually:
- [ ] Eraser button appears in brush selector row
- [ ] Tapping Eraser shows the S/M/L size picker in Row 2
- [ ] S/M/L tiles have correct visual circle sizes (small, medium, large)
- [ ] Drawing with eraser clears coloring strokes back to white
- [ ] Line-art template remains completely visible and untouched
- [ ] Switching eraser sizes changes the eraser stroke width visibly
- [ ] Undo removes eraser strokes correctly
- [ ] Other brushes (palette / theme picker) still work correctly after switching from eraser

- [ ] **Step 5: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat: wire Eraser tool into ColoringScreen toolbar"
```
