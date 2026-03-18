# Visual Overhaul Design Spec
**Project:** DrawForFun — Children's Coloring App (Flutter/iPad)
**Date:** 2026-03-18
**Status:** Approved (rev 2 — post spec-review fixes)

---

## 1. Brand Identity

**Theme:** Modern, Simple, Magical Cartoon Procreate
**Target audience:** Children aged 3–8, iPad-primary
**Design language:** Claymorphism — soft 3D, rounded, toy-like, frosted glass surfaces
**Typography:** Fredoka (display/headings) + Nunito (body/UI copy) — unchanged from current

---

## 2. Design Tokens

### 2.1 Colour Palette (`AppColors` — full replacement)

Old token `accentLight` (`#A78BFA`) is **deleted**. Every existing reference must be replaced during Phase 1 migration (see §3.3 migration notes).

| Token | Dart constant | Role |
|---|---|---|
| `gradientStart` | `Color(0xFFAAFFD4)` | Mint — top of magical sky |
| `gradientMid` | `Color(0xFFC8F0FF)` | Ice-blue — sky mid |
| `gradientEnd` | `Color(0xFFFFD6F5)` | Candy-pink — sky bottom |
| `accentPrimary` | `Color(0xFF7C6FF7)` | Soft indigo-violet (primary actions) |
| `accentSecondary` | `Color(0xFFF472B6)` | Soft candy-pink (secondary accents) |
| `accentMint` | `Color(0xFF34D399)` | Mint — positive/success actions |
| `accentPeach` | `Color(0xFFFDBA74)` | Warm peach — highlight / warm CTA |
| `surface` | `Color.fromRGBO(255,255,255,0.72)` | Frosted-glass card/panel surface |
| `textPrimary` | `Color(0xFF2D2640)` | Near-black heading text |
| `textMuted` | `Color(0xFF7C7490)` | Secondary / helper text |
| `success` | `Color(0xFF10B981)` | Unchanged |
| `warning` | `Color(0xFFF59E0B)` | Unchanged |
| `danger` | `Color(0xFFEF4444)` | Unchanged |

> `background` is no longer a flat colour token — the magical sky gradient is the background (see §3.1). `AppTheme.build()` sets `scaffoldBackgroundColor: Colors.transparent`.

### 2.2 Radius (`AppRadius` — unchanged)

```dart
outer  = 50.0   // pill panels / modals
card   = 32.0   // cards, menu tiles
button = 20.0   // buttons, toolbar tiles
small  = 12.0   // chips, small surfaces
```

### 2.3 Gradients (`AppGradients`)

| Name | Dart type | Stops | Angle | Usage |
|---|---|---|---|---|
| `magicalSky` | `LinearGradient` | `#AAFFD4 → #C8F0FF → #FFD6F5` | `begin: topLeft, end: bottomRight` | Global app background |
| `primaryButton` | `LinearGradient` | `#A5F3D0 → #7C6FF7` | `begin: topLeft, end: bottomRight` | Primary CTAs |
| `appBar` | — | **retired** | — | Removed; floating buttons replace it |

### 2.4 Shadows (`AppShadows`)

All shadow `Color` values use `Color.fromRGBO(...)`, never CSS rgba strings.

- `clay(color)` — existing 3-layer system retained. The **white inner gloss** (3rd layer) is kept unchanged. A **4th ambient layer** is added: `BoxShadow(color: Color.fromRGBO(255,182,213,0.18), blurRadius: 32, offset: Offset(0,12))` — subtle candy-pink glow.
- `soft(color)` — outer shadow colour remains `color.withValues(alpha:0.15)`; inner white gloss unchanged.
- `frosted` (**new**): `BoxShadow(color: Color.fromRGBO(180,200,255,0.20), blurRadius: 24, offset: Offset(0,8))` — used on all frosted-glass panels.

---

## 3. Phase 1 — Foundation Layer

**Goal:** Global background, updated tokens, spring animation, `MainMenuScreen` token cleanup. Zero breaking regressions on all screens.

### 3.1 `MagicalSkyBackground` widget

**File:** `lib/widgets/magical_sky_background.dart`

A new `StatefulWidget` that paints the magical sky gradient + sparkle layer as a full-screen background. It is inserted via **`MaterialApp.builder`** in `app.dart`:

```dart
// app.dart
MaterialApp(
  builder: (context, child) => MagicalSkyBackground(child: child!),
  ...
)
```

This means every route (including `ContourCreatorScreen`) inherits the background automatically. All per-screen `BoxDecoration` gradient `Container` wrappers are removed.

**`MagicalSkyBackground` implementation:**
- Root widget: `Stack` → `[gradient layer, sparkle layer (IgnorePointer), child]`
- Gradient layer: `Container(decoration: BoxDecoration(gradient: AppGradients.magicalSky))`, `fit: BoxFit.cover`
- Sparkle layer: `CustomPaint(painter: _SparklePainter(animation), size: Size.infinite)`, wrapped in `IgnorePointer` so touches pass through
- Single `AnimationController(vsync: this, duration: Duration(seconds: 12))` repeating, drives all particle positions
- `_SparklePainter`: 12 particles, each with a fixed seed offset; position computed as sinusoidal drift from seed; painted as `MaskFilter.blur(BlurStyle.normal, 3)` filled circle; colours cycling through `[gradientStart, gradientMid, gradientEnd]`; opacity 0.4–0.8

**`ContourCreatorScreen` temporary mitigation:** `ContourCreatorScreen`'s `Scaffold` does not need changes — it inherits the gradient via `MaterialApp.builder`. However its existing `AppTheme.gradientAppBar()` call will continue to render with the old gradient colours until a future spec addresses it. This is an accepted known visual inconsistency, not a regression.

### 3.2 `ClayInkWell` spring update

- Press scale: `1.0 → 0.94` (was `0.92`)
- Press: `_ctrl.forward()` unchanged (120 ms `AnimationController`)
- **Release:** Remove `_ctrl.reverse()` and `reverseDuration`. Use physics-driven release:
  ```dart
  void _onTapUp(TapUpDetails _) {
    _ctrl.animateWith(SpringSimulation(
      SpringDescription(mass: 1, stiffness: 300, damping: 20),
      _ctrl.value, // from current compressed position
      0.0,         // to rest (scale = 1.0)
      0.0,         // initial velocity
    ));
  }
  ```
  Same call in `_onTapCancel`.
- `reverseDuration` field is removed from `AnimationController` constructor.

### 3.3 `AppTheme` token migration

**Steps (in order — prevents compile errors mid-migration):**

1. Add all new tokens to `AppColors`, keeping old tokens temporarily (both exist)
2. Replace every reference to `AppColors.accentLight` across the codebase:
   - `template_lib_screen.dart` `_CreateBlankCard` border → `AppColors.accentPrimary.withValues(alpha:0.5)`
   - `app_theme.dart` `primaryButton` gradient → already updated in §2.3
3. Remove `AppColors.accentLight` and `AppColors.background` (old flat colour)

> **Note — intentional colour value shifts:** `accentPrimary` changes from `#7C3AED` (vivid violet) to `#7C6FF7` (softer indigo-violet) and `textPrimary` changes from `#332F3A` to `#2D2640`. These are deliberate brand updates. After token replacement, run `flutter run -d windows` and visually verify all screens — including out-of-scope screens like `ContourCreatorScreen` — for unintended colour changes before committing.
4. Update `AppGradients`: add `magicalSky`, replace `primaryButton` stops, keep `appBar` for now (library screens still reference it in Phase 1 — it is removed in Phase 3)
5. Update `AppShadows`: add `frosted`, add 4th layer to `clay()`
6. Update `AppTheme.build()`: set `scaffoldBackgroundColor: Colors.transparent`
7. Run `flutter analyze` — zero errors required before proceeding

**`MainMenuScreen` updates (Phase 1 scope):**
- Remove the `BoxDecoration` gradient `Container` body wrapper (background now from `MagicalSkyBackground`)
- Replace `ShaderMask` + `AppGradients.appBar` on the logo title with `ShaderMask` + `AppGradients.magicalSky`
- Update `_MenuCard` border colour: `AppColors.accentLight` → `AppColors.accentPrimary.withValues(alpha:0.3)`

---

## 4. Phase 2 — Coloring Screen

**Goal:** Remove AppBar, replace with floating buttons; rebuild bottom panel as collapsible frosted sheet.

### 4.1 AppBar removal + back-navigation safety

The `Scaffold.appBar` in `ColoringScreen` is removed.

**`PopScope` is retained** (critical — handles hardware back button and iOS/iPadOS swipe-back gesture):

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    // same _autoSave logic as before
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);
    await _autoSave();
    if (mounted) {
      setState(() => _isSaving = false);
      navigator.pop();
    }
  },
  child: Scaffold(...),
)
```

The `_FloatingBackButton` calls the same `onPopInvokedWithResult` logic via a shared private method `_handleBack()` to avoid duplication.

**`_FloatingBackButton`** (top-left, `Positioned` inside `Stack`):
- `SafeArea` → `Padding(top:16, left:16)`
- 44×44 px `ClayInkWell` wrapping a `ClipRRect(borderRadius: BorderRadius.circular(22))` → `BackdropFilter(ImageFilter.blur(sigmaX:12,sigmaY:12))` → `Container`
- `Container` `decoration`: `BorderRadius.circular(22)`, `color: AppColors.surface`, `AppShadows.soft(AppColors.accentPrimary)`
- `ClipRRect` is required so the blur is clipped to the circle — without it the frosted effect bleeds beyond the rounded corners
- Icon: `Icons.arrow_back_ios_new`, size 20, `color: AppColors.textPrimary`
- `onTap`: calls `_handleBack()`

**`_FloatingActions`** row (top-right, `Positioned` inside `Stack`):
- `SafeArea` → `Padding(top:16, right:16)`
- `Row` of 3 frosted circles, `gap: 8`
- Each circle: `ClipRRect(borderRadius: BorderRadius.circular(22))` → `BackdropFilter(blur:12)` → `Container(decoration: same as back button)` — same `ClipRRect` requirement applies
- Icons: `Icons.undo`, `Icons.delete_outline`, `Icons.save_alt`

### 4.2 `DraggableScrollableSheet` bottom panel

The sheet is placed as the **last child** of the `Stack` that already contains the canvas `Column`. The canvas `Column` uses `Expanded` to fill all available space; the sheet overlaps it from the bottom. This is correct `Stack` behaviour — no additional height constraint wrapper needed. The sheet does not cause layout reflow because it is `Stack`-positioned and uses `Transform`/`opacity` internally.

```
minChildSize:     0.08   → ~56 px pill — drag handle visible, brush row clipped
initialChildSize: 0.22   → brush row + colour swatches fully visible
maxChildSize:     0.38   → brush row + palette/theme/eraser panel fully visible
snapSizes:        [0.08, 0.22, 0.38]   → snap points for child-friendly UX
snap:             true
```

> `snapSizes` with `snap: true` means a simple tap on the drag handle at `minChildSize` snaps to `0.22` — no fine-motor drag required for young children (addresses child UX concern).

**Sheet decoration:**
- Background: `Color.fromRGBO(255,255,255,0.78)` + `BackdropFilter(ImageFilter.blur(sigmaX:18,sigmaY:18))`
- `BorderRadius.vertical(top: Radius.circular(28))`
- `AppShadows.frosted` drop shadow
- Top drag handle: `Container(width:32, height:4, decoration: BoxDecoration(color: Color.fromRGBO(0,0,0,0.15), borderRadius: BorderRadius.circular(2)))`, centered, 10 px top padding

**Sheet content (top to bottom):**
1. Drag handle (always rendered)
2. `BrushSelectorWidget` row
3. `SizedBox(height: 10)`
4. `AnimatedSwitcher` — `PaletteWidget` / `ThemePickerWidget` / `EraserSizePickerWidget` (logic unchanged, re-skinned)

> `BackdropFilter` on Windows Desktop (dev target): renders correctly but may show subtle artefacts in debug mode. Verify visually on `flutter run -d windows` before Phase 2 sign-off.

---

## 5. Phase 3 — Library Cards & Carousels

**Goal:** Replace `DrawingCardWidget` with `PolaroidCardWidget`; restyle library AppBars; add centre-item carousel scaling.

### 5.1 Library screen AppBar updates

`TemplateLibScreen` and `MyUploadLibScreen` retain their `AppBar` (not removed — library screens suit a visible title bar). The `AppTheme.gradientAppBar()` helper is **updated in Phase 3** to use `AppGradients.magicalSky` instead of the retired `appBar` gradient. After this update `AppGradients.appBar` is deleted from `app_theme.dart`.

### 5.2 `PolaroidCardWidget`

**File:** `lib/widgets/polaroid_card_widget.dart`

Drop-in replacement for `DrawingCardWidget` — identical public API (same named parameters). Call sites in `TemplateLibScreen` and `MyUploadLibScreen` change only the class name.

**Structure:**
```
Transform.rotate(angle)               ← alternating by card index
  Stack
    Container (white card)            ← BorderRadius.circular(12), hard drop shadow
      Column
        _ImageArea (140 px height)    ← gradient bg + plant emoji + sparkle + thumbnail
        _LabelStrip (44 px height)    ← Fredoka 12px bold + status pill
    Positioned (washi tape)           ← top-center, overhangs card top by 8 px, outside ClipRRect
    Positioned (delete button)        ← outside rotated subtree — see note below
```

**Tilt:**
- `index % 2 == 0` → `Transform.rotate(angle: -0.04)`
- `index % 2 == 1` → `Transform.rotate(angle: 0.05)`

**Image area (`_ImageArea`):**
- Background gradient per `index % 4`:
  - 0: `Color(0xFFAAFFD4)` → `Color(0xFF67E8F9)` (mint → cyan)
  - 1: `Color(0xFFC8F0FF)` → `Color(0xFFA5F3FB)` (ice-blue → sky)
  - 2: `Color(0xFFFDBA74)` → `Color(0xFFFCA5A5)` (peach → coral)
  - 3: `Color(0xFFFFD6F5)` → `Color(0xFFFBCFE8)` (candy-pink → rose)
- Plant emoji at `Positioned(bottom:4, left:6)`: `['🌿','🌸','🌻','🌺'][index % 4]`, `fontSize: 18`, clipped by parent `ClipRRect`
- Star at `Positioned(top:6, right:8)`: `'✨'`, `fontSize: 11`
- Thumbnail/SVG/emoji placeholder: same logic as `DrawingCardWidget._buildThumbnail()` — no changes

**Washi tape (`Positioned` above card):**
- `Positioned(top: -8, left: 0, right: 0)` → `Center` → `Transform.rotate(angle: 0.02)`
- `Container(width:44, height:14, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: LinearGradient(...)))` at opacity 0.65
- Tape gradient colours cycling `index % 4`: violet `#A78BFA`, yellow `#FDE68A`, mint `#6EE7B7`, pink `#FBCFE8`

**Delete button — hit-test safety:**
The delete button is placed in an **outer `Stack`** wrapping the `Transform.rotate`, not inside the rotated subtree. This ensures the hit area matches the visible button position after rotation:

```dart
// Outer stack — delete button sits here, unrotated
Stack(
  clipBehavior: Clip.none,
  children: [
    Transform.rotate(angle: ..., child: _card),  // rotated card
    if (onDelete != null)
      Positioned(
        top: 8, right: 8,
        child: _DeleteButton(onDelete: onDelete!),
      ),
  ],
)
```

**Label strip (`_LabelStrip`):**
- `Container(height:44, color: Colors.white, padding: EdgeInsets.symmetric(horizontal:8))`
- `Text(label)`: Fredoka 12 px bold, `AppColors.textPrimary`
- Status pill: same logic as current — coloured pill if `hasThumbnail`, grey if not

### 5.3 Carousel centre-item scaling

Applied to both carousels in `TemplateLibScreen` and `MyUploadLibScreen`.

**Layout change:** `ListView` gains `itemExtent: 212` (200 card + 12 gap) to make item positions mathematically predictable. The existing `Padding(right:12)` wrapper is replaced by `itemExtent` spacing.

**Scroll controller + scaling:**
```dart
final _scrollCtrl = ScrollController();
// in initState: _scrollCtrl.addListener(() => setState((){}));

// in itemBuilder:
final viewportWidth = MediaQuery.of(context).size.width;
final scrollOffset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
final itemCenter = index * 212.0 + 100.0;  // 100 = cardWidth/2
final viewportCenter = scrollOffset + viewportWidth / 2;
final distance = (itemCenter - viewportCenter).abs();
final scale = lerpDouble(1.0, 0.88, (distance / 160.0).clamp(0.0, 1.0))!;

return Transform.scale(scale: scale, child: PolaroidCardWidget(...));
```

No layout reflow — `Transform.scale` does not affect neighbouring items' positions.

> **Performance note:** `_scrollCtrl.addListener(() => setState((){}))` rebuilds the list on every scroll pixel. On a 120 Hz iPad Pro this can cause jank. If profiling reveals dropped frames, replace top-level `setState` with a `ValueNotifier<double>` scoped to the `ListView` builder — only the builder subtree rebuilds on each tick rather than the full screen.

---

## 6. Component Inventory

| Component | Phase | File | Action |
|---|---|---|---|
| `MagicalSkyBackground` | 1 | `lib/widgets/magical_sky_background.dart` | **New** |
| `AppColors` / `AppGradients` / `AppShadows` / `AppTheme` | 1 | `lib/theme/app_theme.dart` | **Update** |
| `ClayInkWell` | 1 | `lib/widgets/clay_ink_well.dart` | **Update** |
| `MainMenuScreen` background + logo gradient | 1 | `lib/screens/main_menu_screen.dart` | **Update** |
| `_FloatingBackButton` + `_FloatingActions` | 2 | `lib/screens/coloring_screen.dart` | **New (private)** |
| `ColoringScreen` bottom panel | 2 | `lib/screens/coloring_screen.dart` | **Update** |
| `PolaroidCardWidget` | 3 | `lib/widgets/polaroid_card_widget.dart` | **New** |
| `AppTheme.gradientAppBar()` — sky gradient | 3 | `lib/theme/app_theme.dart` | **Update** |
| `TemplateLibScreen` carousel + AppBar | 3 | `lib/screens/template_lib_screen.dart` | **Update** |
| `MyUploadLibScreen` carousel + AppBar | 3 | `lib/screens/my_upload_lib_screen.dart` | **Update** |

---

## 7. Out of Scope

- `ContourCreatorScreen` — inherits `MagicalSkyBackground` via `MaterialApp.builder` (no black screen); its AppBar retains old gradient until a future spec
- Dark mode — not applicable for this audience
- Font loading changes — Fredoka + Nunito already wired via `google_fonts`
- Sound / haptic feedback — separate future spec
- Particle physics engine / third-party package — sparkles use `CustomPainter` only

---

## 8. Testing Gates (per phase)

Each phase passes when:
1. `flutter analyze` returns zero errors/warnings
2. `flutter run -d windows` renders without layout overflows, black screens, or transparent Scaffolds
3. `BackdropFilter` frosted panels render visibly (not black) on the Windows target
4. Visual QA sign-off from user (acknowledged visual blindness — user reviews app screenshots after each phase)
