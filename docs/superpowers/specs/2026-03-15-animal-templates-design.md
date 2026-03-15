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
- Each cell: `AnimalTemplateCard` — rounded card with `SvgPicture.asset` thumbnail + name label below
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
    child: SvgPicture.asset(lineArtAssetPath!, fit: BoxFit.fill),
  )
else if (lineArtBytes != null)
  IgnorePointer(
    child: Image.memory(lineArtBytes!, fit: BoxFit.fill, gaplessPlayback: true),
  ),
```

`IgnorePointer` is added to **both** overlay types (SVG template and photo bytes) so touch always reaches the drawing layer.

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
  _lineArtBytes = null;
  _activeTemplatePath = template.assetPath;
});
```

**Updated `CanvasStackWidget` call** passes both `lineArtBytes: _lineArtBytes` and `lineArtAssetPath: _activeTemplatePath`.

**Updated `_showClearDialog`** — clears both `_lineArtBytes` and `_activeTemplatePath` in addition to `_controller.clear()`.

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

`TemplateScreen` and `CanvasStackWidget` changes are UI-only — covered by manual visual QA via `flutter run -d windows`.

---

## Constraints

- Windows dev environment — no `pod install` / `xcodebuild`
- Visual QA (template grid appearance, SVG rendering, overlay alignment) requires manual `flutter run -d windows` review
- `flutter_svg` renders SVGs in Flutter via a Dart parser — no platform-native SVG engine required, works on Windows desktop
- SVG files must use only basic SVG elements supported by `flutter_svg`: `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`, `g`. No `text`, `image`, `filter`, or `foreignObject`.
