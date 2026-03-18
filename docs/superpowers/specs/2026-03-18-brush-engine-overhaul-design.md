# Brush Engine Overhaul — Design Spec
**Date:** 2026-03-18
**Project:** DrawForFun (Flutter, children's coloring app, iPad target)
**Scope:** Upgrade all 5 brush types and add a dynamic bottom toolbar that adapts per brush.

---

## 1. Goals

1. **Dynamic Bottom Toolbar** — Color palette visible for Pencil/Marker/Splatter; replaced by a horizontal theme picker for Airbrush/Pattern.
2. **Upgraded Airbrush** — Dense opaque base stroke with emoji particles scattered along the path (10 themes).
3. **Upgraded Pattern** — Seamless tiled wallpaper revealed by drawing (10 styles), using `ui.PictureRecorder` + `ImageShader`.
4. **Upgraded Splatter** — Realistic thick-paint feel: opaque central blob + directional droplets at alpha 255.

---

## 2. Data Model

### 2.1 `Stroke` (`lib/brushes/stroke.dart`)

Add one nullable field with an explicit default of `null`:

```dart
final int? themeIndex; // null for color brushes; 0–9 for airbrush/pattern
```

Constructor signature change:
```dart
const Stroke({
  required this.type,
  required this.color,
  required this.points,
  this.themeIndex,  // defaults to null — backward-compatible
});
```

All existing `Stroke(...)` call sites that do not pass `themeIndex` continue to compile unchanged because `themeIndex` is a named optional parameter with a null default. Affected call sites to update explicitly:

- `copyWithPoint()` — add `themeIndex: themeIndex` to the returned `Stroke`.
- `fromJson()` — add `themeIndex: json['themeIndex'] as int?` (null if key absent).
- `CanvasController.startStroke()` — passes `themeIndex` conditionally (see §2.2).

Serialisation:
- `toJson()` — emit `'themeIndex': themeIndex` (value will be null for color brushes; JSON serialisation of `null` is fine and round-trips cleanly).
- `fromJson()` — `json['themeIndex'] as int?` returns null for missing keys, so existing saved strokes load without error.

### 2.2 `CanvasController` (`lib/canvas/canvas_controller.dart`)

Airbrush and Pattern each maintain their own independent theme index so switching between them does not reset the other's selection:

- Add `int _activeAirbrushThemeIndex = 0` and `int _activePatternThemeIndex = 0`.
- Add getters `int get activeAirbrushThemeIndex` and `int get activePatternThemeIndex`.
- Add `void setActiveTheme(int index)` — sets the index for whichever brush is currently active, calls `notifyListeners()`:

```dart
void setActiveTheme(int index) {
  if (_activeBrushType == BrushType.airbrush) {
    _activeAirbrushThemeIndex = index;
  } else if (_activeBrushType == BrushType.pattern) {
    _activePatternThemeIndex = index;
  }
  notifyListeners();
}
```

- Convenience getter used by `ThemePickerWidget` and `startStroke()`:

```dart
int get activeThemeIndex => _activeBrushType == BrushType.airbrush
    ? _activeAirbrushThemeIndex
    : _activePatternThemeIndex;
```

- `startStroke(BrushType type, Color color, Offset point)` — the method signature does not change. Inside, branch on `_activeBrushType` (the internal field, not the `type` parameter):

```dart
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
```

Note: `CanvasStackWidget` calls `controller.startStroke(controller.activeBrushType, controller.activeColor, d.localPosition)` — no change needed there. The controller uses `_activeBrushType` internally for the branch, ensuring the theme decision is always consistent with the controller's true active state.

Convention: for `BrushType.airbrush` and `BrushType.pattern` strokes, `Stroke.color` is populated but **ignored by `BrushEngine`** — `themeIndex` is the authoritative field. `BrushEngine` must never read `stroke.color` for these two brush types. This is an intentional trade-off to avoid changing `CanvasStackWidget`'s call signature.

### 2.3 `BrushTheme` (new file `lib/brushes/brush_theme.dart`)

Pure data class — no logic. Two static const lists:

**Airbrush themes** (10 entries, each with):
```dart
class AirbrushTheme {
  final Color baseColor;
  final List<String> emojis;
  final String label;
  const AirbrushTheme({required this.baseColor, required this.emojis, required this.label});
}
```

| # | Label | Base Color | Emojis |
|---|-------|-----------|--------|
| 0 | Blue + Gold Flowers | `#1565C0` | 🌸 🌼 ✨ |
| 1 | Yellow + Rainbows | `#F9A825` | 🌈 ☁️ 🌟 |
| 2 | Pink + Butterflies | `#880E4F` | 🦋 💜 🌸 |
| 3 | Green + Stars | `#1B5E20` | ✨ ⭐ 🌟 |
| 4 | Red + Fire | `#B71C1C` | 🔥 💥 ⚡ |
| 5 | Teal + Ocean | `#006064` | 🌊 🐟 💧 |
| 6 | Purple + Magic | `#4A148C` | 🪄 🌙 💫 |
| 7 | Orange + Autumn | `#E65100` | 🍂 🍁 🎃 |
| 8 | Dark + Space | `#37474F` | 🌙 ⭐ 🛸 |
| 9 | Pink + Candy | `#F48FB1` | 🍭 🍬 🎀 |

**Pattern styles** (10 entries, each with):
```dart
class PatternStyle {
  final List<String> emojis;
  final Color backgroundColor;
  final String label;
  const PatternStyle({required this.emojis, required this.backgroundColor, required this.label});
}
```

| # | Label | Background | Emojis |
|---|-------|-----------|--------|
| 0 | Stars | `#FFF9C4` | ⭐ 🌟 ✨ |
| 1 | Moons | `#E3F2FD` | 🌙 |
| 2 | Suns | `#FFFDE7` | ☀️ 🌤️ |
| 3 | Flowers | `#F3E5F5` | 🌸 🌺 |
| 4 | Butterflies | `#E8F5E9` | 🦋 🌿 |
| 5 | Hearts | `#FCE4EC` | ❤️ 💙 💚 |
| 6 | Fish | `#E0F2F1` | 🐠 🐡 🐟 |
| 7 | Party | `#FFF3E0` | 🎈 🎀 🎊 |
| 8 | Snow | `#FAFAFA` | ❄️ ⛄ 🌨️ |
| 9 | Sweets | `#FCE4EC` | 🍦 🍰 🧁 |

---

## 3. BrushEngine Rendering

### 3.1 Airbrush (`_paintAirbrush`)

Replace existing soft-dot implementation:

1. **Base stroke** — Draw the full point path as a single `Path` with `strokeWidth: 20.0`, `strokeCap: StrokeCap.round`, `strokeJoin: StrokeJoin.round`, fully opaque (`alpha: 255`) using `BrushTheme.airbrushThemes[stroke.themeIndex ?? 0].baseColor`.
2. **Emoji particles** — Walk the path; every ~30px of cumulative travel, pick one emoji from the theme's list (index = `(segmentIndex + stroke.hashCode) % emojis.length`). Render via `TextPainter` at font size 14–22px (randomly varied, seeded from `stroke.hashCode + pointIndex`), rotated ±30°, offset ±15px from the path centre.
3. **Single point** — Paint a 12px filled circle in `baseColor` + one emoji above it.

### 3.2 Pattern (`_paintPattern`)

**Tile generation:**

On first use of a given `themeIndex`, call `_generateTile(int index)`. This must only be called from inside `CustomPainter.paint()`, never from `shouldRepaint()`:
- Create `ui.PictureRecorder` + `Canvas`.
- Fill 80×80px background with `style.backgroundColor` using `canvas.drawRect`.
- Render the style's emojis in a grid arrangement using `TextPainter` at font size 28px. For each emoji, set `TextPainter.text`, `TextPainter.textDirection`, call `TextPainter.layout(maxWidth: double.infinity)`, then `TextPainter.paint(canvas, offset)`.
- Call `picture.toImageSync(80, 80)` → `ui.Image`.
- Store in `static final Map<int, ui.Image> _tileCache`.

**Tile cache lifecycle:** `ui.Image` holds GPU texture memory and must be explicitly disposed. Add a `static void disposeTileCache()` method to `BrushEngine` that calls `image.dispose()` on every cached entry and clears the map. Call `BrushEngine.disposeTileCache()` from `CanvasController.dispose()` — `CanvasController` already overrides `dispose()`, making it the natural owner of this cleanup.

> **Platform note:** `toImageSync()` is native-only (Skia/Impeller). It is unavailable on Flutter Web and will throw. Since CLAUDE.md lists Chrome as a local preview target, the Pattern brush must degrade gracefully on web: detect `kIsWeb` and skip tile generation, falling back to a plain opaque stroke in the pattern's `backgroundColor`. This is acceptable — web is dev-preview only; the real target is native iPad.

**Stroke rendering:**

Use `dart:typed_data`'s `Float64List` directly for the identity matrix — no `vector_math` dependency needed:

```dart
final shader = ImageShader(
  tile,
  TileMode.repeated,
  TileMode.repeated,
  Float64List.fromList([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]),
);
final paint = Paint()
  ..shader = shader
  ..strokeWidth = 40.0
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;
```

Draw the full point path as a single stroke. Result: drawing reveals a seamless wallpaper underneath.

**Single point** — 24px filled circle using the same `ImageShader`.

### 3.3 Splatter (`_paintSplatter`)

Replace existing random-dot implementation:

1. **Central blob** — Draw the full path as a stroke: `strokeWidth: 12.0`, `strokeCap: StrokeCap.round`, `alpha: 255`, using `stroke.color`.
2. **Directional droplets** — For each consecutive point pair `(p1, p2)`:
   - Compute direction unit vector `d = (p2 - p1) / (p2 - p1).distance`.
   - Scatter 6–14 droplets (count seeded from `stroke.hashCode + segmentIndex`):
     - 60% of droplets in a ±60° forward cone (higher velocity feel).
     - 40% in ±120° side spread.
     - Distance from path: 5–25px (seeded).
     - Radius: 2–8px (seeded).
     - Alpha: 255, color: `stroke.color`.
3. **Single point** — 8px filled circle at alpha 255 + 3 small droplets.

---

## 4. UI / Widget Layer

### 4.1 `ThemePickerWidget` (new file `lib/widgets/theme_picker_widget.dart`)

```
ThemePickerWidget
  props: BrushType brushType, int selectedIndex, ValueChanged<int> onThemeSelected
  layout: horizontal ListView (scrollDirection: Axis.horizontal)
  item size: 80×64px
  item anatomy:
    - Colored background (AirbrushTheme.baseColor or PatternStyle.backgroundColor)
    - 1–2 large emojis (font size 22px) centred
    - Short label below (font size 9px, bold)
    - Selected: deepPurple border 2.5px + AnimatedScale(scale: 1.05)
    - Unselected: grey border 1.5px
```

Reads from `BrushTheme.airbrushThemes` or `BrushTheme.patternStyles` based on `brushType`. Stateless — selection state is owned by `CanvasController`.

### 4.2 `ColoringScreen` bottom panel (`lib/screens/coloring_screen.dart`)

The bottom `Container` currently holds `BrushSelectorWidget` + `PaletteWidget` inside an `AnimatedBuilder`. The entire bottom panel column (including the new switcher) must be wrapped in a `ListenableBuilder` (or `AnimatedBuilder`) listening to `_controller` so that brush-type changes trigger a rebuild and `AnimatedSwitcher` receives a new child:

```
ListenableBuilder(listenable: _controller, builder: (_, __) =>
  Column:
    BrushSelectorWidget(...)    ← unchanged
    SizedBox(height: 10)
    AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      child: _controller.activeBrushType == BrushType.airbrush ||
             _controller.activeBrushType == BrushType.pattern
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
          )
    )
)
```

`ValueKey` on each child is required for `AnimatedSwitcher` to detect the widget swap and play the cross-fade. Without distinct keys it will not animate. Both children must have the same fixed height so the toolbar never jumps in size on switch.

---

## 5. Files Changed / Created

| File | Change |
|------|--------|
| `lib/brushes/stroke.dart` | Add `themeIndex` field + serialisation; update `copyWithPoint` |
| `lib/brushes/brush_theme.dart` | **New** — static theme/style data |
| `lib/brushes/brush_engine.dart` | Replace `_paintAirbrush`, `_paintPattern`, `_paintSplatter`; add `_tileCache` |
| `lib/canvas/canvas_controller.dart` | Add `_activeAirbrushThemeIndex`, `_activePatternThemeIndex`, `activeThemeIndex`, `setActiveTheme()`; update `startStroke()` and `dispose()` |
| `lib/widgets/theme_picker_widget.dart` | **New** — horizontal scrollable theme selector |
| `lib/screens/coloring_screen.dart` | Wrap bottom panel in `ListenableBuilder`; add `AnimatedSwitcher` between palette and theme picker |

**No changes to:** `DrawingPainter`, `CanvasStackWidget`, `SaveManager`, `DrawingRepository`, `BrushSelectorWidget`, `PaletteWidget`.

---

## 6. Constraints & Notes

- **Synchronous rendering:** `TextPainter`, `PictureRecorder`, and `toImageSync()` are all sync-safe inside `CustomPainter.paint()` on native targets.
- **Pattern on Web:** `toImageSync()` is unavailable on Flutter Web. Use `kIsWeb` guard to fall back to a plain opaque fill in the pattern's `backgroundColor`. Web is dev-preview only; real target is native iPad.
- **Pattern tile cache:** `static final Map<int, ui.Image> _tileCache` on `BrushEngine` — lazy, generated once per pattern index per session. `BrushEngine.disposeTileCache()` calls `image.dispose()` on all entries; called from `CanvasController.dispose()` to release GPU texture memory.
- **Deterministic randomness:** Airbrush particles and Splatter droplets seeded from `stroke.hashCode` — strokes replay identically on undo/redo and screen redraw.
- **`Stroke.color` for theme brushes:** Populated at stroke creation but ignored by `BrushEngine` for `airbrush` and `pattern`. `themeIndex` is authoritative for those two types.
- **Backward compatibility:** Existing strokes on disk load cleanly — `themeIndex` absent in old JSON reads as null, which is a valid state for all color-based brush types.
- **`ImageShader` matrix:** Use `Float64List.fromList([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1])` from `dart:typed_data` — no `vector_math` dependency needed.
