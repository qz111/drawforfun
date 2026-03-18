# Visual Overhaul Design Spec
**Project:** DrawForFun — Children's Coloring App (Flutter/iPad)
**Date:** 2026-03-18
**Status:** Approved

---

## 1. Brand Identity

**Theme:** Modern, Simple, Magical Cartoon Procreate
**Target audience:** Children aged 3–8, iPad-primary
**Design language:** Claymorphism — soft 3D, rounded, toy-like, frosted glass surfaces
**Typography:** Fredoka (display/headings) + Nunito (body/UI copy) — unchanged from current

---

## 2. Design Tokens

### 2.1 Colour Palette (`AppColors` — full replacement)

| Token | Hex | Role |
|---|---|---|
| `gradientStart` | `#AAFFD4` | Mint — top of magical sky |
| `gradientMid` | `#C8F0FF` | Ice-blue — sky mid |
| `gradientEnd` | `#FFD6F5` | Candy-pink — sky bottom |
| `accentPrimary` | `#7C6FF7` | Soft indigo-violet (primary actions) |
| `accentSecondary` | `#F472B6` | Soft candy-pink (secondary accents) |
| `accentMint` | `#34D399` | Mint — positive/success actions |
| `accentPeach` | `#FDBA74` | Warm peach — highlight / warm CTA |
| `surface` | `rgba(255,255,255,0.72)` | Frosted-glass card/panel surface |
| `background` | gradient (see §2.3) | Magical sky — never a flat colour |
| `textPrimary` | `#2D2640` | Near-black heading text |
| `textMuted` | `#7C7490` | Secondary / helper text |
| `success` | `#10B981` | Unchanged |
| `warning` | `#F59E0B` | Unchanged |
| `danger` | `#EF4444` | Unchanged |

### 2.2 Radius (`AppRadius` — unchanged)

```dart
outer  = 50.0   // pill panels / modals
card   = 32.0   // cards, menu tiles
button = 20.0   // buttons, toolbar tiles
small  = 12.0   // chips, small surfaces
```

### 2.3 Gradients (`AppGradients`)

| Name | Stops | Angle | Usage |
|---|---|---|---|
| `magicalSky` | `#AAFFD4 → #C8F0FF → #FFD6F5` | 160° | Global app background |
| `primaryButton` | `#A5F3D0 → #7C6FF7` | 135° TL→BR | Primary CTAs |
| `appBar` | retired | — | Replaced by floating buttons |

### 2.4 Shadows (`AppShadows`)

- `clay(color)` — existing 3-layer system, third layer updated to candy-pink ambient tint
- `soft(color)` — existing, outer shadow tinted to mint
- `frosted` — new: `BoxShadow(color: rgba(180,200,255,0.20), blurRadius: 24, offset: (0,8))` for frosted panels

---

## 3. Phase 1 — Foundation Layer

**Goal:** Global background, updated tokens, spring animation. Zero screen regressions.

### 3.1 `MagicalSkyBackground` widget

- New `StatefulWidget` in `lib/widgets/magical_sky_background.dart`
- Wraps `Scaffold` body with a 3-stop `LinearGradient` using `AppGradients.magicalSky`
- Hosts a `CustomPainter` sparkle layer:
  - 12 soft-glow circles, diameters 4–10 px
  - Colours sampled from gradient triad (mint / ice-blue / candy-pink)
  - Each drifts on a slow sinusoidal path, cycle 8–14 s, driven by a single `AnimationController(duration: 12s)` + `Tween` per particle
  - Opacity range 0.4–0.8, no sharp edges (painted with `MaskFilter.blur`)
- Inserted in `app.dart` as the root body wrapper; all screens inherit it automatically
- Per-screen `BoxDecoration` gradient backgrounds are removed

### 3.2 `ClayInkWell` spring update

- Press scale: `1.0 → 0.94` (was `0.92`) — slightly less aggressive
- Release: replace `Curves.easeOut` reverse with a `SpringSimulation` (stiffness: 300, damping: 20) — gives a physical "pop back" feel
- Press duration: 120 ms unchanged

### 3.3 `AppTheme` token migration

- `AppColors` updated to new palette (§2.1)
- `AppGradients.magicalSky` added; `appBar` gradient kept in code but marked deprecated
- `AppShadows.frosted` added
- `AppTheme.build()` updated: `scaffoldBackgroundColor` set to `Colors.transparent` (background now comes from `MagicalSkyBackground`)

---

## 4. Phase 2 — Coloring Screen

**Goal:** Remove AppBar, replace with floating buttons; rebuild bottom panel as collapsible frosted sheet.

### 4.1 AppBar removal

The `AppTheme.gradientAppBar()` call in `ColoringScreen` is removed. Replaced with two floating overlays in the `Stack`:

**`_FloatingBackButton`** (top-left):
- 44×44 px `ClayInkWell` wrapping a `Container`
- `decoration`: `BorderRadius.circular(22)`, `color: AppColors.surface`, `BackdropFilter(blur: 12)`, `AppShadows.soft()`
- Contains `Icons.arrow_back_ios_new`, size 20, `color: AppColors.textPrimary`
- Triggers `_autoSave()` then `Navigator.pop()` (same logic as current `PopScope`)

**`_FloatingActions`** row (top-right):
- Row of 3 frosted circles (same decoration as back button): undo, clear, save
- 8 px gap between items
- Icons: `Icons.undo`, `Icons.delete_outline`, `Icons.save_alt`

Both overlays sit inside the existing `Stack`, above the canvas column, with `SafeArea` padding: top 16 px, horizontal 16 px.

### 4.2 `DraggableScrollableSheet` bottom panel

Replaces the current `Container` bottom panel. Implemented as a `DraggableScrollableSheet` child inside the `Stack`:

```
minChildSize:     0.08   → 56 px pill — drag handle + brush row only
initialChildSize: 0.22   → brush row + colour swatches visible
maxChildSize:     0.38   → brush row + palette/theme full height
```

**Sheet decoration:**
- Background: `rgba(255,255,255,0.78)` + `BackdropFilter(ImageFilter.blur(sigmaX:18, sigmaY:18))`
- `BorderRadius.vertical(top: Radius.circular(28))`
- `AppShadows.frosted` drop shadow
- Top drag handle: 32×4 px `Container`, `BorderRadius.circular(2)`, `rgba(0,0,0,0.15)`, centered, 10 px top padding

**Sheet content (top to bottom):**
1. Drag handle (always visible)
2. `BrushSelectorWidget` row (always visible when `childSize >= 0.08`)
3. 10 px gap
4. `AnimatedSwitcher` — `PaletteWidget` / `ThemePickerWidget` / `EraserSizePickerWidget` (visible when `childSize >= 0.22`) — unchanged logic, re-skinned

**`PopScope` behaviour:** `_autoSave` now triggered from `_FloatingBackButton.onTap` instead of `PopScope`. `PopScope` is removed.

---

## 5. Phase 3 — Library Cards & Carousels

**Goal:** Replace `DrawingCardWidget` with `PolaroidCardWidget`; add centre-item carousel scaling.

### 5.1 `PolaroidCardWidget`

New widget in `lib/widgets/polaroid_card_widget.dart`. Replaces `DrawingCardWidget` in both `TemplateLibScreen` and `MyUploadLibScreen`.

**Structure:**
```
Transform.rotate(angle)          ← alternating ±0.04–0.05 rad by index
  Stack
    Container (white card)       ← BorderRadius.circular(12), hard shadow
      Column
        image area (140 px)      ← gradient bg + plant emoji + thumbnail/SVG
        label strip (44 px)      ← Fredoka 12px bold + status pill
    Positioned washi tape        ← top-center, overhangs by 8 px
```

**Image area:**
- Background: per-card gradient from a 4-colour cycle: `[mint, ice-blue, peach, candy-pink]` at index `% 4`
- Plant emoji accent: one of `['🌿','🌸','🌻','🌺']` at index `% 4`, `fontSize: 18`, `Positioned(bottom: 4, left: 6)`, partially clipped by `ClipRRect`
- Star sparkle: `✨`, `fontSize: 11`, `Positioned(top: 6, right: 8)`
- Template SVG / thumbnail / emoji placeholder: unchanged logic from current `DrawingCardWidget._buildThumbnail()`

**Washi tape:**
- `Transform.rotate(angle: 0.02)`
- `Container(width: 44, height: 14)`, `BorderRadius.circular(3)`
- `decoration`: semi-transparent gradient from accent colour at `0.65` opacity
- 4 tape colour variants cycling at `index % 4`: violet, yellow, mint, pink

**Tilt:**
- `index % 2 == 0` → `Transform.rotate(angle: -0.04)`
- `index % 2 == 1` → `Transform.rotate(angle: 0.05)`

**Delete button:** retained as `Positioned(top:8, right:8)` — same as current, re-skinned.

**API:** identical to `DrawingCardWidget` — same named parameters, drop-in replacement.

### 5.2 Carousel centre-item scaling

Applied to `ListView` in `TemplateLibScreen` and `MyUploadLibScreen`:

- Each carousel gets a `ScrollController`
- A `ValueNotifier<double> _scrollOffset` drives `setState`
- In `itemBuilder`, each item's `center distance from viewport centre` is computed:
  ```dart
  final itemCenter = index * (cardWidth + gap) + cardWidth / 2;
  final viewportCenter = scrollOffset + viewportWidth / 2;
  final distance = (itemCenter - viewportCenter).abs();
  final scale = lerpDouble(1.0, 0.88, (distance / 160.0).clamp(0.0, 1.0))!;
  ```
- Item wrapped in `Transform.scale(scale: scale)` — no layout reflow
- `gap: 12`, `cardWidth: 200` (unchanged)

---

## 6. Component Inventory

| Component | Phase | File | Status |
|---|---|---|---|
| `MagicalSkyBackground` | 1 | `lib/widgets/magical_sky_background.dart` | New |
| `AppColors` / `AppGradients` / `AppShadows` / `AppTheme` | 1 | `lib/theme/app_theme.dart` | Update |
| `ClayInkWell` | 1 | `lib/widgets/clay_ink_well.dart` | Update |
| `_FloatingBackButton` | 2 | `lib/screens/coloring_screen.dart` | New (private) |
| `_FloatingActions` | 2 | `lib/screens/coloring_screen.dart` | New (private) |
| `ColoringScreen` bottom panel | 2 | `lib/screens/coloring_screen.dart` | Update |
| `PolaroidCardWidget` | 3 | `lib/widgets/polaroid_card_widget.dart` | New |
| `TemplateLibScreen` carousel | 3 | `lib/screens/template_lib_screen.dart` | Update |
| `MyUploadLibScreen` carousel | 3 | `lib/screens/my_upload_lib_screen.dart` | Update |

---

## 7. Out of Scope

- `ContourCreatorScreen` — no visual overhaul in this spec
- Dark mode — not applicable for this audience
- Custom font loading changes — Fredoka + Nunito already wired via `google_fonts`
- Sound / haptic feedback — separate future spec
- Particle physics engine / third-party package — sparkles use `CustomPainter` only

---

## 8. Testing Gates (per phase)

Each phase passes when:
1. `flutter analyze` returns zero errors
2. `flutter run -d windows` renders without layout overflows or black screens
3. Visual QA sign-off from user (acknowledged visual blindness — user reviews screenshots)
