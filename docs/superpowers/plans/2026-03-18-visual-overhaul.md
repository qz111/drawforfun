# Visual Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the DrawForFun coloring app with a "Magical Cartoon Procreate" visual identity — candy-pastel sky background, spring-physics press animations, frosted-glass coloring toolbar, and polaroid-style library cards.

**Architecture:** Three independent phases, each shippable. Phase 1 = design token + background foundation (every screen benefits immediately). Phase 2 = coloring screen floating UI. Phase 3 = library card overhaul + carousel scaling. All phases are additive — no phase breaks a previous one.

**Tech Stack:** Flutter/Dart, Material 3, `google_fonts` (Fredoka + Nunito already wired), `dart:ui` (BackdropFilter/ImageFilter), standard Flutter physics (`SpringSimulation`, `SpringDescription`), `CustomPainter` for sparkles.

**Spec:** `docs/superpowers/specs/2026-03-18-visual-overhaul-design.md`

---

## File Map

| File | Action | Phase |
|---|---|---|
| `lib/theme/app_theme.dart` | Update — new tokens, gradients, shadows | 1 |
| `lib/widgets/clay_ink_well.dart` | Update — spring physics on release | 1 |
| `lib/widgets/magical_sky_background.dart` | **Create** — gradient + sparkle layer | 1 |
| `lib/app.dart` | Update — insert `MagicalSkyBackground` via `builder` | 1 |
| `lib/screens/main_menu_screen.dart` | Update — remove gradient wrapper, fix token refs | 1 |
| `lib/screens/coloring_screen.dart` | Update — remove AppBar, add floating buttons + sheet | 2 |
| `lib/widgets/polaroid_card_widget.dart` | **Create** — polaroid card with washi tape + plants | 3 |
| `lib/screens/template_lib_screen.dart` | Update — swap card widget + carousel scaling | 3 |
| `lib/screens/my_upload_lib_screen.dart` | Update — swap card widget + carousel scaling | 3 |

---

## Phase 1 — Foundation Layer

---

### Task 1: Design Token Migration (`app_theme.dart`)

**Files:**
- Modify: `lib/theme/app_theme.dart`

> **Why this order matters:** Add new tokens BEFORE removing old ones. This prevents compile errors mid-migration since other files still reference old names. Delete old tokens only after all references are updated.

- [ ] **Step 1: Add new tokens alongside existing ones**

Open `lib/theme/app_theme.dart`. Replace the entire `AppColors` class:

```dart
abstract class AppColors {
  // ── Magical Sky gradient triad ──────────────────────────────────────────
  static const gradientStart  = Color(0xFFAAFFD4); // mint
  static const gradientMid    = Color(0xFFC8F0FF); // ice-blue
  static const gradientEnd    = Color(0xFFFFD6F5); // candy-pink

  // ── Accent colours ──────────────────────────────────────────────────────
  static const accentPrimary   = Color(0xFF7C6FF7); // soft indigo-violet
  static const accentSecondary = Color(0xFFF472B6); // soft candy-pink
  static const accentMint      = Color(0xFF34D399); // mint actions
  static const accentPeach     = Color(0xFFFDBA74); // warm peach

  // ── Surface (frosted glass) ──────────────────────────────────────────────
  // Use Color.fromRGBO for alpha — never CSS rgba strings in Dart
  static final surface = Color.fromRGBO(255, 255, 255, 0.72);

  // ── Text ────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF2D2640); // was 0xFF332F3A
  static const textMuted   = Color(0xFF7C7490); // was 0xFF635F69

  // ── Semantic ────────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);
}
```

- [ ] **Step 2: Update `AppGradients`**

Replace the `AppGradients` class:

```dart
abstract class AppGradients {
  // Global app background — 3-stop mint → ice-blue → candy-pink
  static const magicalSky = LinearGradient(
    colors: [
      Color(0xFFAAFFD4),
      Color(0xFFC8F0FF),
      Color(0xFFFFD6F5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary CTA buttons
  static const primaryButton = LinearGradient(
    colors: [Color(0xFFA5F3D0), Color(0xFF7C6FF7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // appBar gradient intentionally kept for now — removed in Phase 3
  static const appBar = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
```

- [ ] **Step 3: Update `AppShadows` — add `frosted` and 4th clay layer**

Replace the `AppShadows` class:

```dart
abstract class AppShadows {
  /// 4-layer clay shadow. Use on interactive cards & primary CTA buttons.
  static List<BoxShadow> clay(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.18),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    // Inner gloss highlight — simulates clay elevation
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.7),
      blurRadius: 4,
      offset: const Offset(-2, -2),
      spreadRadius: -1,
    ),
    // Candy-pink ambient glow (new)
    BoxShadow(
      color: Color.fromRGBO(255, 182, 213, 0.18),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// Soft lift — for passive containers.
  static List<BoxShadow> soft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.6),
      blurRadius: 3,
      offset: const Offset(-1, -1),
      spreadRadius: -1,
    ),
  ];

  /// Frosted-glass panel shadow. Use on DraggableScrollableSheet and floating buttons.
  static const List<BoxShadow> frosted = [
    BoxShadow(
      color: Color.fromRGBO(180, 200, 255, 0.20),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
```

- [ ] **Step 4: Update `AppTheme.build()` — transparent scaffold background**

Inside `AppTheme.build()`, change the `scaffoldBackgroundColor` line:

```dart
// Before:
scaffoldBackgroundColor: AppColors.background,

// After:
scaffoldBackgroundColor: Colors.transparent,
```

Also remove `AppColors.background` from the `ColorScheme.fromSeed` call if it was referenced there — the background is now the gradient, not a flat colour.

- [ ] **Step 5: Fix `_CreateBlankCard` in `template_lib_screen.dart`**

In `lib/screens/template_lib_screen.dart`, find `_CreateBlankCard` (around line 536). Change the border colour:

```dart
// Before:
border: Border.all(
  color: AppColors.accentLight,
  width: 2.5,
),

// After:
border: Border.all(
  color: AppColors.accentPrimary.withValues(alpha: 0.5),
  width: 2.5,
),
```

- [ ] **Step 6: Run analysis**

```bash
flutter analyze
```

Expected: zero errors. If there are `accentLight` or `background` "undefined" errors, search the codebase:

```bash
grep -r "accentLight\|AppColors\.background" lib/
```

Fix any remaining references before proceeding.

- [ ] **Step 7: Visual check**

```bash
flutter run -d windows
```

Navigate all screens. The background will still be the old flat colour at this point (the new tokens are in place, but `MagicalSkyBackground` isn't wired yet). Confirm no crash, no red overflow errors.

- [ ] **Step 8: Commit**

```bash
git add lib/theme/app_theme.dart lib/screens/template_lib_screen.dart
git commit -m "feat(phase1): migrate design tokens to Candy-Pastel Pop palette"
```

---

### Task 2: Create `MagicalSkyBackground` Widget

**Files:**
- Create: `lib/widgets/magical_sky_background.dart`

- [ ] **Step 1: Create the file**

Create `lib/widgets/magical_sky_background.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen magical sky gradient with drifting sparkle particles.
///
/// Inserted at the root via MaterialApp.builder so every route inherits
/// the background. All per-screen BoxDecoration gradient wrappers are
/// removed when this widget is active.
class MagicalSkyBackground extends StatefulWidget {
  final Widget child;
  const MagicalSkyBackground({super.key, required this.child});

  @override
  State<MagicalSkyBackground> createState() => _MagicalSkyBackgroundState();
}

class _MagicalSkyBackgroundState extends State<MagicalSkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Gradient layer ──────────────────────────────────────────────
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.magicalSky),
        ),

        // ── Sparkle layer (non-interactive) ────────────────────────────
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _SparklePainter(_ctrl.value),
              size: Size.infinite,
            ),
          ),
        ),

        // ── App content ─────────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

// ── Sparkle Painter ──────────────────────────────────────────────────────────

class _SparklePainter extends CustomPainter {
  final double t; // 0.0 → 1.0, repeating animation value

  _SparklePainter(this.t);

  // 12 particles — each has a fixed seed that determines base position,
  // drift amplitude, speed multiplier, colour index, and opacity range.
  static const _particles = [
    _Particle(sx: 0.12, sy: 0.08, ax: 0.06, ay: 0.04, sp: 1.0, ci: 0, oMin: 0.5),
    _Particle(sx: 0.30, sy: 0.22, ax: 0.04, ay: 0.07, sp: 0.7, ci: 1, oMin: 0.4),
    _Particle(sx: 0.55, sy: 0.05, ax: 0.05, ay: 0.05, sp: 1.3, ci: 2, oMin: 0.6),
    _Particle(sx: 0.78, sy: 0.15, ax: 0.07, ay: 0.03, sp: 0.9, ci: 0, oMin: 0.45),
    _Particle(sx: 0.90, sy: 0.35, ax: 0.03, ay: 0.06, sp: 1.1, ci: 1, oMin: 0.5),
    _Particle(sx: 0.20, sy: 0.50, ax: 0.08, ay: 0.04, sp: 0.8, ci: 2, oMin: 0.4),
    _Particle(sx: 0.65, sy: 0.42, ax: 0.04, ay: 0.08, sp: 1.2, ci: 0, oMin: 0.55),
    _Particle(sx: 0.40, sy: 0.70, ax: 0.06, ay: 0.05, sp: 1.0, ci: 1, oMin: 0.4),
    _Particle(sx: 0.85, sy: 0.62, ax: 0.05, ay: 0.06, sp: 0.85, ci: 2, oMin: 0.5),
    _Particle(sx: 0.10, sy: 0.80, ax: 0.07, ay: 0.03, sp: 1.15, ci: 0, oMin: 0.45),
    _Particle(sx: 0.50, sy: 0.90, ax: 0.04, ay: 0.07, sp: 0.95, ci: 1, oMin: 0.6),
    _Particle(sx: 0.72, sy: 0.82, ax: 0.06, ay: 0.04, sp: 1.05, ci: 2, oMin: 0.4),
  ];

  static const _colors = [
    AppColors.gradientStart, // mint
    AppColors.gradientMid,   // ice-blue
    AppColors.gradientEnd,   // candy-pink
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final phase = t * p.sp * math.pi * 2;

      final x = (p.sx + math.sin(phase + i) * p.ax) * size.width;
      final y = (p.sy + math.cos(phase * 0.7 + i) * p.ay) * size.height;
      final opacity = p.oMin + (1.0 - p.oMin) * (0.5 + 0.5 * math.sin(phase + i * 0.8));
      final radius = 3.0 + 3.5 * math.sin(phase * 0.5 + i).abs();

      paint
        ..color = _colors[p.ci].withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

class _Particle {
  final double sx;   // seed x (0–1 fraction of width)
  final double sy;   // seed y (0–1 fraction of height)
  final double ax;   // x drift amplitude (fraction of width)
  final double ay;   // y drift amplitude (fraction of height)
  final double sp;   // speed multiplier
  final int ci;      // colour index (0–2)
  final double oMin; // minimum opacity

  const _Particle({
    required this.sx, required this.sy,
    required this.ax, required this.ay,
    required this.sp, required this.ci,
    required this.oMin,
  });
}
```

- [ ] **Step 2: Run analysis**

```bash
flutter analyze
```

Expected: zero errors on the new file.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/magical_sky_background.dart
git commit -m "feat(phase1): add MagicalSkyBackground widget with sparkle particles"
```

---

### Task 3: Wire Background + Fix `MainMenuScreen`

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/screens/main_menu_screen.dart`

- [ ] **Step 1: Wire `MagicalSkyBackground` into `app.dart`**

Replace the contents of `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/magical_sky_background.dart';

class DrawForFunApp extends StatelessWidget {
  const DrawForFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw For Fun',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // MagicalSkyBackground wraps every route — all screens get the
      // gradient + sparkles with no per-screen changes required.
      builder: (context, child) => MagicalSkyBackground(child: child!),
      home: const MainMenuScreen(),
    );
  }
}
```

- [ ] **Step 2: Fix `MainMenuScreen` — remove gradient wrapper and fix logo shader**

In `lib/screens/main_menu_screen.dart`:

**Remove** the outer `Container` with `BoxDecoration` gradient (lines ~14–21). The `Scaffold.body` should now be just `SafeArea`:

```dart
// Before: body is a Container with BoxDecoration gradient
body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFF4F1FA), Color(0xFFEDE9FE)],
      ...
    ),
  ),
  child: SafeArea(...)
),

// After: body is SafeArea directly
body: SafeArea(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
    child: Column(...)
  ),
),
```

**Fix the logo `ShaderMask`** — change `AppGradients.appBar` to `AppGradients.magicalSky`:

```dart
// Before:
shaderCallback: (bounds) => AppGradients.appBar.createShader(bounds),

// After:
shaderCallback: (bounds) => AppGradients.magicalSky.createShader(bounds),
```

- [ ] **Step 3: Run analysis**

```bash
flutter analyze
```

Expected: zero errors.

- [ ] **Step 4: Visual check — Phase 1 milestone**

```bash
flutter run -d windows
```

You should now see:
- Mint → ice-blue → candy-pink sky gradient behind every screen
- Softly drifting sparkle particles on all screens
- Main menu logo title has the magical sky gradient on the text
- All existing widgets render correctly over the new background
- `ContourCreatorScreen` inherits the background (AppBar will still show old purple gradient — this is expected and accepted)

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart lib/screens/main_menu_screen.dart
git commit -m "feat(phase1): wire MagicalSkyBackground globally, fix MainMenuScreen tokens"
```

---

### Task 4: `ClayInkWell` Spring Physics

**Files:**
- Modify: `lib/widgets/clay_ink_well.dart`

- [ ] **Step 1: Replace the file contents**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Wraps any widget with a clay squish press animation: scales to 0.94 on
/// press, then springs back to 1.0 with physics-driven bounce on release.
///
/// Use this around every tappable surface to achieve the "physical toy" feel
/// required by the DrawForFun Claymorphism design language.
class ClayInkWell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ClayInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ClayInkWell> createState() => _ClayInkWellState();
}

class _ClayInkWellState extends State<ClayInkWell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  // Spring parameters: stiffness 300 + damping 20 gives a quick, satisfying pop
  static final _spring = SpringDescription(mass: 1, stiffness: 300, damping: 20);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      // No reverseDuration — release is physics-driven, not time-driven
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();

  void _onTapUp(TapUpDetails _) => _springBack();

  void _onTapCancel() => _springBack();

  void _springBack() {
    // Animate from current compressed value back to 0.0 (scale = 1.0)
    // using spring physics for a satisfying "pop" feel.
    _ctrl.animateWith(
      SpringSimulation(_spring, _ctrl.value, 0.0, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
```

- [ ] **Step 2: Run analysis**

```bash
flutter analyze
```

Expected: zero errors. `flutter/physics.dart` is part of the Flutter SDK — no new packages needed.

- [ ] **Step 3: Visual check**

```bash
flutter run -d windows
```

Tap any button. The press-and-release should feel snappier and bouncier than before — a subtle "pop" spring on release rather than a linear ease-out reverse.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/clay_ink_well.dart
git commit -m "feat(phase1): replace ClayInkWell reverse with SpringSimulation physics"
```

---

## Phase 2 — Coloring Screen

---

### Task 5: Floating Back Button + Actions

**Files:**
- Modify: `lib/screens/coloring_screen.dart`

- [ ] **Step 1: Remove `Scaffold.appBar`, add `_handleBack()`, retain `PopScope`**

In `_ColoringScreenState`, add a shared back-navigation method:

```dart
/// Shared back-navigation handler — called by both PopScope (hardware/gesture
/// back) and the floating back button tap. Runs _autoSave then pops.
Future<void> _handleBack() async {
  final navigator = Navigator.of(context);
  setState(() => _isSaving = true);
  await _autoSave();
  if (mounted) {
    setState(() => _isSaving = false);
    navigator.pop();
  }
}
```

In `build()`, update `PopScope.onPopInvokedWithResult` to call `_handleBack()`:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    await _handleBack();
  },
  child: Scaffold(
    // appBar: removed — no AppBar here
    body: Stack(...)
  ),
)
```

- [ ] **Step 2: Add `_FloatingBackButton` private widget to the file**

Add this private widget class at the bottom of `coloring_screen.dart`:

```dart
class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.soft(AppColors.accentPrimary),
              ),
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
```

Add `import 'dart:ui';` at the top of the file (needed for `ImageFilter`).

- [ ] **Step 3: Add floating overlays to the `Stack` in `build()`**

Inside the `Stack` children, add two new `Positioned` overlays **above** the canvas `Column` child (insert before the saving overlay):

```dart
// ── Floating back button (top-left) ─────────────────────────────────
Positioned(
  top: 0,
  left: 0,
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 16, left: 16),
      child: _FloatingCircleButton(
        icon: Icons.arrow_back_ios_new,
        onTap: _isSaving ? null : _handleBack,
        tooltip: 'Back',
      ),
    ),
  ),
),

// ── Floating action buttons (top-right) ─────────────────────────────
Positioned(
  top: 0,
  right: 0,
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 16, right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingCircleButton(
            icon: Icons.undo,
            onTap: _controller.undo,
            tooltip: 'Undo',
          ),
          const SizedBox(width: 8),
          _FloatingCircleButton(
            icon: Icons.delete_outline,
            onTap: _isSaving ? null : () => _showClearDialog(context),
            tooltip: 'Clear',
          ),
          const SizedBox(width: 8),
          _FloatingCircleButton(
            icon: Icons.save_alt,
            onTap: _isSaving ? null : _saveToGallery,
            tooltip: 'Save',
          ),
        ],
      ),
    ),
  ),
),
```

- [ ] **Step 4: Run analysis**

```bash
flutter analyze
```

Expected: zero errors.

- [ ] **Step 5: Visual check**

```bash
flutter run -d windows
```

Open a template and enter the coloring screen. Confirm:
- No AppBar — full canvas visible
- Frosted glass back button visible top-left
- Undo / Clear / Save buttons visible top-right
- Back button saves and returns correctly
- Hardware escape key (Windows) triggers save + pop (PopScope active)

- [ ] **Step 6: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat(phase2): replace coloring screen AppBar with floating frosted buttons"
```

---

### Task 6: Collapsible Frosted Bottom Sheet

**Files:**
- Modify: `lib/screens/coloring_screen.dart`

> **Context:** The current bottom panel is a `Container` inside a `Column` child. We replace it with a `DraggableScrollableSheet` as the last child of the `Stack`. The canvas `Column` keeps its `Expanded` child — the sheet overlaps it from below at runtime.

- [ ] **Step 1: Remove the old bottom panel from the `Column`**

In `build()`, inside the `Column` children, delete the `ListenableBuilder` block that currently renders the bottom `Container` (the brush selector + palette section). The `Column` should now contain only the canvas `Expanded` child:

```dart
Column(
  children: [
    // ── Canvas ─────────────────────────────────────────────────────
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RepaintBoundary(
          key: _repaintKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CanvasStackWidget(
              controller: _controller,
              lineArtAssetPath: widget.entry.overlayAssetPath,
              lineArtFilePath: widget.entry.type != DrawingType.rawImport
                  ? widget.entry.overlayFilePath
                  : null,
              backgroundFilePath: widget.entry.type == DrawingType.rawImport
                  ? widget.entry.overlayFilePath
                  : null,
            ),
          ),
        ),
      ),
    ),
    // Bottom panel removed — now a DraggableScrollableSheet in the Stack
  ],
),
```

- [ ] **Step 2: Add `DraggableScrollableSheet` to the `Stack`**

Add this as the **last child** of the `Stack` (after the floating buttons but before the saving overlay — actually it should go after the column but before the saving overlay, since the saving overlay must be on top):

```dart
// ── Collapsible frosted bottom sheet ────────────────────────────────
DraggableScrollableSheet(
  initialChildSize: 0.22,
  minChildSize: 0.08,
  maxChildSize: 0.38,
  snap: true,
  snapSizes: const [0.08, 0.22, 0.38],
  builder: (context, _) {
    // _ is the sheet's own ScrollController — unused since sheet content
    // is not itself scrollable. Named _ to satisfy the linter.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.78),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: AppShadows.frosted,
          ),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Brush selector row
                BrushSelectorWidget(
                  selectedBrush: _controller.activeBrushType,
                  onBrushSelected: _controller.setActiveBrush,
                ),
                const SizedBox(height: 10),

                // Palette / theme / eraser picker — unchanged logic
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  },
),
```

Note: `scrollController` from the sheet builder is not used here (the sheet content is not scrollable), but it must be accepted per the `DraggableScrollableSheet` API.

- [ ] **Step 3: Run analysis**

```bash
flutter analyze
```

Expected: zero errors.

- [ ] **Step 4: Visual check — Phase 2 milestone**

```bash
flutter run -d windows
```

Open a template, enter the coloring screen. Confirm:
- Full canvas visible — no AppBar, no bottom panel initially (sheet at 22% height showing brush + swatches)
- Drag the sheet handle downward — sheet snaps to collapsed pill (8%)
- Tap or drag up — sheet snaps back to 22%, then 38%
- Frosted glass effect visible on the sheet (may appear subtle on Windows — verify)
- Brush selection, palette, theme picker, eraser picker all work correctly
- Clear dialog still works
- Save to gallery still works (Windows: silent no-op by design)

- [ ] **Step 5: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat(phase2): replace bottom panel with DraggableScrollableSheet frosted glass"
```

---

## Phase 3 — Library Cards & Carousels

---

### Task 7: Create `PolaroidCardWidget`

**Files:**
- Create: `lib/widgets/polaroid_card_widget.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../persistence/drawing_entry.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Polaroid-style drawing card with washi tape, plant decoration,
/// and alternating tilt. Drop-in replacement for DrawingCardWidget
/// (identical public API).
class PolaroidCardWidget extends StatelessWidget {
  final DrawingEntry entry;
  final String label;
  final String? emoji;
  final bool hasThumbnail;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  // Card index drives tilt direction and decoration colour cycling
  final int index;

  // ignore: prefer_const_constructors_in_immutables
  PolaroidCardWidget({
    super.key,
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
    required this.onTap,
    this.onDelete,
    this.onLongPress,
    this.index = 0,
  });

  // ── Decoration cycles (4 variants, index % 4) ──────────────────────────

  static const _imageGradients = [
    [Color(0xFFAAFFD4), Color(0xFF67E8F9)], // mint → cyan
    [Color(0xFFC8F0FF), Color(0xFFA5F3FB)], // ice-blue → sky
    [Color(0xFFFDBA74), Color(0xFFFCA5A5)], // peach → coral
    [Color(0xFFFFD6F5), Color(0xFFFBCFE8)], // candy-pink → rose
  ];

  static const _plants = ['🌿', '🌸', '🌻', '🌺'];

  static const _tapeColors = [
    [Color(0xFFA78BFA), Color(0xFFC4B5FD)], // violet
    [Color(0xFFFDE68A), Color(0xFFFEF08A)], // yellow
    [Color(0xFF6EE7B7), Color(0xFFA7F3D0)], // mint
    [Color(0xFFFBCFE8), Color(0xFFFCE7F3)], // pink
  ];

  @override
  Widget build(BuildContext context) {
    final vi = index % 4;
    final angle = index % 2 == 0 ? -0.04 : 0.05;

    // Outer Stack: delete button lives here (unrotated) so its hit area
    // matches the visible position after the card is tilted.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Rotated polaroid card ──────────────────────────────────────
        Transform.rotate(
          angle: angle,
          child: ClayInkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // White card body
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.14),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image area
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: SizedBox(
                          height: 140,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Gradient background
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _imageGradients[vi],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              // Thumbnail / SVG / placeholder
                              _buildThumbnail(),
                              // Plant decoration (bottom-left, clipped)
                              Positioned(
                                bottom: 4,
                                left: 6,
                                child: Text(
                                  _plants[vi],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              // Sparkle (top-right)
                              const Positioned(
                                top: 6,
                                right: 8,
                                child: Text('✨', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Label strip
                      Container(
                        height: 44,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _StatusPill(hasThumbnail: hasThumbnail),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Washi tape — overhangs top of card by 8 px
                Positioned(
                  top: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.02,
                      child: Opacity(
                        opacity: 0.65,
                        child: Container(
                          width: 44,
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _tapeColors[vi],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Delete button (outside rotation — correct hit area) ───────
        if (onDelete != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  boxShadow: AppShadows.soft(AppColors.danger),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail() {
    if (hasThumbnail) {
      return Image.file(
        File(entry.thumbnailPath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (entry.type == DrawingType.template && entry.overlayAssetPath != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Opacity(
          opacity: 0.35,
          child: SvgPicture.asset(
            entry.overlayAssetPath!,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => _placeholder(),
          ),
        ),
      );
    }
    if (entry.overlayFilePath != null) {
      return Image.file(
        File(entry.overlayFilePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        emoji ?? '📷',
        style: const TextStyle(fontSize: 32),
      ),
    );
  }
}

// ── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool hasThumbnail;
  const _StatusPill({required this.hasThumbnail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: hasThumbnail
            ? AppColors.accentPrimary.withValues(alpha: 0.15)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        hasThumbnail ? '● colored' : 'not started',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: hasThumbnail ? AppColors.accentPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analysis**

```bash
flutter analyze
```

Expected: zero errors.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/polaroid_card_widget.dart
git commit -m "feat(phase3): add PolaroidCardWidget with washi tape and plant decorations"
```

---

### Task 8: Update `TemplateLibScreen` — Swap Cards + Carousel Scaling

**Files:**
- Modify: `lib/screens/template_lib_screen.dart`

- [ ] **Step 1: Add import for `PolaroidCardWidget`**

At the top of `template_lib_screen.dart`, add:

```dart
import '../widgets/polaroid_card_widget.dart';
```

- [ ] **Step 2: Add a `ScrollController` for the main carousel**

In `_TemplateLibScreenState`, add:

```dart
late final ScrollController _mainScrollCtrl;
late final ScrollController _customScrollCtrl;

@override
void initState() {
  super.initState();
  _mainScrollCtrl = ScrollController()..addListener(() => setState(() {}));
  _customScrollCtrl = ScrollController()..addListener(() => setState(() {}));
  _loadData();
}

@override
void dispose() {
  _mainScrollCtrl.dispose();
  _customScrollCtrl.dispose();
  super.dispose();
}
```

- [ ] **Step 3: Add carousel scale helper method**

Add this method to `_TemplateLibScreenState`:

```dart
/// Computes a scale factor (0.88–1.0) for a carousel item based on its
/// distance from the viewport centre. Items near centre appear larger.
double _carouselScale(int index, ScrollController ctrl, BuildContext context) {
  if (!ctrl.hasClients) return 1.0;
  const itemExtent = 212.0; // cardWidth(200) + gap(12)
  final viewportWidth = MediaQuery.of(context).size.width;
  final scrollOffset = ctrl.offset;
  final itemCenter = index * itemExtent + 100.0; // 100 = cardWidth/2
  final viewportCenter = scrollOffset + viewportWidth / 2;
  final distance = (itemCenter - viewportCenter).abs();
  return lerpDouble(1.0, 0.88, (distance / 160.0).clamp(0.0, 1.0))!;
}
```

Add `import 'dart:ui' show lerpDouble;` at the top.

- [ ] **Step 4: Replace the main carousel `ListView`**

Find the main carousel `ListView` (the one with `_CreateBlankCard` and `_cards`). Replace it with a `ListView.builder` using `itemExtent` and `PolaroidCardWidget`:

```dart
SizedBox(
  height: 200,
  child: ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      },
    ),
    child: ListView.builder(
      controller: _mainScrollCtrl,
      scrollDirection: Axis.horizontal,
      itemExtent: 212,
      itemCount: 1 + _cards.length, // +1 for CreateBlankCard
      itemBuilder: (context, i) {
        final scale = _carouselScale(i, _mainScrollCtrl, context);
        if (i == 0) {
          return Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 200,
                child: _CreateBlankCard(
                  onTap: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ContourCreatorScreen(),
                      ),
                    );
                    _loadData();
                  },
                ),
              ),
            ),
          );
        }
        final cardIndex = i - 1;
        final card = _cards[cardIndex];
        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 200,
              child: PolaroidCardWidget(
                index: cardIndex,
                entry: card.entry,
                label: card.label,
                emoji: card.emoji,
                hasThumbnail: card.hasThumbnail,
                onTap: () => _openEntry(card.entry),
                onLongPress: () => _showRemixSheet(card),
                onDelete: card.entry.type == DrawingType.template
                    ? null
                    : () => _confirmDelete(card),
              ),
            ),
          ),
        );
      },
    ),
  ),
),
```

- [ ] **Step 5: Replace the custom templates `ListView` similarly**

Find the `_customCards` `ListView` and apply the same pattern using `_customScrollCtrl`:

```dart
SizedBox(
  height: 200,
  child: ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      },
    ),
    child: ListView.builder(
      controller: _customScrollCtrl,
      scrollDirection: Axis.horizontal,
      itemExtent: 212,
      itemCount: _customCards.length,
      itemBuilder: (context, i) {
        final card = _customCards[i];
        final scale = _carouselScale(i, _customScrollCtrl, context);
        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 200,
              child: PolaroidCardWidget(
                index: i,
                entry: card.entry,
                label: card.label,
                emoji: card.emoji,
                hasThumbnail: card.hasThumbnail,
                onTap: () => _openEntry(card.entry),
                onLongPress: () => _showRemixSheet(card),
                onDelete: () => _confirmDelete(card),
              ),
            ),
          ),
        );
      },
    ),
  ),
),
```

- [ ] **Step 6: Update AppBar gradient — retire `AppGradients.appBar`**

In `lib/screens/template_lib_screen.dart`, the AppBar is created via `AppTheme.gradientAppBar(...)`. Update `AppTheme.gradientAppBar()` in `lib/theme/app_theme.dart` to use `magicalSky`:

```dart
// In app_theme.dart, AppTheme.gradientAppBar():
flexibleSpace: Container(
  // Before: decoration: const BoxDecoration(gradient: AppGradients.appBar),
  decoration: const BoxDecoration(gradient: AppGradients.magicalSky),
),
```

Then **delete** the `appBar` constant from `AppGradients`.

- [ ] **Step 7: Run analysis**

```bash
flutter analyze
```

Expected: zero errors. If `appBar` is referenced anywhere else, fix those references first.

- [ ] **Step 8: Visual check**

```bash
flutter run -d windows
```

Navigate to Templates screen. Confirm:
- AppBar shows magical sky gradient instead of old purple-pink
- Cards render as polaroids with washi tape and plant emojis
- Cards tilt alternately left/right
- Scrolling the carousel shows center cards slightly larger than edge cards
- Delete button appears and works on uploadable cards
- Long-press still shows the remix sheet

- [ ] **Step 9: Commit**

```bash
git add lib/screens/template_lib_screen.dart lib/theme/app_theme.dart
git commit -m "feat(phase3): polaroid cards + carousel scaling in TemplateLibScreen, retire appBar gradient"
```

---

### Task 9: Update `MyUploadLibScreen`

**Files:**
- Modify: `lib/screens/my_upload_lib_screen.dart`

- [ ] **Step 1: Add imports**

```dart
import 'dart:ui' show lerpDouble;
import '../widgets/polaroid_card_widget.dart';
```

- [ ] **Step 2: Add scroll controller**

In `_MyUploadLibScreenState`:

```dart
late final ScrollController _scrollCtrl;

@override
void initState() {
  super.initState();
  _scrollCtrl = ScrollController()..addListener(() => setState(() {}));
  _loadData();
}

@override
void dispose() {
  _scrollCtrl.dispose();
  super.dispose();
}
```

- [ ] **Step 3: Add carousel scale helper**

```dart
double _carouselScale(int index, BuildContext context) {
  if (!_scrollCtrl.hasClients) return 1.0;
  const itemExtent = 212.0;
  final viewportWidth = MediaQuery.of(context).size.width;
  final scrollOffset = _scrollCtrl.offset;
  final itemCenter = index * itemExtent + 100.0;
  final viewportCenter = scrollOffset + viewportWidth / 2;
  final distance = (itemCenter - viewportCenter).abs();
  return lerpDouble(1.0, 0.88, (distance / 160.0).clamp(0.0, 1.0))!;
}
```

- [ ] **Step 4: Replace the `ListView.builder` in `build()`**

Find the existing `ListView.builder` (inside the `Expanded` body) and replace it:

```dart
ListView.builder(
  controller: _scrollCtrl,
  scrollDirection: Axis.horizontal,
  itemExtent: 212,
  itemCount: _cards.length,
  itemBuilder: (_, i) {
    final card = _cards[i];
    final scale = _carouselScale(i, context);
    return Transform.scale(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 200,
          child: PolaroidCardWidget(
            index: i,
            entry: card.entry,
            label: card.label,
            hasThumbnail: card.hasThumbnail,
            onTap: () => _openEntry(card.entry),
            onDelete: () => _confirmDelete(card),
          ),
        ),
      ),
    );
  },
),
```

- [ ] **Step 5: Run analysis**

```bash
flutter analyze
```

Expected: zero errors.

- [ ] **Step 6: Visual check — Phase 3 milestone**

```bash
flutter run -d windows
```

Open My Uploads. Confirm polaroid card style and carousel scale effect. Navigate all three screens (main menu, templates, my uploads) and the coloring screen. Full visual sign-off:

- [ ] Magical sky gradient + sparkles on all screens
- [ ] Main menu logo uses sky gradient text
- [ ] Templates screen: polaroid cards, sky AppBar, carousel scaling
- [ ] My Uploads screen: polaroid cards, sky AppBar, carousel scaling
- [ ] Coloring screen: no AppBar, floating frosted buttons, collapsible sheet

- [ ] **Step 7: Final commit**

```bash
git add lib/screens/my_upload_lib_screen.dart
git commit -m "feat(phase3): polaroid cards + carousel scaling in MyUploadLibScreen"
```

---

## Done

All three phases complete. The app has a fully transformed visual identity:
- Mint → ice-blue → candy-pink magical sky background on every screen
- Spring-physics press animations on every interactive element
- Floating frosted-glass coloring toolbar that collapses with snap points
- Polaroid-style library cards with washi tape, plant accents, and alternating tilts
- Carousel centre-item scaling on both library screens
