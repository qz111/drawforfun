# Right-Side Vertical Toolbar — Design Spec
**Date:** 2026-03-19
**Status:** Approved

---

## Problem

The bottom `DraggableScrollableSheet` toolbar overflows on smaller screens because the `BrushSelectorWidget` renders 6 tiles × 60px wide = ~420px in a horizontal row. The design must be replaced to eliminate the overflow and improve ergonomics on iPad.

---

## Design Decision

Replace the bottom sheet with a **right-side vertical toolbar** composed of two frosted-glass panels:

1. **Brush Rail** — always visible, shows all 6 brush icons
2. **Options Strip** — slides in when a brush is tapped, shows that brush's options as a vertically scrollable list

---

## Layout

```
┌───────────────────────────────────────────────────────┐
│  [←]                          [↩️]  [🗑️]  [💾]       │  ← top bar, UNCHANGED
├──────────────────────────────────────────┬──────┬─────┤
│                                          │Opts  │Rail │
│                  Canvas                  │Strip │     │
│                                          │(72px)│(64px│
└──────────────────────────────────────────┴──────┴─────┘
```

- **Top bar**: completely unchanged — back button `Positioned(top:0, left:0)`, undo/clear/save `Positioned(top:0, right:0)`
- **Brush Rail**: `Positioned(right: 0, top: topBarOffset, bottom: 0)`, 64px wide
- **Options Strip**: `Positioned(right: 64, top: topBarOffset, bottom: 0)`, 72px wide, slides in/out
- **`topBarOffset`**: computed at runtime as `MediaQuery.of(context).padding.top + 76` (76px = 16 top padding + 44px button height + 16 bottom padding). This ensures the panels never overlap the top bar on any device, including iPad with Face ID notch.
- Canvas takes full screen — panels slightly overlay the right edge of the canvas (acceptable on iPad)

---

## State Ownership

All toolbar state lives in `_ColoringScreenState`:

```dart
bool _isStripOpen = false;
```

- Tapping a brush tile:
  - If it is a **different** brush: select it, open the strip
  - If it is the **same** brush: toggle `_isStripOpen`
- The strip stays open while the user draws on the canvas — children tap the canvas freely and the strip remains accessible
- `_isStripOpen` and brush selection are passed down as props to both `BrushRailWidget` and `OptionsStripWidget`

---

## Brush Rail

- **Size**: 64px wide, full height below top bar
- **Style**: frosted glass (`BackdropFilter` blur + `Color.fromRGBO(255, 255, 255, 0.78)`), rounded left corners only (`BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28))`)
- **Content**: `Column` with `MainAxisAlignment.spaceEvenly`, 6 brush tiles
- **Each tile**: 44px × 44px tap target, icon only (no label — rail is too narrow)
  - Selected: accent color icon + filled accent background circle
  - Unselected: muted grey icon, transparent background

### Brush → Icon mapping (unchanged)
| Brush | Icon |
|-------|------|
| Pencil | `Icons.edit` |
| Marker | `Icons.brush` |
| Airbrush | `Icons.blur_on` |
| Pattern/Stars | `Icons.star` |
| Splatter | `Icons.scatter_plot` |
| Eraser | `Icons.auto_fix_normal` |

### `BrushRailWidget` signature
```dart
class BrushRailWidget extends StatelessWidget {
  final BrushType selectedBrush;
  final bool isStripOpen;
  final ValueChanged<BrushType> onBrushSelected;   // owned by _ColoringScreenState
  final VoidCallback onToggleStrip;
  // ...
}
```

---

## Options Strip

- **Size**: 72px wide, same height as brush rail
- **Style**: frosted glass, rounded left corners only, slightly less opaque (`Color.fromRGBO(255, 255, 255, 0.65)`) than the rail to create visual depth
- **Animation**: `AnimatedSlide` + `AnimatedOpacity` wrapping the entire strip widget
  - Hidden state: `offset = Offset(1.0, 0.0)` (one strip-width to the right, hidden behind the rail), `opacity = 0`
  - Visible state: `offset = Offset(0.0, 0.0)`, `opacity = 1`
  - Duration: 200ms, curve: `Curves.easeOut`
  - Both animations run simultaneously. `IgnorePointer(ignoring: !isVisible)` wraps the strip to block taps when hidden.
- **Content switching**: content is rebuilt directly (no `AnimatedSwitcher`) when the active brush changes — the strip animates closed and open on brush switch, making a cross-fade redundant
- **Strip stays open** while drawing; no auto-dismiss on canvas tap

### Content per brush type

| Brush | Content | Items | Tile size in strip |
|-------|---------|-------|--------------------|
| Pencil, Marker, Splatter | Vertical color palette | 24 color circles | 44px circle, centered |
| Airbrush, Pattern | Vertical theme picker | 10 theme tiles | 56×56px |
| Eraser | Vertical size picker | 3 size tiles (S/M/L) | 56×64px |

### `OptionsStripWidget` signature
```dart
class OptionsStripWidget extends StatelessWidget {
  final bool isVisible;
  final BrushType activeBrush;
  final CanvasController controller;   // provides activeColor, activeThemeIndex, setActiveColor, setActiveTheme
  // ...
}
```

---

## Widget Changes Required

### `PaletteWidget`
- Add `axis: Axis` parameter (default `Axis.horizontal` for backwards compatibility)
- Vertical variant: replace `Wrap` with a `ListView` (single column), tiles 44px circles centered in 72px strip
- **24 colors only** — the existing `ColorPalette.eraser` sentinel color is removed from the palette list in vertical mode (eraser is now a first-class brush in the rail, not a palette shortcut)

### `ThemePickerWidget`
- Add `axis: Axis` parameter (default `Axis.horizontal`)
- Vertical variant: `scrollDirection: Axis.vertical`, tile resized to `56×56px`
- **Drop the text label** in vertical mode (56px width is too narrow for a 9px label alongside a 22px emoji at child-friendly sizes)

### `EraserSizePickerWidget`
- Add `axis: Axis` parameter (default `Axis.horizontal`)
- Vertical variant: `scrollDirection: Axis.vertical`, tile resized to `56×64px` (from current `60×70px`)

### `coloring_screen.dart`
- Remove `DraggableScrollableSheet` and all its children
- Add `_isStripOpen` state and toggle logic
- Add `BrushRailWidget` and `OptionsStripWidget` as `Positioned` children in the `Stack`
- Top bar widgets: **no changes**

---

## New Files

| File | Purpose |
|------|---------|
| `lib/widgets/brush_rail_widget.dart` | Frosted glass vertical rail of 6 brush icon tiles |
| `lib/widgets/options_strip_widget.dart` | Animated frosted glass vertical options strip |

---

## Removed

- `DraggableScrollableSheet` and all its children from `coloring_screen.dart`
- `BrushSelectorWidget` is superseded by `BrushRailWidget` (old file can be deleted after migration)

---

## Non-Goals

- No changes to canvas, drawing logic, stroke handling, save/load
- No changes to top bar (back, undo, clear, save)
- No iPad-specific breakpoints — design works for all screen sizes
