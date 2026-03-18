# Eraser Tool — Design Spec
**Date:** 2026-03-18
**Status:** Approved

## Overview

Add an Eraser tool to the `ColoringScreen` (and any future coloring canvas). When selected, the eraser clears painted strokes back to the white canvas background using `BlendMode.clear`, matching the architecture already proven in `ContourCreatorScreen`. Three child-friendly sizes (S / M / L) are selectable via a sub-panel in the dynamic bottom toolbar. The black line-art overlay is architecturally isolated and is never affected.

---

## Data Model

### `BrushType` (`brushes/brush_type.dart`)
Add `eraser` as the sixth enum value:
```dart
enum BrushType { pencil, marker, airbrush, pattern, splatter, eraser }
```

### `Stroke` (`brushes/stroke.dart`)
No structural change. The existing nullable `themeIndex` field is repurposed for eraser strokes to encode the selected size index:
- `0` → Small (strokeWidth 20.0)
- `1` → Medium (strokeWidth 40.0, default)
- `2` → Large (strokeWidth 70.0)

For all other brush types, `themeIndex` retains its current meaning (airbrush/pattern theme). Update the field comment to document the dual use. `toJson`/`fromJson` are unchanged — `themeIndex` is already persisted.

---

## CanvasController (`canvas/canvas_controller.dart`)

Add one new field:
```dart
int _activeEraserSizeIndex = 1; // default Medium
```

Extend three existing members:

**`activeThemeIndex` getter** — return `_activeEraserSizeIndex` when eraser is active:
```dart
int get activeThemeIndex {
  if (_activeBrushType == BrushType.airbrush) return _activeAirbrushThemeIndex;
  if (_activeBrushType == BrushType.pattern)  return _activePatternThemeIndex;
  if (_activeBrushType == BrushType.eraser)   return _activeEraserSizeIndex;
  return 0;
}
```

**`setActiveTheme`** — save to `_activeEraserSizeIndex` when eraser is active:
```dart
void setActiveTheme(int index) {
  if (_activeBrushType == BrushType.airbrush) _activeAirbrushThemeIndex = index;
  else if (_activeBrushType == BrushType.pattern) _activePatternThemeIndex = index;
  else if (_activeBrushType == BrushType.eraser)  _activeEraserSizeIndex = index;
  notifyListeners();
}
```

**`startStroke`** — include eraser in the `useTheme` check so `themeIndex` is stamped onto the stroke:
```dart
final useTheme = _activeBrushType == BrushType.airbrush ||
    _activeBrushType == BrushType.pattern ||
    _activeBrushType == BrushType.eraser;
```

---

## DrawingPainter (`canvas/drawing_painter.dart`)

### saveLayer wrapping
Wrap all stroke rendering inside `canvas.saveLayer()`. The white background rect is drawn **before** `saveLayer` so erased areas reveal it:

```
paint(canvas, size):
  if paintBackground: drawRect(white)   // floor — outside saveLayer
  canvas.saveLayer(bounds, Paint())
    for each stroke in [strokes..., currentStroke]:
      if eraser → _paintEraser(canvas, stroke)
      else      → BrushEngine.paint(canvas, stroke)
  canvas.restore()
```

For `rawImport` entries (`paintBackground = false`), no white rect is drawn. Erased areas become transparent and show through to the background image widget (Layer 0 in `CanvasStackWidget`), which is the correct behaviour.

### Eraser rendering
```dart
static const _eraserWidths = [20.0, 40.0, 70.0]; // S, M, L

void _paintEraser(Canvas canvas, Stroke stroke) {
  final w = _eraserWidths[stroke.themeIndex ?? 1];
  final paint = Paint()
    ..blendMode = BlendMode.clear
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  if (stroke.points.length < 2) {
    canvas.drawCircle(stroke.points.first, w / 2, Paint()..blendMode = BlendMode.clear);
    return;
  }
  final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
  for (final p in stroke.points.skip(1)) path.lineTo(p.dx, p.dy);
  canvas.drawPath(path, paint);
}
```

### Layer safety
`DrawingPainter` is Layer 1 in `CanvasStackWidget`. Layer 2 (line art SVG/PNG overlay) is a separate Flutter widget rendered above it. `BlendMode.clear` inside a `saveLayer` affects only that layer's buffer — the widget tree above is never touched.

---

## BrushEngine (`brushes/brush_engine.dart`)

Add a no-op `eraser` case to the switch to prevent Dart exhaustiveness warnings. `DrawingPainter` guards against ever calling `BrushEngine.paint()` with an eraser stroke, so this branch is unreachable at runtime:
```dart
case BrushType.eraser:
  break; // handled by DrawingPainter before reaching BrushEngine
```

---

## EraserSizePickerWidget (`widgets/eraser_size_picker_widget.dart`) — new file

A stateless widget styled consistently with `ThemePickerWidget`. Displays three tappable tiles in a horizontal scrollable row.

Each tile contains:
- A filled white circle with a grey border, diameter proportional to the eraser size (16 / 28 / 44 logical px for S / M / L)
- A label `'S'` / `'M'` / `'L'` below the circle

Selected tile uses the same deepPurple highlight border and background as the rest of the toolbar selection UI.

Constructor:
```dart
const EraserSizePickerWidget({
  required int selectedIndex,
  required ValueChanged<int> onSizeSelected,
});
```

---

## BrushSelectorWidget (`widgets/brush_selector_widget.dart`)

Add eraser to the existing icon and label maps:
```dart
BrushType.eraser: Icons.auto_fix_normal,  // consistent with ContourCreator
// label:
BrushType.eraser: 'Eraser',
```

No other changes — the widget already iterates `BrushType.values`.

---

## ColoringScreen (`screens/coloring_screen.dart`)

Rename `_isThemeBrush` → `_showsSubPanel` and extend it to include `eraser`:
```dart
bool _showsSubPanel(BrushType type) =>
    type == BrushType.airbrush ||
    type == BrushType.pattern  ||
    type == BrushType.eraser;
```

Add an eraser branch to the `AnimatedSwitcher`:
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: _controller.activeBrushType == BrushType.eraser
      ? EraserSizePickerWidget(
          key: const ValueKey('eraser'),
          selectedIndex: _controller.activeThemeIndex,
          onSizeSelected: _controller.setActiveTheme,
        )
      : _isThemeBrush(_controller.activeBrushType)  // airbrush / pattern
          ? ThemePickerWidget(...)
          : PaletteWidget(...),
)
```

---

## Files Summary

| File | Action |
|------|--------|
| `lib/brushes/brush_type.dart` | Add `eraser` to enum |
| `lib/brushes/stroke.dart` | Update `themeIndex` comment |
| `lib/brushes/brush_engine.dart` | Add no-op `eraser` case to switch |
| `lib/canvas/drawing_painter.dart` | Add `saveLayer` + eraser dispatch |
| `lib/canvas/canvas_controller.dart` | Add `_activeEraserSizeIndex`, extend getter/setter/startStroke |
| `lib/widgets/brush_selector_widget.dart` | Add eraser icon + label |
| `lib/widgets/eraser_size_picker_widget.dart` | **New file** — 3-tile S/M/L picker |
| `lib/screens/coloring_screen.dart` | Extend sub-panel helper, add eraser branch |

**Untouched:** `ContourCreatorScreen`, `CanvasStackWidget`, `Stroke.toJson/fromJson`, all persistence/save logic.

---

## Success Criteria

1. Eraser button appears in the brush selector row in `ColoringScreen`.
2. Selecting Eraser shows the S/M/L size picker in Row 2; selecting a size persists it.
3. Drawing with the eraser clears coloring strokes back to white canvas (or background photo for rawImport).
4. The black line-art overlay is completely unaffected in all template types.
5. Undo removes eraser strokes correctly (existing `CanvasController.undo()` works unchanged).
6. Saving and reloading a drawing replays eraser strokes at the correct size.
7. `flutter analyze` reports zero errors.
