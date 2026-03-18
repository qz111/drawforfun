# Eraser Tool — Design Spec
**Date:** 2026-03-18
**Status:** Approved

## Overview

Add an Eraser tool to the `ColoringScreen` (and any future coloring canvas). When selected, the eraser clears painted strokes back to the white canvas background using `BlendMode.clear`, matching the architecture already proven in `ContourCreatorScreen`. Three child-friendly sizes (S / M / L) are selectable via a sub-panel in the dynamic bottom toolbar. The black line-art overlay is architecturally isolated and is never affected.

`ContourCreatorScreen` uses its own separate `ContourCreatorPainter` (not `DrawingPainter`) — it is unaffected by this change.

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

For all other brush types, `themeIndex` retains its current meaning (airbrush/pattern theme index). Update the field comment:
```dart
/// Theme index (0–9) for airbrush and pattern brushes.
/// For eraser strokes, encodes size: 0 = Small, 1 = Medium, 2 = Large.
/// Null for other color-based brushes (pencil, marker, splatter).
/// When non-null, BrushEngine ignores [color] and uses the index instead.
```

`toJson`/`fromJson` are unchanged — `themeIndex` is already persisted.

For eraser strokes, `Stroke.color` is set to `controller.activeColor` (whatever was last active). The value is ignored by the eraser renderer (`BlendMode.clear` discards source color).

---

## CanvasController (`canvas/canvas_controller.dart`)

Add one new field:
```dart
int _activeEraserSizeIndex = 1; // default Medium
```

Extend three existing members:

**`activeThemeIndex` getter** — return `_activeEraserSizeIndex` when eraser is active. Update the doc comment to reflect eraser:
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
  bounds = Rect.fromLTWH(0, 0, size.width, size.height)
  if paintBackground: canvas.drawRect(bounds, white paint)   // floor — outside saveLayer
  canvas.saveLayer(bounds, Paint())
    for each stroke in [strokes..., currentStroke]:
      if stroke.type == BrushType.eraser → _paintEraser(canvas, stroke)
      else                               → BrushEngine.paint(canvas, stroke)
  canvas.restore()
```

**`saveLayer` is unconditional.** Conditional saveLayer (only when eraser strokes exist) would require iterating strokes on every repaint to check for presence of eraser — equivalent overhead with added complexity. The offscreen pass cost of `saveLayer` is negligible on the target iPad hardware. Accept this trade-off.

For `rawImport` entries (`paintBackground = false`), no white rect is drawn. Erased areas in the layer become transparent and show through to the background image widget (Layer 0 in `CanvasStackWidget`) — the correct behaviour.

### Eraser rendering

```dart
static const _eraserWidths = [20.0, 40.0, 70.0]; // S, M, L

void _paintEraser(Canvas canvas, Stroke stroke) {
  final w = _eraserWidths[stroke.themeIndex ?? 1];

  // Single-point tap: fill circle so the visual radius matches strokeWidth / 2.
  if (stroke.points.length < 2) {
    canvas.drawCircle(
      stroke.points.first,
      w / 2,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill,   // fill so radius = w/2 matches stroke path visually
    );
    return;
  }

  final paint = Paint()
    ..blendMode = BlendMode.clear
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
  for (final p in stroke.points.skip(1)) path.lineTo(p.dx, p.dy);
  canvas.drawPath(path, paint);
}
```

Note: the single-point fallback uses a separate `Paint()` with `PaintingStyle.fill` intentionally. A stroke-style circle with `strokeWidth = w` would have a visual radius of `w/2 + w/2 = w`, which is twice as large as the path's cap radius. Fill with radius `w/2` matches the path's visual endpoint exactly.

### Layer safety
`DrawingPainter` is Layer 1 in `CanvasStackWidget`. Layer 2 (line art SVG/PNG overlay) is a separate Flutter widget rendered above it. `BlendMode.clear` inside a `saveLayer` affects only that layer's offscreen buffer — the widget tree above is never touched.

---

## BrushEngine (`brushes/brush_engine.dart`)

Add a no-op `eraser` case to the switch to prevent Dart analyzer exhaustiveness warnings. `DrawingPainter` guards against calling `BrushEngine.paint()` with an eraser stroke, so this branch is unreachable at runtime:
```dart
case BrushType.eraser:
  break; // handled by DrawingPainter — this branch is unreachable
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

Add `eraser` to **both** the `_icons` and `_labels` static const maps. The widget's `build` method dereferences these maps with `!` for every value in `BrushType.values` — omitting either entry will throw a null-assertion at runtime:

```dart
static const _icons = {
  BrushType.pencil:   Icons.edit,
  BrushType.marker:   Icons.brush,
  BrushType.airbrush: Icons.blur_on,
  BrushType.pattern:  Icons.star,
  BrushType.splatter: Icons.scatter_plot,
  BrushType.eraser:   Icons.auto_fix_normal,  // ← add
};

static const _labels = {
  BrushType.pencil:   'Pencil',
  BrushType.marker:   'Marker',
  BrushType.airbrush: 'Air',
  BrushType.pattern:  'Stars',
  BrushType.splatter: 'Splat',
  BrushType.eraser:   'Erase',  // ← add; 5 chars matches 'Splat'/'Stars' length
};
```

No other changes — the widget already iterates `BrushType.values`.

---

## ColoringScreen (`screens/coloring_screen.dart`)

`_isThemeBrush` is **not renamed**. It continues to return `true` only for `airbrush` and `pattern` (the two brushes that show `ThemePickerWidget`). Eraser is handled explicitly as the first branch in the `AnimatedSwitcher`.

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
)
```

`_isThemeBrush` is unchanged:
```dart
bool _isThemeBrush(BrushType type) =>
    type == BrushType.airbrush || type == BrushType.pattern;
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
| `lib/widgets/brush_selector_widget.dart` | Add eraser to `_icons` and `_labels` maps |
| `lib/widgets/eraser_size_picker_widget.dart` | **New file** — 3-tile S/M/L picker |
| `lib/screens/coloring_screen.dart` | Add eraser branch to `AnimatedSwitcher` |

**Untouched:** `ContourCreatorScreen` (uses its own `ContourCreatorPainter`), `CanvasStackWidget`, `Stroke.toJson/fromJson`, all persistence/save logic.

---

## Success Criteria

1. Eraser button appears in the brush selector row in `ColoringScreen`.
2. Selecting Eraser shows the S/M/L size picker in Row 2; tapping a size tile updates the selection highlight immediately.
3. Drawing with the eraser clears coloring strokes: on template canvases, erased areas reveal white; on rawImport canvases, erased areas reveal the background photo.
4. The black line-art overlay is completely unaffected across all template types (SVG asset, uploaded PNG, rawImport).
5. Undo removes eraser strokes in correct draw order (existing `CanvasController.undo()` is unchanged).
6. After save → quit → reload, eraser marks reappear at the same position and size as when originally drawn.
7. `flutter analyze` reports zero errors or warnings.
