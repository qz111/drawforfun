# Right-Side Vertical Toolbar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the overflowing horizontal bottom sheet toolbar with a frosted-glass vertical brush rail on the right edge plus a slide-in options strip, eliminating overflow and improving iPad ergonomics.

**Architecture:** Two new `Positioned` widgets live in `coloring_screen.dart`'s `Stack` — a permanent `BrushRailWidget` on the far right and an `OptionsStripWidget` that slides in to its left. `_ColoringScreenState` owns `_isStripOpen`. Existing picker widgets (`PaletteWidget`, `ThemePickerWidget`, `EraserSizePickerWidget`) gain an `axis` parameter so they can scroll vertically inside the strip.

**Tech Stack:** Flutter/Dart, `BackdropFilter` for frosted glass, `AnimatedSlide`+`AnimatedOpacity` for strip animation, `flutter_test` for widget tests.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/palette/palette_widget.dart` | Add `axis` param; vertical = single-column `ListView`, 24 swatches only |
| Modify | `lib/widgets/theme_picker_widget.dart` | Add `axis` param; vertical = `Axis.vertical` ListView, 56×56px tiles, no label |
| Modify | `lib/widgets/eraser_size_picker_widget.dart` | Add `axis` param; vertical = `Axis.vertical` scroll, 56×64px tiles |
| Create | `lib/widgets/brush_rail_widget.dart` | Frosted glass vertical rail, 6 icon-only brush tiles |
| Create | `lib/widgets/options_strip_widget.dart` | Animated frosted glass strip, delegates content to the three picker widgets |
| Modify | `lib/screens/coloring_screen.dart` | Remove `DraggableScrollableSheet`; add `_isStripOpen`; wire new widgets |
| Modify | `test/widgets/eraser_size_picker_widget_test.dart` | Add vertical-axis test cases |
| Create | `test/widgets/brush_rail_widget_test.dart` | Rail renders 6 icons, tap callbacks, selected highlight |
| Create | `test/widgets/options_strip_widget_test.dart` | Visibility states, correct content per brush type |

---

## Task 1: Add vertical axis to `EraserSizePickerWidget`

**Files:**
- Modify: `lib/widgets/eraser_size_picker_widget.dart`
- Modify: `test/widgets/eraser_size_picker_widget_test.dart`

- [ ] **Step 1: Write the failing tests**

Add to the end of the existing `group` in `test/widgets/eraser_size_picker_widget_test.dart`:

```dart
    testWidgets('vertical axis shows tiles in a vertical list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 300,
              child: EraserSizePickerWidget(
                axis: Axis.vertical,
                selectedIndex: 0,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // A vertical SingleChildScrollView (or ListView) must be present.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // All labels still render.
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('vertical axis tile height is 64', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 300,
              child: EraserSizePickerWidget(
                axis: Axis.vertical,
                selectedIndex: 0,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('S'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      expect(container.constraints?.maxHeight, 64.0);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/eraser_size_picker_widget_test.dart -v
```
Expected: 2 new tests FAIL with "Named parameter 'axis' isn't defined".

- [ ] **Step 3: Add `axis` parameter and vertical layout**

Replace `lib/widgets/eraser_size_picker_widget.dart` with:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Eraser size selector. Supports horizontal (default) and vertical layouts.
class EraserSizePickerWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSizeSelected;
  final Axis axis;

  const EraserSizePickerWidget({
    super.key,
    required this.selectedIndex,
    required this.onSizeSelected,
    this.axis = Axis.horizontal,
  });

  static const _circleDiameters = [16.0, 28.0, 44.0];
  static const _labels = ['S', 'M', 'L'];

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    return SingleChildScrollView(
      scrollDirection: axis,
      child: isVertical
          ? Column(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _SizeTile(
                  label: _labels[i],
                  circleDiameter: _circleDiameters[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onSizeSelected(i),
                  width: 56,
                  height: 64,
                ),
              )),
            )
          : Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _SizeTile(
                  label: _labels[i],
                  circleDiameter: _circleDiameters[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onSizeSelected(i),
                  width: 60,
                  height: 70,
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
  final double width;
  final double height;

  const _SizeTile({
    required this.label,
    required this.circleDiameter,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        constraints: BoxConstraints(maxHeight: height),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected ? AppShadows.clay(AppColors.accentPrimary) : null,
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
                  color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run all eraser tests**

```
flutter test test/widgets/eraser_size_picker_widget_test.dart -v
```
Expected: all 5 tests PASS.

- [ ] **Step 5: Analyze**

```
flutter analyze lib/widgets/eraser_size_picker_widget.dart
```
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/eraser_size_picker_widget.dart test/widgets/eraser_size_picker_widget_test.dart
git commit -m "feat: add vertical axis support to EraserSizePickerWidget"
```

---

## Task 2: Add vertical axis to `ThemePickerWidget`

**Files:**
- Modify: `lib/widgets/theme_picker_widget.dart`
- Create: `test/widgets/theme_picker_widget_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/widgets/theme_picker_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';

void main() {
  group('ThemePickerWidget', () {
    testWidgets('horizontal default shows 10 tiles', (tester) async {
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
      // ListView with horizontal scroll must be present.
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('vertical axis uses vertical ListView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: ThemePickerWidget(
                axis: Axis.vertical,
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.vertical);
    });

    testWidgets('vertical axis tiles are 56×56', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: ThemePickerWidget(
                axis: Axis.vertical,
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // First AnimatedContainer should be 56×56.
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();
      expect(containers.first.constraints?.maxWidth, 56.0);
      expect(containers.first.constraints?.maxHeight, 56.0);
    });

    testWidgets('calls onThemeSelected when tapped', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: ThemePickerWidget(
                axis: Axis.vertical,
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (i) => selected = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AnimatedContainer).first);
      expect(selected, 0);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/theme_picker_widget_test.dart -v
```
Expected: FAIL — `axis` named parameter not found.

- [ ] **Step 3: Add `axis` parameter and vertical layout**

Replace `lib/widgets/theme_picker_widget.dart` with:

```dart
import 'package:flutter/material.dart';
import '../brushes/brush_theme.dart';
import '../brushes/brush_type.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Scrollable list of 10 theme/style tiles.
/// Supports horizontal (default, bottom bar) and vertical (options strip) layouts.
class ThemePickerWidget extends StatelessWidget {
  final BrushType brushType;
  final int selectedIndex;
  final ValueChanged<int> onThemeSelected;
  final Axis axis;

  const ThemePickerWidget({
    super.key,
    required this.brushType,
    required this.selectedIndex,
    required this.onThemeSelected,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final isAirbrush = brushType == BrushType.airbrush;
    final isVertical = axis == Axis.vertical;
    const count = 10;

    // Horizontal: fixed height wrapper. Vertical: unconstrained in height.
    return isVertical
        ? _buildList(isAirbrush, isVertical, count)
        : SizedBox(
            height: 64,
            child: _buildList(isAirbrush, isVertical, count),
          );
  }

  Widget _buildList(bool isAirbrush, bool isVertical, int count) {
    return ListView.separated(
      scrollDirection: axis,
      padding: isVertical
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 4),
      itemCount: count,
      separatorBuilder: (_, __) =>
          isVertical ? const SizedBox(height: 6) : const SizedBox(width: 6),
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

        return ClayInkWell(
          onTap: () => onThemeSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isVertical ? 56 : 80,
            height: isVertical ? 56 : 64,
            constraints: BoxConstraints(
              maxWidth: isVertical ? 56 : 80,
              maxHeight: isVertical ? 56 : 64,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: selected ? AppColors.accentPrimary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: selected ? AppShadows.clay(AppColors.accentPrimary) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: isVertical ? 20 : 22)),
                // Label dropped in vertical mode — too narrow for 56px width.
                if (!isVertical) ...[
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
              ],
            ),
          ),
        );
      },
    );
  }
}
```

> **Note:** `const` on a conditional expression like `fontSize: isVertical ? 20 : 22` is not valid at compile time because `isVertical` is a runtime value. Replace with a variable: declare `final double emojiSize = isVertical ? 20.0 : 22.0;` in `_buildList` and use it in the `TextStyle`.

- [ ] **Step 4: Fix the non-const issue**

In `_buildList`, before `return ListView.separated(...)`, add:
```dart
final double emojiSize = isVertical ? 20.0 : 22.0;
```
And change the emoji `Text` to:
```dart
Text(emoji, style: TextStyle(fontSize: emojiSize)),
```

- [ ] **Step 5: Run all theme picker tests**

```
flutter test test/widgets/theme_picker_widget_test.dart -v
```
Expected: all 4 tests PASS.

- [ ] **Step 6: Analyze**

```
flutter analyze lib/widgets/theme_picker_widget.dart
```
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/theme_picker_widget.dart test/widgets/theme_picker_widget_test.dart
git commit -m "feat: add vertical axis support to ThemePickerWidget"
```

---

## Task 3: Add vertical axis to `PaletteWidget`

**Files:**
- Modify: `lib/palette/palette_widget.dart`
- Create: `test/widgets/palette_widget_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/widgets/palette_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/palette/palette_widget.dart';
import 'package:drawforfun/palette/color_palette.dart';

void main() {
  group('PaletteWidget', () {
    testWidgets('horizontal default uses Wrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaletteWidget(
              selectedColor: Colors.red,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('vertical axis uses ListView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: PaletteWidget(
                axis: Axis.vertical,
                selectedColor: Colors.red,
                onColorSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('vertical axis shows exactly 24 swatches', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: PaletteWidget(
                axis: Axis.vertical,
                selectedColor: Colors.red,
                onColorSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // 24 color circle containers (not 25 — eraser sentinel excluded).
      expect(
        find.byType(Container),
        findsNWidgets(ColorPalette.swatches.length),
      );
    });

    testWidgets('calls onColorSelected when a swatch is tapped', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: PaletteWidget(
                axis: Axis.vertical,
                selectedColor: Colors.red,
                onColorSelected: (c) => picked = c,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      expect(picked, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/palette_widget_test.dart -v
```
Expected: FAIL — `axis` named parameter not found.

- [ ] **Step 3: Implement vertical axis**

Replace `lib/palette/palette_widget.dart` with:

```dart
import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Color swatch picker. Supports horizontal Wrap (default) and vertical ListView.
class PaletteWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final Axis axis;

  const PaletteWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      // Vertical: single-column ListView, 24 swatches only (no eraser sentinel).
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: ColorPalette.swatches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final color = ColorPalette.swatches[index];
          return Center(
            child: _ColorSwatch(
              color: color,
              isSelected: color == selectedColor,
              onTap: () => onColorSelected(color),
            ),
          );
        },
      );
    }

    // Horizontal default: Wrap with eraser sentinel appended.
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

- [ ] **Step 4: Run palette tests**

```
flutter test test/widgets/palette_widget_test.dart -v
```
Expected: all 4 tests PASS.

- [ ] **Step 5: Analyze**

```
flutter analyze lib/palette/palette_widget.dart
```
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/palette/palette_widget.dart test/widgets/palette_widget_test.dart
git commit -m "feat: add vertical axis support to PaletteWidget"
```

---

## Task 4: Create `BrushRailWidget`

**Files:**
- Create: `lib/widgets/brush_rail_widget.dart`
- Create: `test/widgets/brush_rail_widget_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/widgets/brush_rail_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/brush_rail_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BrushRailWidget', () {
    testWidgets('renders an icon for every BrushType', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.pencil,
            isStripOpen: false,
            onBrushSelected: (_) {},
            onToggleStrip: () {},
          ),
        ),
      ));
      // 6 icon tiles — one per BrushType.
      expect(find.byType(Icon), findsNWidgets(BrushType.values.length));
    });

    testWidgets('tapping a different brush calls onBrushSelected with that type', (tester) async {
      BrushType? selected;
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.pencil,
            isStripOpen: false,
            onBrushSelected: (t) => selected = t,
            onToggleStrip: () {},
          ),
        ),
      ));
      // Tap the eraser icon (last in column).
      await tester.tap(find.byIcon(Icons.auto_fix_normal));
      expect(selected, BrushType.eraser);
    });

    testWidgets('tapping the selected brush calls onToggleStrip', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.pencil,
            isStripOpen: false,
            onBrushSelected: (_) {},
            onToggleStrip: () => toggled = true,
          ),
        ),
      ));
      // Pencil is the selected brush — tapping it should toggle strip.
      await tester.tap(find.byIcon(Icons.edit));
      expect(toggled, isTrue);
    });

    testWidgets('selected brush icon uses accent color', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.marker,
            isStripOpen: false,
            onBrushSelected: (_) {},
            onToggleStrip: () {},
          ),
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.brush));
      expect(icon.color, isNotNull);
      // Color should differ from unselected (accent vs muted grey) — just check non-null.
      expect(icon.color, isNot(equals(Colors.grey)));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/brush_rail_widget_test.dart -v
```
Expected: FAIL — `brush_rail_widget.dart` not found.

- [ ] **Step 3: Implement `BrushRailWidget`**

Create `lib/widgets/brush_rail_widget.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../theme/app_theme.dart';
import 'clay_ink_well.dart';

/// Always-visible frosted glass vertical rail showing one icon tile per brush type.
/// Tapping the active brush calls [onToggleStrip]; tapping another calls [onBrushSelected].
class BrushRailWidget extends StatelessWidget {
  final BrushType selectedBrush;
  final bool isStripOpen;
  final ValueChanged<BrushType> onBrushSelected;
  final VoidCallback onToggleStrip;

  const BrushRailWidget({
    super.key,
    required this.selectedBrush,
    required this.isStripOpen,
    required this.onBrushSelected,
    required this.onToggleStrip,
  });

  static const _icons = {
    BrushType.pencil:   Icons.edit,
    BrushType.marker:   Icons.brush,
    BrushType.airbrush: Icons.blur_on,
    BrushType.pattern:  Icons.star,
    BrushType.splatter: Icons.scatter_plot,
    BrushType.eraser:   Icons.auto_fix_normal,
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        bottomLeft: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 64,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.78),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
            boxShadow: AppShadows.frosted,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: BrushType.values.map((type) {
              final isSelected = type == selectedBrush;
              return _BrushTile(
                icon: _icons[type]!,
                isSelected: isSelected,
                onTap: isSelected ? onToggleStrip : () => onBrushSelected(type),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BrushTile extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushTile({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.18)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run brush rail tests**

```
flutter test test/widgets/brush_rail_widget_test.dart -v
```
Expected: all 4 tests PASS.

- [ ] **Step 5: Analyze**

```
flutter analyze lib/widgets/brush_rail_widget.dart
```
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/brush_rail_widget.dart test/widgets/brush_rail_widget_test.dart
git commit -m "feat: add BrushRailWidget — vertical frosted glass brush selector"
```

---

## Task 5: Create `OptionsStripWidget`

**Files:**
- Create: `lib/widgets/options_strip_widget.dart`
- Create: `test/widgets/options_strip_widget_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/widgets/options_strip_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';
import 'package:drawforfun/palette/palette_widget.dart';
import 'package:drawforfun/widgets/eraser_size_picker_widget.dart';
import 'package:drawforfun/widgets/options_strip_widget.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

CanvasController _controller() => CanvasController();

void main() {
  group('OptionsStripWidget', () {
    testWidgets('when not visible, strip is wrapped in IgnorePointer(ignoring: true)', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: false,
          activeBrush: BrushType.pencil,
          controller: ctrl,
        ),
      )));
      final ip = tester.widget<IgnorePointer>(find.byType(IgnorePointer).first);
      expect(ip.ignoring, isTrue);
    });

    testWidgets('when visible, IgnorePointer is not ignoring', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.pencil,
          controller: ctrl,
        ),
      )));
      final ip = tester.widget<IgnorePointer>(find.byType(IgnorePointer).first);
      expect(ip.ignoring, isFalse);
    });

    testWidgets('pencil brush shows PaletteWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.pencil,
          controller: ctrl,
        ),
      )));
      await tester.pump(); // settle animation
      expect(find.byType(PaletteWidget), findsOneWidget);
    });

    testWidgets('eraser brush shows EraserSizePickerWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.eraser,
          controller: ctrl,
        ),
      )));
      await tester.pump();
      expect(find.byType(EraserSizePickerWidget), findsOneWidget);
    });

    testWidgets('airbrush shows ThemePickerWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.airbrush,
          controller: ctrl,
        ),
      )));
      await tester.pump();
      expect(find.byType(ThemePickerWidget), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/options_strip_widget_test.dart -v
```
Expected: FAIL — `options_strip_widget.dart` not found.

- [ ] **Step 3: Implement `OptionsStripWidget`**

> **Controller API note:** `CanvasController.activeThemeIndex` is a unified getter that already returns `_activeEraserSizeIndex` when the eraser brush is active (confirmed in `canvas_controller.dart`). Similarly `setActiveTheme` routes to the correct underlying field per brush type. Using these for the eraser branch is intentional and correct — no separate eraser-specific getter or setter exists.

Create `lib/widgets/options_strip_widget.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../canvas/canvas_controller.dart';
import '../palette/palette_widget.dart';
import '../theme/app_theme.dart';
import 'eraser_size_picker_widget.dart';
import 'theme_picker_widget.dart';

/// Animated frosted glass options strip.
/// Slides in from the right (behind the brush rail) when [isVisible] is true.
/// Content is determined by [activeBrush] — palette, theme picker, or eraser sizes.
class OptionsStripWidget extends StatelessWidget {
  final bool isVisible;
  final BrushType activeBrush;
  final CanvasController controller;

  const OptionsStripWidget({
    super.key,
    required this.isVisible,
    required this.activeBrush,
    required this.controller,
  });

  bool get _isThemeBrush =>
      activeBrush == BrushType.airbrush || activeBrush == BrushType.pattern;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(1.0, 0.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 72,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.65),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                  boxShadow: AppShadows.frosted,
                ),
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (_, __) => _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (activeBrush == BrushType.eraser) {
      return EraserSizePickerWidget(
        axis: Axis.vertical,
        selectedIndex: controller.activeThemeIndex,
        onSizeSelected: controller.setActiveTheme,
      );
    }
    if (_isThemeBrush) {
      return ThemePickerWidget(
        axis: Axis.vertical,
        brushType: activeBrush,
        selectedIndex: controller.activeThemeIndex,
        onThemeSelected: controller.setActiveTheme,
      );
    }
    // Pencil, marker, splatter — color palette.
    return PaletteWidget(
      axis: Axis.vertical,
      selectedColor: controller.activeColor,
      onColorSelected: controller.setActiveColor,
    );
  }
}
```

- [ ] **Step 4: Run options strip tests**

```
flutter test test/widgets/options_strip_widget_test.dart -v
```
Expected: all 5 tests PASS.

- [ ] **Step 5: Analyze**

```
flutter analyze lib/widgets/options_strip_widget.dart
```
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/options_strip_widget.dart test/widgets/options_strip_widget_test.dart
git commit -m "feat: add OptionsStripWidget — animated vertical options strip"
```

---

## Task 6: Wire up `coloring_screen.dart`

**Files:**
- Modify: `lib/screens/coloring_screen.dart`
- Modify: `test/widget_test.dart` (smoke test — verify screen still builds)

- [ ] **Step 1: Check the existing smoke test**

Read `test/widget_test.dart` to understand what it currently tests. The smoke test should still pass after the screen change.

- [ ] **Step 2: Update `coloring_screen.dart`**

Make these changes to `lib/screens/coloring_screen.dart`:

**2a.** Add imports at the top:
```dart
import '../widgets/brush_rail_widget.dart';
import '../widgets/options_strip_widget.dart';
```

**2b.** Add `_isStripOpen` to `_ColoringScreenState`:
```dart
bool _isStripOpen = false;
```

**2c.** Add the toggle handler to `_ColoringScreenState`:
```dart
void _handleBrushSelected(BrushType type) {
  setState(() {
    _controller.setActiveBrush(type);
    _isStripOpen = true; // always open strip when switching to a new brush
  });
}

void _handleToggleStrip() {
  setState(() => _isStripOpen = !_isStripOpen);
}
```

**2d.** Remove the entire `DraggableScrollableSheet(...)` block from the `Stack` children. It is the large block starting with `DraggableScrollableSheet(` and ending at its closing `)` — search for `DraggableScrollableSheet` in the file to locate it.

**2e.** Remove unused imports that were only needed for the bottom sheet:
```dart
// Remove these if no longer used elsewhere:
import '../widgets/brush_selector_widget.dart';   // superseded by BrushRailWidget
```
Keep `eraser_size_picker_widget.dart`, `theme_picker_widget.dart`, `palette_widget.dart` imports — they are now used inside `OptionsStripWidget` (no direct import needed in the screen file; remove them if unused).

**2f.** Add the two new `Positioned` children to the `Stack`, after the floating back button and before the save overlay. Wrap them in a `ListenableBuilder` so they rebuild when `_controller` changes (brush type selection updates):

```dart
// ── Right-side brush rail + options strip ──────────────────────────────
ListenableBuilder(
  listenable: _controller,
  builder: (context, _) {
    final topOffset = MediaQuery.of(context).padding.top + 76.0;
    return Stack(
      children: [
        Positioned(
          right: 0,
          top: topOffset,
          bottom: 0,
          child: BrushRailWidget(
            selectedBrush: _controller.activeBrushType,
            isStripOpen: _isStripOpen,
            onBrushSelected: _handleBrushSelected,
            onToggleStrip: _handleToggleStrip,
          ),
        ),
        Positioned(
          right: 64,
          top: topOffset,
          bottom: 0,
          child: OptionsStripWidget(
            isVisible: _isStripOpen,
            activeBrush: _controller.activeBrushType,
            controller: _controller,
          ),
        ),
      ],
    );
  },
),
```

- [ ] **Step 3: Run flutter analyze**

```
flutter analyze lib/screens/coloring_screen.dart
```
Fix any unused import warnings. Expected: No issues after cleanup.

- [ ] **Step 4: Run all tests**

```
flutter test -v
```
Expected: all tests PASS. Any test referencing the old `DraggableScrollableSheet` or `BrushSelectorWidget` in the context of the coloring screen should be updated or removed.

- [ ] **Step 5: Update `brush_selector_widget_test.dart`**

The `BrushSelectorWidget` still exists as a file. Its tests still test the old widget directly — they remain valid as unit tests of that widget. No changes needed unless the widget file itself is deleted. Leave it in place for now.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat: replace bottom sheet toolbar with right-side brush rail and options strip"
```

---

## Task 7: Final cleanup and full test run

- [ ] **Step 1: Run full test suite**

```
flutter test
```
Expected: all tests pass, no failures.

- [ ] **Step 2: Run analyze on the whole project**

```
flutter analyze
```
Expected: no issues (fix any stale unused imports from removed bottom sheet).

- [ ] **Step 3: Manual smoke test on Windows desktop**

```
flutter run -d windows
```
Verify:
- No bottom sheet appears
- Brush rail visible on right side, below top buttons
- Tapping a brush opens the options strip from the right
- Tapping the same brush again closes the strip
- Colors, eraser sizes, themes all scroll vertically in the strip
- Undo, clear, save buttons at top-right work as before
- Back button works and auto-saves

- [ ] **Step 4: Final commit (if any fixes made during smoke test)**

```bash
git add -p
git commit -m "fix: address visual issues found during manual smoke test"
```
