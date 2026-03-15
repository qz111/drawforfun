# Animal Templates Feature — Design Spec

**Date:** 2026-03-15
**Project:** DrawForFun — Flutter children's coloring app (ages 3–8)
**Status:** Approved

---

## Overview

Add 25 built-in animal line-art templates (SVG assets) that children can select from a dedicated Template Screen. Selected templates overlay the drawing canvas using the same `Stack` layering rules as photo-converted line art (line art on top with `IgnorePointer`, drawing layer in the middle). Switching templates prompts the user to optionally save their current drawing first.

---

## Goals

- Give children instant coloring content without needing to photograph anything
- 25 recognisable animals at medium detail level (clear outlines + face/paws, no texture)
- Child-friendly template picker: large grid cards, emoji + name labels
- Non-destructive workflow: always offer to save before switching templates

---

## Animals (25)

| # | ID | Name | Emoji |
|---|-----|------|-------|
| 1 | cat | Cat | 🐱 |
| 2 | dog | Dog | 🐶 |
| 3 | fox | Fox | 🦊 |
| 4 | panda | Panda | 🐼 |
| 5 | rabbit | Rabbit | 🐰 |
| 6 | monkey | Monkey | 🐵 |
| 7 | elephant | Elephant | 🐘 |
| 8 | lion | Lion | 🦁 |
| 9 | giraffe | Giraffe | 🦒 |
| 10 | bear | Bear | 🐻 |
| 11 | horse | Horse | 🐴 |
| 12 | cow | Cow | 🐮 |
| 13 | pig | Pig | 🐷 |
| 14 | sheep | Sheep | 🐑 |
| 15 | chicken | Chicken | 🐔 |
| 16 | duck | Duck | 🦆 |
| 17 | frog | Frog | 🐸 |
| 18 | turtle | Turtle | 🐢 |
| 19 | fish | Fish | 🐟 |
| 20 | whale | Whale | 🐳 |
| 21 | owl | Owl | 🦉 |
| 22 | penguin | Penguin | 🐧 |
| 23 | butterfly | Butterfly | 🦋 |
| 24 | crocodile | Crocodile | 🐊 |
| 25 | bird | Bird | 🐦 |

---

## Art Style

**Medium detail:** clear outer body outline + face features (eyes, nose/beak, mouth) + distinct paw/fin/wing regions. No fur texture lines, no hatching. Stroke width 2–2.5px. All fills `none`, all strokes `#1a1a1a`. SVG viewBox `0 0 400 400`, optimised for coloring at any scale.

The style is intentionally between "chunky toddler" and "detailed colouring book" — suitable for ages 5–8 and approachable for ages 3–5 with help.

---

## Architecture

### New Package

- **`flutter_svg: ^2.0.0`** — required to render `.svg` assets in Flutter widgets. Approved by user.

### New Files

#### `lib/templates/animal_template.dart`
Immutable data class:
```dart
class AnimalTemplate {
  final String id;          // e.g. 'cat'
  final String name;        // e.g. 'Cat'
  final String emoji;       // e.g. '🐱'
  final String assetPath;   // e.g. 'assets/line_art/cat.svg'
  const AnimalTemplate({required this.id, required this.name, required this.emoji, required this.assetPath});
}
```

#### `lib/templates/animal_templates.dart`
Static registry:
```dart
class AnimalTemplates {
  static const List<AnimalTemplate> all = [ /* 25 entries */ ];
}
```

#### `lib/screens/template_screen.dart`
- `StatelessWidget` — no local state needed
- `Scaffold` with deep-purple `AppBar` titled "Choose an Animal"
- `GridView.builder` with 3 columns
- Each cell: `AnimalTemplateCard` — rounded card with `SvgPicture.asset` thumbnail (with `placeholderBuilder` showing a grey box on load failure) + name label below
- Tapping a card calls `Navigator.pop(context, template)`
- Back button returns `null` (no selection)

#### `assets/line_art/*.svg`
25 SVG files, one per animal (e.g. `assets/line_art/cat.svg`). Medium-detail hand-crafted SVG line art, `viewBox="0 0 400 400"`, black stroke on transparent background.

#### `test/templates/animal_templates_test.dart`
- Verifies `AnimalTemplates.all.length == 25`
- Verifies all `id` values are unique
- Verifies all `assetPath` values are unique and match `assets/line_art/<id>.svg` pattern

---

### Modified Files

#### `lib/canvas/canvas_stack_widget.dart`

Add `String? lineArtAssetPath` parameter. Add `IgnorePointer` to the overlay layer. Updated overlay logic:

```dart
// Layer 1: Line art overlay (always on top, never intercepts touch)
if (lineArtAssetPath != null)
  IgnorePointer(
    child: SvgPicture.asset(
      lineArtAssetPath!,
      fit: BoxFit.fill,
      placeholderBuilder: (_) => const SizedBox.expand(), // silent fallback on load error
    ),
  )
else if (lineArtBytes != null)
  IgnorePointer(
    child: Image.memory(lineArtBytes!, fit: BoxFit.fill, gaplessPlayback: true),
  ),
```

**Important:** `IgnorePointer` is added to **both** overlay types (SVG template and photo bytes). The existing `Image.memory` overlay currently lacks `IgnorePointer` — adding it here is an intentional bug fix bundled into this feature. Without it, touch events on the photo overlay are silently absorbed.

**Important:** The `else if` ordering is intentional — `lineArtAssetPath` (template) takes priority. Both fields are mutually exclusive in practice: `_applyTemplate` nulls out `_lineArtBytes`, and `_pickAndConvertPhoto` nulls out `_activeTemplatePath` (see below). The `else if` guards against any race where both are non-null.

**`BoxFit.fill`** stretches the SVG to fill the canvas exactly. Since SVGs have `viewBox="0 0 400 400"` (square) and the canvas area is typically non-square, there will be slight distortion — this is intentional to ensure drawing coordinates and overlay coordinates always align. `BoxFit.contain` would introduce letterboxing and misalign strokes near edges.

**SVG rendering inside `RepaintBoundary`:** The SVG overlay is inside the `RepaintBoundary` keyed by `_repaintKey`, so `SaveManager.captureCanvas` captures both the drawing layer and the SVG template together. `flutter_svg` renders synchronously into the Flutter layer tree and is fully captured by `RenderRepaintBoundary.toImage`.

#### `lib/screens/coloring_screen.dart`

**State changes:**
- Add `String? _activeTemplatePath` field
- Keep existing `Uint8List? _lineArtBytes` for photo conversion

**New toolbar button:**
- `Icons.pets` icon, tooltip `'Templates'`
- Disabled during `_isProcessing`
- Calls `_onTemplatesTapped()`

**New method `_onTemplatesTapped()`:**
```
if (canvas is blank) → navigate to TemplateScreen
else → show _showSwitchTemplateDialog()
```

Canvas is considered non-blank if `_controller.strokes.isNotEmpty || _lineArtBytes != null || _activeTemplatePath != null`.

**New method `_showSwitchTemplateDialog()`:**
AlertDialog — "Switch template?" with three actions:
1. **Save & Switch** — await `_saveArtwork()`, then navigate to TemplateScreen
2. **Discard & Switch** — navigate directly to TemplateScreen
3. **Cancel** — dismiss

**New method `_applyTemplate(AnimalTemplate template)`:**
```dart
_controller.clear();
setState(() {
  _lineArtBytes = null;          // clear any active photo overlay
  _activeTemplatePath = template.assetPath;
});
```

**Updated `_pickAndConvertPhoto()`** — must clear `_activeTemplatePath` when a photo is loaded, to maintain mutual exclusivity:
```dart
if (mounted) setState(() {
  _lineArtBytes = lineArt;
  _activeTemplatePath = null;    // clear any active template overlay
});
```

**Updated `CanvasStackWidget` call** passes both `lineArtBytes: _lineArtBytes` and `lineArtAssetPath: _activeTemplatePath`.

**Updated `_showClearDialog`** — clears both `_lineArtBytes` and `_activeTemplatePath` in addition to `_controller.clear()`. This is also a bug fix: the existing implementation does not clear `_lineArtBytes` on "Clear drawing", so a photo overlay currently persists after clearing strokes.

#### `pubspec.yaml`

Add dependency:
```yaml
flutter_svg: ^2.0.0
```

Add asset declaration:
```yaml
flutter:
  assets:
    - assets/line_art/
```

---

## Navigation Flow

```
ColoringScreen
  └─ [Templates button tap]
        ├─ blank canvas → push TemplateScreen
        └─ non-blank canvas → AlertDialog
              ├─ Save & Switch → _saveArtwork() → push TemplateScreen
              ├─ Discard & Switch → push TemplateScreen
              └─ Cancel → dismiss

TemplateScreen
  └─ tap card → Navigator.pop(context, template)
        └─ back in ColoringScreen → _applyTemplate(template)
              ├─ _controller.clear()
              ├─ _lineArtBytes = null
              └─ _activeTemplatePath = template.assetPath
```

---

## Testing

| Test file | What it covers |
|-----------|---------------|
| `test/templates/animal_templates_test.dart` | List length == 25, unique IDs, unique asset paths, correct path format |
| `test/screens/template_screen_test.dart` | Widget test: grid renders 25 cards; tapping a card calls `Navigator.pop` with the correct `AnimalTemplate`; back button returns `null` |

`CanvasStackWidget` SVG rendering and visual QA (overlay alignment, art style) require manual `flutter run -d windows` review.

---

## Implementation Sequencing Note

The 25 SVG asset files under `assets/line_art/` must be created **before** `pubspec.yaml` declares `- assets/line_art/`, otherwise `flutter analyze` and `flutter run` will fail with missing asset errors. The implementation plan must sequence SVG asset creation first, then `pubspec.yaml` update, then code changes.

---

## Constraints

- Windows dev environment — no `pod install` / `xcodebuild`
- Visual QA (template grid appearance, SVG rendering, overlay alignment) requires manual `flutter run -d windows` review
- `flutter_svg` renders SVGs in Flutter via a Dart parser — no platform-native SVG engine required, works on Windows desktop
- SVG files must use only basic SVG elements supported by `flutter_svg`: `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`, `g`. No `text`, `image`, `filter`, or `foreignObject`.
- `SvgPicture.asset` should use `placeholderBuilder` to show a grey placeholder if the SVG fails to load (e.g. missing or corrupt asset), preventing a silent blank overlay.
