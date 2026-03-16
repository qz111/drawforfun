# Animal Templates Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 25 built-in animal SVG line-art templates that children can select from a dedicated Template Screen, overlaid on the drawing canvas with `IgnorePointer` so strokes always land on the drawing layer.

**Architecture:** A static `AnimalTemplates` registry holds 25 `AnimalTemplate` data objects pointing to SVG asset paths. A new `TemplateScreen` displays them in a 3-column grid using `flutter_svg`. `CanvasStackWidget` gains a `lineArtAssetPath` parameter and wraps both overlay types in `IgnorePointer`. `ColoringScreen` gets a Templates toolbar button and a save-before-switch dialog flow. Two existing bugs are fixed: `IgnorePointer` was missing from the photo overlay, and "Clear drawing" did not clear `_lineArtBytes`.

**Tech Stack:** Flutter (Dart), `flutter_svg ^2.0.0` (SVG rendering), existing `CanvasController` / `DrawingPainter` / `SaveManager` unchanged.

---

## Chunk 1: Data Model, SVG Assets & pubspec

### Task 1: AnimalTemplate data class + registry

**Files:**
- Create: `lib/templates/animal_template.dart`
- Create: `lib/templates/animal_templates.dart`
- Create: `test/templates/animal_templates_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/templates/animal_templates_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/templates/animal_template.dart';
import 'package:drawforfun/templates/animal_templates.dart';

void main() {
  group('AnimalTemplates', () {
    test('has exactly 25 animals', () {
      expect(AnimalTemplates.all.length, 25);
    });

    test('all ids are unique', () {
      final ids = AnimalTemplates.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all assetPaths are unique', () {
      final paths = AnimalTemplates.all.map((t) => t.assetPath).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('all assetPaths follow assets/line_art/<id>.svg pattern', () {
      for (final t in AnimalTemplates.all) {
        expect(t.assetPath, 'assets/line_art/${t.id}.svg');
      }
    });

    test('AnimalTemplate equality is value-based on id', () {
      const a = AnimalTemplate(id: 'cat', name: 'Cat', emoji: '🐱', assetPath: 'assets/line_art/cat.svg');
      const b = AnimalTemplate(id: 'cat', name: 'Cat', emoji: '🐱', assetPath: 'assets/line_art/cat.svg');
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/templates/animal_templates_test.dart -v
```
Expected: compilation error — `animal_template.dart` not found.

- [ ] **Step 3: Create `lib/templates/animal_template.dart`**

```dart
/// Immutable descriptor for a built-in animal line-art template.
class AnimalTemplate {
  final String id;         // file stem, e.g. 'cat'
  final String name;       // display name, e.g. 'Cat'
  final String emoji;      // decorative emoji, e.g. '🐱'
  final String assetPath;  // Flutter asset path, e.g. 'assets/line_art/cat.svg'

  const AnimalTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.assetPath,
  });

  @override
  bool operator ==(Object other) =>
      other is AnimalTemplate &&
      other.id == id &&
      other.name == name &&
      other.emoji == emoji &&
      other.assetPath == assetPath;

  @override
  int get hashCode => Object.hash(id, name, emoji, assetPath);
}
```

- [ ] **Step 4: Create `lib/templates/animal_templates.dart`**

```dart
import 'animal_template.dart';

/// Static registry of all 25 built-in animal templates.
/// Order determines display order in the Template Screen grid.
class AnimalTemplates {
  AnimalTemplates._();

  static const List<AnimalTemplate> all = [
    AnimalTemplate(id: 'cat',        name: 'Cat',        emoji: '🐱', assetPath: 'assets/line_art/cat.svg'),
    AnimalTemplate(id: 'dog',        name: 'Dog',        emoji: '🐶', assetPath: 'assets/line_art/dog.svg'),
    AnimalTemplate(id: 'fox',        name: 'Fox',        emoji: '🦊', assetPath: 'assets/line_art/fox.svg'),
    AnimalTemplate(id: 'panda',      name: 'Panda',      emoji: '🐼', assetPath: 'assets/line_art/panda.svg'),
    AnimalTemplate(id: 'rabbit',     name: 'Rabbit',     emoji: '🐰', assetPath: 'assets/line_art/rabbit.svg'),
    AnimalTemplate(id: 'monkey',     name: 'Monkey',     emoji: '🐵', assetPath: 'assets/line_art/monkey.svg'),
    AnimalTemplate(id: 'elephant',   name: 'Elephant',   emoji: '🐘', assetPath: 'assets/line_art/elephant.svg'),
    AnimalTemplate(id: 'lion',       name: 'Lion',       emoji: '🦁', assetPath: 'assets/line_art/lion.svg'),
    AnimalTemplate(id: 'giraffe',    name: 'Giraffe',    emoji: '🦒', assetPath: 'assets/line_art/giraffe.svg'),
    AnimalTemplate(id: 'bear',       name: 'Bear',       emoji: '🐻', assetPath: 'assets/line_art/bear.svg'),
    AnimalTemplate(id: 'horse',      name: 'Horse',      emoji: '🐴', assetPath: 'assets/line_art/horse.svg'),
    AnimalTemplate(id: 'cow',        name: 'Cow',        emoji: '🐮', assetPath: 'assets/line_art/cow.svg'),
    AnimalTemplate(id: 'pig',        name: 'Pig',        emoji: '🐷', assetPath: 'assets/line_art/pig.svg'),
    AnimalTemplate(id: 'sheep',      name: 'Sheep',      emoji: '🐑', assetPath: 'assets/line_art/sheep.svg'),
    AnimalTemplate(id: 'chicken',    name: 'Chicken',    emoji: '🐔', assetPath: 'assets/line_art/chicken.svg'),
    AnimalTemplate(id: 'duck',       name: 'Duck',       emoji: '🦆', assetPath: 'assets/line_art/duck.svg'),
    AnimalTemplate(id: 'frog',       name: 'Frog',       emoji: '🐸', assetPath: 'assets/line_art/frog.svg'),
    AnimalTemplate(id: 'turtle',     name: 'Turtle',     emoji: '🐢', assetPath: 'assets/line_art/turtle.svg'),
    AnimalTemplate(id: 'fish',       name: 'Fish',       emoji: '🐟', assetPath: 'assets/line_art/fish.svg'),
    AnimalTemplate(id: 'whale',      name: 'Whale',      emoji: '🐳', assetPath: 'assets/line_art/whale.svg'),
    AnimalTemplate(id: 'owl',        name: 'Owl',        emoji: '🦉', assetPath: 'assets/line_art/owl.svg'),
    AnimalTemplate(id: 'penguin',    name: 'Penguin',    emoji: '🐧', assetPath: 'assets/line_art/penguin.svg'),
    AnimalTemplate(id: 'butterfly',  name: 'Butterfly',  emoji: '🦋', assetPath: 'assets/line_art/butterfly.svg'),
    AnimalTemplate(id: 'crocodile',  name: 'Crocodile',  emoji: '🐊', assetPath: 'assets/line_art/crocodile.svg'),
    AnimalTemplate(id: 'bird',       name: 'Bird',       emoji: '🐦', assetPath: 'assets/line_art/bird.svg'),
  ];
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/templates/animal_templates_test.dart -v
```
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/templates/ test/templates/
git commit -m "feat: AnimalTemplate data class and 25-entry registry"
```

---

### Task 2: SVG Assets — Animals 1–16 (cat through duck)

**Files:**
- Create: `assets/line_art/cat.svg` through `assets/line_art/duck.svg` (16 files)

All SVGs: `viewBox="0 0 400 400"`, black stroke `#1a1a1a`, stroke-width 2–2.5, fill `none`, transparent background. Use only `path`, `circle`, `ellipse`, `rect`, `line`, `polyline`, `polygon`, `g`. Medium detail: outer body + face features + paws/fins/wings. No fur texture, no hatching.

- [ ] **Step 1: Create `assets/line_art/cat.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="280" rx="110" ry="90" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="155" r="75" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Ears -->
  <polygon points="148,95 125,45 170,85" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <polygon points="252,95 275,45 230,85" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eyes -->
  <ellipse cx="175" cy="148" rx="14" ry="16" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="225" cy="148" rx="14" ry="16" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Pupils -->
  <ellipse cx="175" cy="150" rx="5" ry="10" fill="#1a1a1a"/>
  <ellipse cx="225" cy="150" rx="5" ry="10" fill="#1a1a1a"/>
  <!-- Nose -->
  <polygon points="200,168 193,178 207,178" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M193,178 Q200,188 207,178" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Whiskers left -->
  <line x1="185" y1="172" x2="135" y2="162" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="185" y1="176" x2="135" y2="176" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="185" y1="180" x2="135" y2="190" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Whiskers right -->
  <line x1="215" y1="172" x2="265" y2="162" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="215" y1="176" x2="265" y2="176" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="215" y1="180" x2="265" y2="190" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Front paws -->
  <ellipse cx="158" cy="355" rx="30" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="242" cy="355" rx="30" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Tail -->
  <path d="M310,280 Q360,220 340,160 Q320,120 350,100" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 2: Create `assets/line_art/dog.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="275" rx="115" ry="95" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="148" r="78" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Floppy ears -->
  <ellipse cx="138" cy="148" rx="28" ry="52" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="262" cy="148" rx="28" ry="52" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eyes -->
  <circle cx="178" cy="138" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="222" cy="138" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="180" cy="138" r="5" fill="#1a1a1a"/>
  <circle cx="224" cy="138" r="5" fill="#1a1a1a"/>
  <!-- Snout -->
  <ellipse cx="200" cy="172" rx="30" ry="22" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nose -->
  <ellipse cx="200" cy="163" rx="12" ry="8" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M188,178 Q200,190 212,178" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Front paws -->
  <ellipse cx="155" cy="358" rx="32" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="245" cy="358" rx="32" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Tail -->
  <path d="M315,265 Q365,230 355,180" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 3: Create `assets/line_art/fox.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="278" rx="108" ry="88" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="152" r="72" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Pointed ears -->
  <polygon points="155,98 135,40 175,88" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <polygon points="245,98 265,40 225,88" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eyes -->
  <ellipse cx="178" cy="145" rx="12" ry="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="222" cy="145" rx="12" ry="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="178" cy="147" rx="5" ry="9" fill="#1a1a1a"/>
  <ellipse cx="222" cy="147" rx="5" ry="9" fill="#1a1a1a"/>
  <!-- Muzzle -->
  <ellipse cx="200" cy="175" rx="28" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nose -->
  <ellipse cx="200" cy="167" rx="10" ry="7" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M190,176 Q200,186 210,176" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Whiskers -->
  <line x1="172" y1="170" x2="125" y2="160" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="172" y1="175" x2="125" y2="175" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="228" y1="170" x2="275" y2="160" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="228" y1="175" x2="275" y2="175" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Paws -->
  <ellipse cx="155" cy="352" rx="30" ry="17" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="245" cy="352" rx="30" ry="17" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Bushy tail -->
  <path d="M308,278 Q368,230 355,165 Q345,130 370,110" fill="none" stroke="#1a1a1a" stroke-width="3"/>
  <ellipse cx="362" cy="108" rx="20" ry="15" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 4: Create `assets/line_art/panda.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="278" rx="118" ry="98" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="148" r="80" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Round ears -->
  <circle cx="148" cy="90" r="28" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <circle cx="252" cy="90" r="28" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Eye patches (filled) -->
  <ellipse cx="178" cy="145" rx="22" ry="20" fill="#1a1a1a"/>
  <ellipse cx="222" cy="145" rx="22" ry="20" fill="#1a1a1a"/>
  <!-- Eyes (white highlights) -->
  <circle cx="178" cy="145" r="10" fill="white"/>
  <circle cx="222" cy="145" r="10" fill="white"/>
  <!-- Pupils -->
  <circle cx="180" cy="145" r="5" fill="#1a1a1a"/>
  <circle cx="224" cy="145" r="5" fill="#1a1a1a"/>
  <!-- Nose -->
  <ellipse cx="200" cy="170" rx="12" ry="8" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M188,176 Q200,188 212,176" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Arm patches -->
  <ellipse cx="98" cy="285" rx="28" ry="48" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="302" cy="285" rx="28" ry="48" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Paws -->
  <ellipse cx="155" cy="355" rx="35" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="245" cy="355" rx="35" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 5: Create `assets/line_art/rabbit.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="285" rx="105" ry="95" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="168" r="68" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Long ears -->
  <ellipse cx="170" cy="80" rx="22" ry="65" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="230" cy="80" rx="22" ry="65" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Inner ears -->
  <ellipse cx="170" cy="80" rx="10" ry="50" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <ellipse cx="230" cy="80" rx="10" ry="50" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Eyes -->
  <circle cx="180" cy="162" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="220" cy="162" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="182" cy="162" r="5" fill="#1a1a1a"/>
  <circle cx="222" cy="162" r="5" fill="#1a1a1a"/>
  <!-- Nose -->
  <ellipse cx="200" cy="182" rx="8" ry="6" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M192,186 Q200,196 208,186" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Whiskers -->
  <line x1="192" y1="182" x2="148" y2="174" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="192" y1="185" x2="148" y2="185" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="208" y1="182" x2="252" y2="174" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="208" y1="185" x2="252" y2="185" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Front paws -->
  <ellipse cx="158" cy="358" rx="28" ry="17" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="242" cy="358" rx="28" ry="17" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Fluffy tail -->
  <circle cx="305" cy="310" r="22" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 6: Create `assets/line_art/monkey.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="278" rx="105" ry="90" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="152" r="72" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Round ears -->
  <circle cx="136" cy="155" r="26" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="264" cy="155" r="26" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Inner ear -->
  <circle cx="136" cy="155" r="14" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <circle cx="264" cy="155" r="14" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Eyes -->
  <circle cx="180" cy="142" r="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="220" cy="142" r="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="182" cy="142" r="6" fill="#1a1a1a"/>
  <circle cx="222" cy="142" r="6" fill="#1a1a1a"/>
  <!-- Snout -->
  <ellipse cx="200" cy="174" rx="32" ry="24" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nose -->
  <ellipse cx="193" cy="168" rx="5" ry="4" fill="#1a1a1a"/>
  <ellipse cx="207" cy="168" rx="5" ry="4" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M186,178 Q200,192 214,178" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Arms -->
  <path d="M95,258 Q55,310 65,360" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M305,258 Q345,310 335,360" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Paws -->
  <ellipse cx="155" cy="355" rx="28" ry="17" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="245" cy="355" rx="28" ry="17" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Tail -->
  <path d="M305,290 Q365,260 370,320 Q375,370 340,380" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 7: Create `assets/line_art/elephant.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="205" cy="270" rx="130" ry="105" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <ellipse cx="175" cy="145" rx="85" ry="75" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Big ears -->
  <ellipse cx="88" cy="148" rx="52" ry="68" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Trunk -->
  <path d="M148,195 Q120,230 125,270 Q130,300 115,325" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Trunk tip -->
  <ellipse cx="113" cy="328" rx="14" ry="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eye -->
  <circle cx="195" cy="130" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="197" cy="130" r="5" fill="#1a1a1a"/>
  <!-- Tusk -->
  <path d="M155,195 Q140,215 148,240" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Legs -->
  <rect x="108" y="350" width="42" height="38" rx="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <rect x="165" y="350" width="42" height="38" rx="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <rect x="222" y="350" width="42" height="38" rx="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Tail -->
  <path d="M335,268 Q360,255 358,285" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 8: Create `assets/line_art/lion.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Mane -->
  <circle cx="200" cy="155" r="105" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Body -->
  <ellipse cx="200" cy="295" rx="108" ry="88" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="155" r="72" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Ears (inside mane) -->
  <polygon points="170,92 155,68 185,88" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <polygon points="230,92 245,68 215,88" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eyes -->
  <ellipse cx="178" cy="145" rx="13" ry="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="222" cy="145" rx="13" ry="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="178" cy="147" rx="5" ry="9" fill="#1a1a1a"/>
  <ellipse cx="222" cy="147" rx="5" ry="9" fill="#1a1a1a"/>
  <!-- Snout -->
  <ellipse cx="200" cy="175" rx="28" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nose -->
  <polygon points="200,165 193,174 207,174" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M190,175 Q200,186 210,175" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Whiskers -->
  <line x1="172" y1="170" x2="128" y2="162" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="172" y1="175" x2="128" y2="175" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="228" y1="170" x2="272" y2="162" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="228" y1="175" x2="272" y2="175" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Paws -->
  <ellipse cx="155" cy="365" rx="32" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="245" cy="365" rx="32" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Tail with tuft -->
  <path d="M308,290 Q360,255 355,205" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <ellipse cx="357" cy="198" rx="14" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 9: Create `assets/line_art/giraffe.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="220" cy="300" rx="95" ry="75" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Long neck -->
  <path d="M175,235 Q168,160 175,95" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M215,232 Q222,158 218,92" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <ellipse cx="196" cy="82" rx="35" ry="28" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Snout extension -->
  <ellipse cx="196" cy="100" rx="20" ry="14" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Ossicones (horns) -->
  <line x1="182" y1="58" x2="178" y2="28" stroke="#1a1a1a" stroke-width="3"/>
  <circle cx="178" cy="26" r="5" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <line x1="210" y1="58" x2="214" y2="28" stroke="#1a1a1a" stroke-width="3"/>
  <circle cx="214" cy="26" r="5" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eye -->
  <circle cx="208" cy="74" r="9" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="210" cy="74" r="4" fill="#1a1a1a"/>
  <!-- Nostril -->
  <ellipse cx="200" cy="105" rx="5" ry="3" fill="#1a1a1a"/>
  <!-- Legs -->
  <line x1="148" y1="358" x2="148" y2="390" stroke="#1a1a1a" stroke-width="8" stroke-linecap="round"/>
  <line x1="185" y1="360" x2="185" y2="392" stroke="#1a1a1a" stroke-width="8" stroke-linecap="round"/>
  <line x1="250" y1="360" x2="250" y2="392" stroke="#1a1a1a" stroke-width="8" stroke-linecap="round"/>
  <line x1="288" y1="358" x2="288" y2="390" stroke="#1a1a1a" stroke-width="8" stroke-linecap="round"/>
  <!-- Tail -->
  <path d="M315,295 Q342,278 338,310" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 10: Create `assets/line_art/bear.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="282" rx="118" ry="98" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="152" r="78" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Ears -->
  <circle cx="148" cy="92" r="28" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <circle cx="252" cy="92" r="28" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <circle cx="148" cy="92" r="14" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <circle cx="252" cy="92" r="14" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Eyes -->
  <circle cx="178" cy="142" r="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="222" cy="142" r="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="180" cy="142" r="6" fill="#1a1a1a"/>
  <circle cx="224" cy="142" r="6" fill="#1a1a1a"/>
  <!-- Snout -->
  <ellipse cx="200" cy="175" rx="32" ry="24" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nose -->
  <ellipse cx="200" cy="167" rx="13" ry="9" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M187,178 Q200,192 213,178" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Paws -->
  <ellipse cx="152" cy="362" rx="35" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="248" cy="362" rx="35" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 11: Create `assets/line_art/horse.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="210" cy="268" rx="130" ry="88" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Neck -->
  <path d="M130,215 Q118,165 135,118" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M158,208 Q152,160 162,115" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <ellipse cx="148" cy="100" rx="38" ry="45" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Nostril -->
  <ellipse cx="140" cy="130" rx="7" ry="5" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eye -->
  <circle cx="162" cy="92" r="9" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="163" cy="92" r="4" fill="#1a1a1a"/>
  <!-- Ear -->
  <polygon points="148,62 140,35 162,58" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Mane -->
  <path d="M162,65 Q172,80 165,95 Q175,110 168,125" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <path d="M155,62 Q168,78 158,92 Q170,108 160,122" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Legs -->
  <line x1="118" y1="340" x2="112" y2="392" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <line x1="158" y1="342" x2="155" y2="394" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <line x1="248" y1="342" x2="252" y2="394" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <line x1="295" y1="338" x2="300" y2="390" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <!-- Tail -->
  <path d="M338,265 Q375,240 370,290 Q368,320 355,345" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 12: Create `assets/line_art/cow.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="210" cy="265" rx="128" ry="95" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Spots -->
  <ellipse cx="175" cy="248" rx="32" ry="22" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <ellipse cx="248" cy="285" rx="25" ry="18" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Neck -->
  <path d="M125,195 Q112,152 128,112" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M158,192 Q150,150 160,110" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <ellipse cx="144" cy="96" rx="42" ry="38" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Snout -->
  <ellipse cx="144" cy="120" rx="26" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="137" cy="120" rx="6" ry="4" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <ellipse cx="151" cy="120" rx="6" ry="4" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Eye -->
  <circle cx="162" cy="88" r="9" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="163" cy="88" r="4" fill="#1a1a1a"/>
  <!-- Ears -->
  <ellipse cx="106" cy="96" rx="16" ry="24" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="182" cy="82" rx="16" ry="20" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Horns -->
  <path d="M128,68 Q118,45 108,52" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <path d="M162,64 Q172,41 182,48" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Legs -->
  <line x1="118" y1="342" x2="112" y2="392" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <line x1="160" y1="345" x2="157" y2="395" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <line x1="248" y1="345" x2="252" y2="395" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <line x1="290" y1="340" x2="296" y2="390" stroke="#1a1a1a" stroke-width="7" stroke-linecap="round"/>
  <!-- Udder -->
  <ellipse cx="200" cy="358" rx="30" ry="15" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Tail -->
  <path d="M337,260 Q368,242 362,280" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 13: Create `assets/line_art/pig.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body (round) -->
  <ellipse cx="200" cy="278" rx="120" ry="102" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="150" r="80" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Ears -->
  <polygon points="158,82 140,42 178,78" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <polygon points="242,82 260,42 222,78" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eyes -->
  <circle cx="175" cy="140" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="225" cy="140" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="177" cy="140" r="5" fill="#1a1a1a"/>
  <circle cx="227" cy="140" r="5" fill="#1a1a1a"/>
  <!-- Snout (big round) -->
  <ellipse cx="200" cy="178" rx="38" ry="30" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Nostrils -->
  <ellipse cx="188" cy="178" rx="8" ry="7" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="212" cy="178" rx="8" ry="7" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Mouth -->
  <path d="M184,190 Q200,202 216,190" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Trotters -->
  <ellipse cx="148" cy="362" rx="30" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="252" cy="362" rx="30" ry="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Curly tail -->
  <path d="M320,278 Q352,262 348,292 Q344,318 360,308" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 14: Create `assets/line_art/sheep.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Fluffy body (overlapping circles suggest wool) -->
  <circle cx="200" cy="272" r="98" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <circle cx="155" cy="250" r="55" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="245" cy="250" r="55" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="200" cy="225" r="52" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Head -->
  <circle cx="200" cy="142" r="52" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Woolly head sides -->
  <circle cx="158" cy="148" r="28" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="242" cy="148" r="28" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Ears -->
  <ellipse cx="138" cy="172" rx="18" ry="28" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="262" cy="172" rx="18" ry="28" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eyes -->
  <circle cx="184" cy="140" r="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="216" cy="140" r="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="186" cy="140" r="4" fill="#1a1a1a"/>
  <circle cx="218" cy="140" r="4" fill="#1a1a1a"/>
  <!-- Snout -->
  <ellipse cx="200" cy="162" rx="22" ry="16" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nose -->
  <ellipse cx="200" cy="157" rx="8" ry="5" fill="#1a1a1a"/>
  <!-- Legs -->
  <line x1="155" y1="355" x2="148" y2="392" stroke="#1a1a1a" stroke-width="6" stroke-linecap="round"/>
  <line x1="180" y1="360" x2="175" y2="397" stroke="#1a1a1a" stroke-width="6" stroke-linecap="round"/>
  <line x1="220" y1="360" x2="225" y2="397" stroke="#1a1a1a" stroke-width="6" stroke-linecap="round"/>
  <line x1="245" y1="355" x2="252" y2="392" stroke="#1a1a1a" stroke-width="6" stroke-linecap="round"/>
</svg>
```

- [ ] **Step 15: Create `assets/line_art/chicken.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body (egg-shaped) -->
  <ellipse cx="200" cy="285" rx="95" ry="108" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Wing -->
  <ellipse cx="275" cy="270" rx="42" ry="65" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Head -->
  <circle cx="200" cy="152" r="58" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Comb -->
  <polygon points="186,98 194,72 202,98" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <polygon points="198,98 206,68 214,98" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Beak -->
  <polygon points="238,152 265,144 265,160" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eye -->
  <circle cx="215" cy="145" r="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="217" cy="145" r="5" fill="#1a1a1a"/>
  <!-- Wattle -->
  <ellipse cx="240" cy="168" rx="10" ry="14" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Feet -->
  <line x1="170" y1="388" x2="162" y2="365" stroke="#1a1a1a" stroke-width="4"/>
  <line x1="162" y1="365" x2="138" y2="372" stroke="#1a1a1a" stroke-width="3"/>
  <line x1="162" y1="365" x2="155" y2="388" stroke="#1a1a1a" stroke-width="3"/>
  <line x1="162" y1="365" x2="172" y2="388" stroke="#1a1a1a" stroke-width="3"/>
  <line x1="230" y1="388" x2="238" y2="365" stroke="#1a1a1a" stroke-width="4"/>
  <line x1="238" y1="365" x2="262" y2="372" stroke="#1a1a1a" stroke-width="3"/>
  <line x1="238" y1="365" x2="245" y2="388" stroke="#1a1a1a" stroke-width="3"/>
  <line x1="238" y1="365" x2="228" y2="388" stroke="#1a1a1a" stroke-width="3"/>
</svg>
```

- [ ] **Step 16: Create `assets/line_art/duck.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="205" cy="290" rx="108" ry="85" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Wing detail -->
  <ellipse cx="272" cy="278" rx="38" ry="58" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Neck -->
  <path d="M148,228 Q138,185 148,155" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M172,222 Q168,180 172,152" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="160" cy="138" r="52" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Bill -->
  <ellipse cx="208" cy="142" rx="30" ry="14" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nostril -->
  <ellipse cx="208" cy="136" rx="6" ry="3" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Eye -->
  <circle cx="172" cy="128" r="10" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="174" cy="128" r="5" fill="#1a1a1a"/>
  <!-- Tail feathers -->
  <path d="M312,278 Q348,255 355,278 Q348,300 338,295" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Feet -->
  <path d="M158,368 Q148,380 128,375 M158,368 Q152,385 148,392 M158,368 Q165,382 158,392" stroke="#1a1a1a" stroke-width="2.5" fill="none"/>
  <path d="M242,368 Q252,380 272,375 M242,368 Q248,385 252,392 M242,368 Q235,382 242,392" stroke="#1a1a1a" stroke-width="2.5" fill="none"/>
</svg>
```

- [ ] **Step 17: Commit**

```bash
git add assets/line_art/
git commit -m "feat: SVG line art assets — cat through duck (animals 1–16)"
```

---

### Task 3: SVG Assets — Animals 17–25 (frog through bird)

**Files:**
- Create: `assets/line_art/frog.svg` through `assets/line_art/bird.svg` (9 files)

- [ ] **Step 1: Create `assets/line_art/frog.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="295" rx="115" ry="88" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head (wide) -->
  <ellipse cx="200" cy="185" rx="95" ry="68" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Bulgy eyes on top -->
  <circle cx="152" cy="138" r="30" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <circle cx="248" cy="138" r="30" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <circle cx="152" cy="138" r="14" fill="#1a1a1a"/>
  <circle cx="248" cy="138" r="14" fill="#1a1a1a"/>
  <circle cx="148" cy="134" r="4" fill="white"/>
  <circle cx="244" cy="134" r="4" fill="white"/>
  <!-- Wide mouth line -->
  <path d="M122,198 Q200,218 278,198" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Nostril dots -->
  <circle cx="188" cy="185" r="4" fill="#1a1a1a"/>
  <circle cx="212" cy="185" r="4" fill="#1a1a1a"/>
  <!-- Front legs -->
  <path d="M95,268 Q68,298 72,332" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M305,268 Q332,298 328,332" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Front feet (webbed) -->
  <path d="M72,332 Q58,345 52,358 M72,332 Q68,350 65,365 M72,332 Q80,348 78,362" stroke="#1a1a1a" stroke-width="2" fill="none"/>
  <path d="M328,332 Q342,345 348,358 M328,332 Q332,350 335,365 M328,332 Q320,348 322,362" stroke="#1a1a1a" stroke-width="2" fill="none"/>
  <!-- Hind legs -->
  <path d="M130,368 Q95,358 72,375" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M270,368 Q305,358 328,375" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 2: Create `assets/line_art/turtle.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Shell (dome) -->
  <ellipse cx="200" cy="235" rx="128" ry="98" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Shell pattern -->
  <ellipse cx="200" cy="220" rx="60" ry="48" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="140" y1="200" x2="200" y2="172" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="260" y1="200" x2="200" y2="172" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="128" y1="240" x2="140" y2="200" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="272" y1="240" x2="260" y2="200" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="140" y1="278" x2="128" y2="240" stroke="#1a1a1a" stroke-width="1.5"/>
  <line x1="260" y1="278" x2="272" y2="240" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Head -->
  <ellipse cx="200" cy="125" rx="42" ry="36" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Neck -->
  <path d="M175,155 L175,170" stroke="#1a1a1a" stroke-width="10" stroke-linecap="round"/>
  <path d="M225,155 L225,170" stroke="#1a1a1a" stroke-width="10" stroke-linecap="round"/>
  <!-- Eyes -->
  <circle cx="185" cy="118" r="9" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="215" cy="118" r="9" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="187" cy="118" r="4" fill="#1a1a1a"/>
  <circle cx="217" cy="118" r="4" fill="#1a1a1a"/>
  <!-- Mouth -->
  <path d="M188,138 Q200,146 212,138" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Four flippers -->
  <ellipse cx="88" cy="205" rx="30" ry="48" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="312" cy="205" rx="30" ry="48" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="140" cy="318" rx="45" ry="22" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="260" cy="318" rx="45" ry="22" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Tail -->
  <path d="M200,332 Q200,355 208,368" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 3: Create `assets/line_art/fish.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="195" cy="200" rx="130" ry="85" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Tail fin -->
  <polygon points="325,200 380,148 380,252" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Top fin -->
  <path d="M155,118 Q175,72 215,118" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Bottom fin -->
  <path d="M165,282 Q185,320 210,282" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Pectoral fin -->
  <ellipse cx="188" cy="215" rx="35" ry="20" fill="none" stroke="#1a1a1a" stroke-width="1.5" transform="rotate(-20 188 215)"/>
  <!-- Eye -->
  <circle cx="110" cy="188" r="22" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="110" cy="188" r="10" fill="#1a1a1a"/>
  <circle cx="106" cy="184" r="3" fill="white"/>
  <!-- Mouth -->
  <path d="M70,200 Q60,210 70,220" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Scales (arc lines) -->
  <path d="M155,165 Q175,155 195,165" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M195,165 Q215,155 235,165" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M235,165 Q255,155 275,165" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M165,195 Q185,185 205,195" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M205,195 Q225,185 245,195" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M155,225 Q175,215 195,225" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M195,225 Q215,215 235,225" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
</svg>
```

- [ ] **Step 4: Create `assets/line_art/whale.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="185" cy="215" rx="158" ry="105" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Tail flukes -->
  <path d="M340,215 Q378,178 388,195 Q378,215 388,235 Q378,252 340,215" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Dorsal fin -->
  <path d="M200,115 Q218,68 245,110" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Pectoral fin -->
  <ellipse cx="118" cy="255" rx="30" ry="55" fill="none" stroke="#1a1a1a" stroke-width="2" transform="rotate(25 118 255)"/>
  <!-- Head -->
  <ellipse cx="55" cy="205" rx="42" ry="58" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Eye -->
  <circle cx="72" cy="185" r="13" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="74" cy="185" r="6" fill="#1a1a1a"/>
  <!-- Mouth (smile) -->
  <path d="M30,225 Q55,248 80,232" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Blowhole -->
  <ellipse cx="92" cy="128" rx="10" ry="7" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Water spout -->
  <path d="M88,122 Q78,98 85,78" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <path d="M96,122 Q106,98 99,78" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Belly line -->
  <path d="M45,248 Q185,295 335,248" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
</svg>
```

- [ ] **Step 5: Create `assets/line_art/owl.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="285" rx="105" ry="105" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Wings -->
  <path d="M98,260 Q62,220 70,165 Q95,240 98,260" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <path d="M302,260 Q338,220 330,165 Q305,240 302,260" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Head (round) -->
  <circle cx="200" cy="162" r="85" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Ear tufts -->
  <polygon points="168,85 155,48 182,82" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <polygon points="232,85 245,48 218,82" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Facial disc -->
  <ellipse cx="200" cy="168" rx="62" ry="58" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Big eyes -->
  <circle cx="175" cy="158" r="28" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="225" cy="158" r="28" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="175" cy="158" r="14" fill="#1a1a1a"/>
  <circle cx="225" cy="158" r="14" fill="#1a1a1a"/>
  <circle cx="170" cy="153" r="4" fill="white"/>
  <circle cx="220" cy="153" r="4" fill="white"/>
  <!-- Beak -->
  <polygon points="200,178 190,198 210,198" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Belly feathers -->
  <path d="M155,295 Q200,280 245,295" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M148,320 Q200,305 252,320" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Talons -->
  <path d="M162,375 Q152,362 148,348 M162,375 Q158,360 165,348 M162,375 Q172,360 175,348" stroke="#1a1a1a" stroke-width="2" fill="none"/>
  <path d="M238,375 Q248,362 252,348 M238,375 Q242,360 235,348 M238,375 Q228,360 225,348" stroke="#1a1a1a" stroke-width="2" fill="none"/>
</svg>
```

- [ ] **Step 6: Create `assets/line_art/penguin.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="200" cy="282" rx="98" ry="108" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- White belly -->
  <ellipse cx="200" cy="295" rx="62" ry="85" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Wings/flippers -->
  <ellipse cx="110" cy="278" rx="28" ry="72" fill="none" stroke="#1a1a1a" stroke-width="2" transform="rotate(-10 110 278)"/>
  <ellipse cx="290" cy="278" rx="28" ry="72" fill="none" stroke="#1a1a1a" stroke-width="2" transform="rotate(10 290 278)"/>
  <!-- Head -->
  <circle cx="200" cy="155" r="70" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- White face -->
  <ellipse cx="200" cy="165" rx="48" ry="45" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Eyes -->
  <circle cx="182" cy="148" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="218" cy="148" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="184" cy="148" r="6" fill="#1a1a1a"/>
  <circle cx="220" cy="148" r="6" fill="#1a1a1a"/>
  <!-- Beak -->
  <polygon points="200,170 188,185 212,185" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Feet -->
  <ellipse cx="168" cy="380" rx="28" ry="14" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <ellipse cx="232" cy="380" rx="28" ry="14" fill="none" stroke="#1a1a1a" stroke-width="2"/>
</svg>
```

- [ ] **Step 7: Create `assets/line_art/butterfly.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body (slender) -->
  <ellipse cx="200" cy="210" rx="10" ry="95" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Head -->
  <circle cx="200" cy="108" r="18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Antennae -->
  <path d="M193,92 Q178,68 170,52" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="168" cy="50" r="5" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <path d="M207,92 Q222,68 230,52" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="232" cy="50" r="5" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Upper wings (large) -->
  <path d="M190,135 Q95,85 68,155 Q50,220 128,235 Q165,240 190,205" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M210,135 Q305,85 332,155 Q350,220 272,235 Q235,240 210,205" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Upper wing inner pattern -->
  <ellipse cx="135" cy="172" rx="32" ry="38" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <ellipse cx="265" cy="172" rx="32" ry="38" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Lower wings (smaller) -->
  <path d="M190,215 Q120,228 100,280 Q108,332 162,318 Q188,308 192,268" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M210,215 Q280,228 300,280 Q292,332 238,318 Q212,308 208,268" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Lower wing dots -->
  <circle cx="155" cy="275" r="12" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <circle cx="245" cy="275" r="12" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
</svg>
```

- [ ] **Step 8: Create `assets/line_art/crocodile.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body (long, low) -->
  <ellipse cx="195" cy="255" rx="155" ry="62" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Tail -->
  <path d="M348,255 Q378,248 390,268 Q382,282 360,275 Q348,270 348,255" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Scales on back -->
  <polygon points="148,195 155,175 162,195" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <polygon points="170,192 177,172 184,192" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <polygon points="192,190 199,170 206,190" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <polygon points="214,192 221,172 228,192" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <polygon points="235,195 242,175 249,195" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Head -->
  <ellipse cx="68" cy="248" rx="62" ry="32" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Snout (flat) -->
  <ellipse cx="38" cy="248" rx="32" ry="22" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Nostrils -->
  <ellipse cx="28" cy="238" rx="5" ry="4" fill="#1a1a1a"/>
  <ellipse cx="42" cy="238" rx="5" ry="4" fill="#1a1a1a"/>
  <!-- Eye (on top of head) -->
  <circle cx="92" cy="225" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="94" cy="225" r="5" fill="#1a1a1a"/>
  <!-- Teeth (upper) -->
  <line x1="22" y1="232" x2="20" y2="222" stroke="#1a1a1a" stroke-width="2"/>
  <line x1="35" y1="228" x2="33" y2="218" stroke="#1a1a1a" stroke-width="2"/>
  <line x1="50" y1="228" x2="48" y2="218" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Legs -->
  <path d="M118,302 Q108,330 95,345" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M175,308 Q168,338 158,352" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M248,305 Q258,335 268,348" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <path d="M305,298 Q318,325 330,338" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 9: Create `assets/line_art/bird.svg`**

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">
  <!-- Body -->
  <ellipse cx="195" cy="255" rx="105" ry="78" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Tail feathers -->
  <path d="M298,258 Q338,235 348,258 Q338,280 298,258" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <path d="M298,255 Q345,222 360,240" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <path d="M298,262 Q345,290 358,275" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Wing -->
  <path d="M142,215 Q175,158 248,195 Q200,218 142,215" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Wing feather details -->
  <path d="M165,205 Q188,172 218,192" fill="none" stroke="#1a1a1a" stroke-width="1.5"/>
  <!-- Head -->
  <circle cx="118" cy="188" r="52" fill="none" stroke="#1a1a1a" stroke-width="2.5"/>
  <!-- Eye -->
  <circle cx="105" cy="178" r="12" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <circle cx="107" cy="178" r="6" fill="#1a1a1a"/>
  <circle cx="105" cy="175" r="2" fill="white"/>
  <!-- Beak -->
  <polygon points="72,185 45,178 45,192" fill="none" stroke="#1a1a1a" stroke-width="2"/>
  <!-- Feet/perch grip -->
  <line x1="160" y1="322" x2="145" y2="355" stroke="#1a1a1a" stroke-width="4"/>
  <line x1="145" y1="355" x2="122" y2="368" stroke="#1a1a1a" stroke-width="2.5"/>
  <line x1="145" y1="355" x2="140" y2="372" stroke="#1a1a1a" stroke-width="2.5"/>
  <line x1="145" y1="355" x2="158" y2="370" stroke="#1a1a1a" stroke-width="2.5"/>
  <line x1="230" y1="322" x2="245" y2="355" stroke="#1a1a1a" stroke-width="4"/>
  <line x1="245" y1="355" x2="268" y2="368" stroke="#1a1a1a" stroke-width="2.5"/>
  <line x1="245" y1="355" x2="250" y2="372" stroke="#1a1a1a" stroke-width="2.5"/>
  <line x1="245" y1="355" x2="232" y2="370" stroke="#1a1a1a" stroke-width="2.5"/>
</svg>
```

- [ ] **Step 10: Commit**

```bash
git add assets/line_art/
git commit -m "feat: SVG line art assets — frog through bird (animals 17–25)"
```

---

### Task 4: pubspec.yaml — add flutter_svg and declare assets

**Files:**
- Modify: `pubspec.yaml`

**Important:** All 25 SVG files must exist in `assets/line_art/` before this step (done in Tasks 2–3).

- [ ] **Step 1: Add flutter_svg dependency and asset declaration**

Edit `pubspec.yaml` — add `flutter_svg: ^2.0.0` under `dependencies` and declare the assets directory:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image: ^4.2.0
  path_provider: ^2.1.2
  file_picker: ^6.1.1
  image_gallery_saver: ^2.0.3
  provider: ^6.1.2
  flutter_svg: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/line_art/
```

- [ ] **Step 2: Fetch the new package**

```bash
flutter pub get
```
Expected: `flutter_svg` resolved, no errors.

- [ ] **Step 3: Run existing tests to confirm nothing broke**

```bash
flutter test
```
Expected: All previously passing tests still pass.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add flutter_svg dependency and declare assets/line_art/ in pubspec"
```

---

## Chunk 2: Template Screen

### Task 5: TemplateScreen widget + widget test

**Files:**
- Create: `lib/screens/template_screen.dart`
- Create: `test/screens/template_screen_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/screens/template_screen_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/templates/animal_template.dart';
import 'package:drawforfun/templates/animal_templates.dart';
import 'package:drawforfun/screens/template_screen.dart';

/// Fake asset bundle that returns minimal valid SVG bytes for every key.
/// SvgPicture.asset calls DefaultAssetBundle.of(context).load(path) at runtime.
/// In widget tests the default bundle is empty, so without this fake every
/// SvgPicture.asset call would throw "Unable to load asset", crashing the test.
class _FakeAssetBundle extends AssetBundle {
  static const _minimalSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400"></svg>';

  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(utf8.encode(_minimalSvg)).buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _minimalSvg;
}

void main() {
  group('TemplateScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: const MaterialApp(home: TemplateScreen()),
        ),
      );
      expect(find.text('Choose an Animal'), findsOneWidget);
    });

    testWidgets('renders a card for every template', (tester) async {
      expect(AnimalTemplates.all.length, 25); // guard: fails loudly if list is empty
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: const MaterialApp(home: TemplateScreen()),
        ),
      );
      await tester.pump(); // allow grid to lay out

      for (final t in AnimalTemplates.all) {
        expect(find.text(t.name), findsOneWidget);
      }
    });

    testWidgets('tapping a card pops with the selected template', (tester) async {
      AnimalTemplate? result;
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Builder(builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<AnimalTemplate>(
                  ctx,
                  MaterialPageRoute(builder: (_) => const TemplateScreen()),
                );
              },
              child: const Text('open'),
            )),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap the first card (Cat)
      await tester.tap(find.text('Cat'));
      await tester.pumpAndSettle();

      expect(result, equals(AnimalTemplates.all.first));
    });

    testWidgets('back button returns null', (tester) async {
      AnimalTemplate? result = const AnimalTemplate(
        id: 'sentinel', name: 'Sentinel', emoji: '?', assetPath: 'x',
      );
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Builder(builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<AnimalTemplate>(
                  ctx,
                  MaterialPageRoute(builder: (_) => const TemplateScreen()),
                );
              },
              child: const Text('open'),
            )),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/screens/template_screen_test.dart -v
```
Expected: compilation error — `template_screen.dart` not found.

- [ ] **Step 3: Implement `lib/screens/template_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../templates/animal_template.dart';
import '../templates/animal_templates.dart';

/// Fullscreen grid for picking a built-in animal line-art template.
/// Returns the selected [AnimalTemplate] via [Navigator.pop], or null on back.
class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          'Choose an Animal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: AnimalTemplates.all.length,
        itemBuilder: (context, index) {
          final template = AnimalTemplates.all[index];
          return _AnimalTemplateCard(
            template: template,
            onTap: () => Navigator.pop(context, template),
          );
        },
      ),
    );
  }
}

class _AnimalTemplateCard extends StatelessWidget {
  final AnimalTemplate template;
  final VoidCallback onTap;

  const _AnimalTemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  template.assetPath,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                template.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/template_screen_test.dart -v
```
Expected: PASS (4 tests).

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/template_screen.dart test/screens/template_screen_test.dart
git commit -m "feat: TemplateScreen grid picker with 25 animal cards"
```

---

## Chunk 3: Canvas Integration & ColoringScreen Wiring

### Task 6: Update CanvasStackWidget — add lineArtAssetPath + IgnorePointer

**Files:**
- Modify: `lib/canvas/canvas_stack_widget.dart`

- [ ] **Step 1: Read the current file**

Read `lib/canvas/canvas_stack_widget.dart` in full before editing.

- [ ] **Step 2: Add `flutter_svg` import and `lineArtAssetPath` parameter, wrap overlays in IgnorePointer**

Replace the full file content with:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (bottom) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
/// The overlay (SVG template or photo PNG) is wrapped in [IgnorePointer]
/// so all touch always reaches the drawing layer.
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// Optional photo line art PNG bytes (from LineArtEngine). Mutually
  /// exclusive with [lineArtAssetPath] — caller must null one when setting the other.
  final Uint8List? lineArtBytes;

  /// Optional SVG asset path for a built-in animal template
  /// (e.g. 'assets/line_art/cat.svg'). Takes priority over [lineArtBytes]
  /// if both are somehow non-null.
  final String? lineArtAssetPath;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtBytes,
    this.lineArtAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => controller.startStroke(
        controller.activeBrushType,
        controller.activeColor,
        d.localPosition,
      ),
      onPanUpdate: (d) => controller.addPoint(d.localPosition),
      onPanEnd: (_) => controller.endStroke(),
      onPanCancel: () => controller.endStroke(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Drawing (colors)
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              painter: DrawingPainter(
                strokes: controller.strokes,
                currentStroke: controller.currentStroke,
              ),
            ),
          ),

          // Layer 1: Line art overlay (always on top, never intercepts touch).
          // SVG template takes priority; falls back to photo PNG bytes.
          if (lineArtAssetPath != null)
            IgnorePointer(
              child: SvgPicture.asset(
                lineArtAssetPath!,
                fit: BoxFit.fill, // fill ensures overlay and drawing layer share the same coordinate space
                placeholderBuilder: (_) => const SizedBox.expand(), // silent fallback on load error
              ),
            )
          else if (lineArtBytes != null)
            IgnorePointer(
              child: Image.memory(
                lineArtBytes!,
                fit: BoxFit.fill,
                // Transparent pixels in the PNG let the drawing layer show through
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```
Expected: All previously passing tests still pass (CanvasStackWidget has no unit test — visual QA via `flutter run -d windows`).

- [ ] **Step 4: Commit**

```bash
git add lib/canvas/canvas_stack_widget.dart
git commit -m "feat: CanvasStackWidget gains lineArtAssetPath + IgnorePointer on both overlay types"
```

---

### Task 7: Update ColoringScreen — Templates button, switch dialog, apply template, fix Clear

**Files:**
- Modify: `lib/screens/coloring_screen.dart`

- [ ] **Step 1: Read the current file**

Read `lib/screens/coloring_screen.dart` in full before editing.

- [ ] **Step 2: Apply all changes**

Replace the full file content with:

```dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../line_art/line_art_engine.dart';
import '../palette/palette_widget.dart';
import '../save/save_manager.dart';
import '../templates/animal_template.dart';
import '../widgets/brush_selector_widget.dart';
import 'template_screen.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _controller = CanvasController();
  final _repaintKey = GlobalKey();

  /// Photo-converted line art bytes (from LineArtEngine). Null when a template is active.
  Uint8List? _lineArtBytes;

  /// Active animal template asset path. Null when photo line art is active or canvas is blank.
  String? _activeTemplatePath;

  bool _isProcessing = false;

  /// True when the canvas has any content worth saving or switching away from.
  bool get _canvasHasContent =>
      _controller.strokes.isNotEmpty ||
      _lineArtBytes != null ||
      _activeTemplatePath != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndConvertPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      final lineArt = await LineArtEngine.convert(result.files.single.bytes!);
      if (mounted) {
        setState(() {
          _lineArtBytes = lineArt;
          _activeTemplatePath = null; // photo overlay replaces any active template
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveArtwork() async {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null || !mounted) return;

    final path = await SaveManager.saveToAppDocuments(bytes);

    // Gallery save (iOS only) failures are silent — in-app save is the primary path.
    await SaveManager.saveToGallery(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Saved!' : 'Save failed'),
          backgroundColor: path != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// Entry point for the Templates toolbar button.
  Future<void> _onTemplatesTapped() async {
    if (_canvasHasContent) {
      await _showSwitchTemplateDialog();
    } else {
      await _navigateToTemplateScreen();
    }
  }

  /// Shows a dialog offering to save, discard, or cancel before switching templates.
  Future<void> _showSwitchTemplateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch template?'),
        content: const Text('You have a drawing in progress.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveArtwork();
              if (mounted) await _navigateToTemplateScreen();
            },
            child: const Text('Save & Switch'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToTemplateScreen();
            },
            child: const Text('Discard & Switch', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Pushes TemplateScreen and applies the selection if one is made.
  Future<void> _navigateToTemplateScreen() async {
    final template = await Navigator.push<AnimalTemplate>(
      context,
      MaterialPageRoute(builder: (_) => const TemplateScreen()),
    );
    if (template != null && mounted) {
      _applyTemplate(template);
    }
  }

  /// Clears strokes and sets the active template, nulling photo overlay.
  void _applyTemplate(AnimalTemplate template) {
    _controller.clear();
    setState(() {
      _lineArtBytes = null;
      _activeTemplatePath = template.assetPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('Draw For Fun', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _isProcessing ? null : _onTemplatesTapped,
            tooltip: 'Templates',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _isProcessing ? null : _pickAndConvertPhoto,
            tooltip: 'Load photo',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _controller.undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isProcessing ? null : () => _showClearDialog(context),
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _isProcessing ? null : _saveArtwork,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : CanvasStackWidget(
                          controller: _controller,
                          lineArtBytes: _lineArtBytes,
                          lineArtAssetPath: _activeTemplatePath,
                        ),
                ),
              ),
            ),
          ),

          // ── Bottom Panel ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => BrushSelectorWidget(
                    selectedBrush: _controller.activeBrushType,
                    onBrushSelected: _controller.setActiveBrush,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => PaletteWidget(
                    selectedColor: _controller.activeColor,
                    onColorSelected: _controller.setActiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text('This will erase everything. Are you sure?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.clear();
              setState(() {
                _lineArtBytes = null;       // bug fix: was not clearing photo overlay
                _activeTemplatePath = null;  // clear template overlay too
              });
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

```bash
flutter analyze
```
Expected: 0 errors.

- [ ] **Step 4: Run all tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat: Templates button, switch-template dialog, _applyTemplate, fix Clear overlay reset"
```

---

### Task 8: Final verification

- [ ] **Step 1: Run full test suite**

```bash
flutter test -v
```
Expected: All tests pass, 0 failures.

- [ ] **Step 2: Run Flutter analyze**

```bash
flutter analyze
```
Expected: 0 issues (errors/warnings from project code). Third-party `file_picker` plugin platform messages in stdout are noise, not analyzer issues.

- [ ] **Step 3: Visual QA (Windows Desktop)**

```bash
flutter run -d windows
```

Verify:
- [ ] Templates button (paw icon) appears in toolbar
- [ ] Tapping Templates on blank canvas opens Template Screen immediately
- [ ] Template Screen shows 25 animal cards in a 3-column grid
- [ ] Each card shows SVG thumbnail and animal name
- [ ] Tapping a card loads it on the canvas
- [ ] Drawing strokes appear on the canvas under the line art
- [ ] Line art stays on top of strokes (IgnorePointer working — touch passes through to drawing)
- [ ] Tapping Templates with strokes on canvas shows "Switch template?" dialog
- [ ] "Save & Switch" saves then navigates to template picker
- [ ] "Discard & Switch" navigates without saving
- [ ] "Cancel" dismisses dialog, canvas unchanged
- [ ] "Clear drawing" button removes strokes AND clears the line art overlay
- [ ] Loading a photo via photo_library button replaces template overlay

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: animal templates feature complete — visual QA passed"
```

---

## File Map Summary

```
lib/
├── templates/
│   ├── animal_template.dart          AnimalTemplate data class
│   └── animal_templates.dart         Static registry of 25 templates
├── screens/
│   ├── template_screen.dart          Grid picker screen (new)
│   └── coloring_screen.dart          Modified: Templates button + switch dialog
└── canvas/
    └── canvas_stack_widget.dart      Modified: lineArtAssetPath + IgnorePointer

assets/
└── line_art/
    └── *.svg                         25 SVG files (cat, dog, fox … bird)

test/
├── templates/
│   └── animal_templates_test.dart    Registry unit tests
└── screens/
    └── template_screen_test.dart     Widget tests: grid + navigation contract

pubspec.yaml                          flutter_svg ^2.0.0 + assets declaration
```
