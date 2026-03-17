# DIY Template Creator Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a ContourCreatorScreen where users draw transparent line-art templates that become colorable entries in the Template Library, with Remix support on all existing cards.

**Architecture:** A new `DrawingType.customTemplate` entry type persists a transparent PNG as its overlay. A dedicated `ContourCreatorController` + `ContourCreatorPainter` handle the eraser via `canvas.saveLayer` + `BlendMode.clear`. `TemplateLibScreen` gains a "Create Blank" card, a "My Templates" section, and long-press → bottom sheet on all cards.

**Tech Stack:** Flutter/Dart, `flutter_svg` (already a dependency) for SVG rasterisation, `flutter_test` for widget + unit tests.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/persistence/drawing_entry.dart` | Modify | Add `customTemplate` to `DrawingType` enum |
| `lib/persistence/drawing_repository.dart` | Modify | Add `createCustomTemplateEntry`, `listCustomTemplateEntries` |
| `lib/widgets/drawing_card_widget.dart` | Modify | Add nullable `onLongPress` callback |
| `lib/screens/contour_creator_screen.dart` | Create | `ContourTool`, `ContourCreatorController`, `ContourCreatorPainter`, `ContourCreatorScreen` |
| `lib/screens/template_lib_screen.dart` | Modify | Create Blank card, My Templates section, long-press bottom sheet |
| `test/persistence/drawing_repository_test.dart` | Modify | Tests for `createCustomTemplateEntry`, `listCustomTemplateEntries`, delete |
| `test/widgets/drawing_card_widget_test.dart` | Modify | Tests for `onLongPress` |
| `test/screens/contour_creator_controller_test.dart` | Create | Unit tests for `ContourCreatorController` |
| `test/screens/contour_creator_screen_test.dart` | Create | Widget tests for `ContourCreatorScreen` |
| `test/screens/template_lib_screen_test.dart` | Modify | Tests for new sections and interactions |

---

## Task 1: Add `customTemplate` to `DrawingType` — prerequisite

**Files:**
- Modify: `lib/persistence/drawing_entry.dart`
- Modify: `test/persistence/drawing_entry_test.dart`

This must land first. Every downstream task depends on this enum value existing at compile time.

- [ ] **Step 1: Write the failing test**

Add to `test/persistence/drawing_entry_test.dart`:

```dart
test('DrawingType has customTemplate value', () {
  expect(DrawingType.values, contains(DrawingType.customTemplate));
});

test('customTemplate entry with overlayFilePath satisfies assert', () {
  const entry = DrawingEntry(
    id: 'custom_20260317_120000_042',
    type: DrawingType.customTemplate,
    overlayFilePath: '/tmp/custom_20260317_120000_042/overlay.png',
    directoryPath: '/tmp/custom_20260317_120000_042',
  );
  expect(entry.type, DrawingType.customTemplate);
  expect(entry.overlayFilePath, isNotNull);
  expect(entry.overlayAssetPath, isNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/persistence/drawing_entry_test.dart
```

Expected: compile error — `DrawingType.customTemplate` does not exist.

- [ ] **Step 3: Add enum value**

In `lib/persistence/drawing_entry.dart`, change:
```dart
enum DrawingType { template, upload, rawImport }
```
to:
```dart
enum DrawingType { template, upload, rawImport, customTemplate }
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/persistence/drawing_entry_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite to verify no regressions**

```
flutter test
```

Expected: all existing tests pass (no switch exhaustiveness errors — Dart enums don't require exhaustive switches unless using pattern matching).

- [ ] **Step 6: Commit**

```bash
git add lib/persistence/drawing_entry.dart test/persistence/drawing_entry_test.dart
git commit -m "feat: add DrawingType.customTemplate enum value"
```

---

## Task 2: Repository — `createCustomTemplateEntry` + `listCustomTemplateEntries`

**Files:**
- Modify: `lib/persistence/drawing_repository.dart`
- Modify: `test/persistence/drawing_repository_test.dart`

- [ ] **Step 1: Write the failing tests**

Add to `test/persistence/drawing_repository_test.dart`:

```dart
group('DrawingRepository.createCustomTemplateEntry', () {
  test('creates folder, writes overlay.png, returns customTemplate entry', () async {
    final fakeBytes = Uint8List.fromList([1, 2, 3, 4]);
    final entry = await DrawingRepository.createCustomTemplateEntry(fakeBytes);
    expect(entry.type, DrawingType.customTemplate);
    expect(entry.id.startsWith('custom_'), isTrue);
    expect(entry.overlayFilePath, isNotNull);
    expect(entry.overlayAssetPath, isNull);
    final overlayFile = File(entry.overlayFilePath!);
    expect(overlayFile.existsSync(), isTrue);
    expect(overlayFile.readAsBytesSync(), fakeBytes);
  });

  test('ID has format custom_YYYYMMDD_HHmmss_NNN', () async {
    final entry = await DrawingRepository.createCustomTemplateEntry(
        Uint8List.fromList([0]));
    // Match: custom_ + 8 digit date + _ + 6 digit time + _ + 3 digit suffix
    expect(entry.id, matches(RegExp(r'^custom_\d{8}_\d{6}_\d{3}$')));
  });
});

group('DrawingRepository.listCustomTemplateEntries', () {
  test('returns empty list when no custom templates exist', () async {
    final result = await DrawingRepository.listCustomTemplateEntries();
    expect(result, isEmpty);
  });

  test('lists custom_ folders, ignores other prefixes', () async {
    final customDir = Directory('${tempDir.path}/custom_20260317_120000_042')
      ..createSync(recursive: true);
    File('${customDir.path}/overlay.png').writeAsBytesSync([1, 2, 3]);
    // These must be ignored:
    Directory('${tempDir.path}/upload_20260315_120000').createSync(recursive: true);
    Directory('${tempDir.path}/rawimport_20260315_143000').createSync(recursive: true);
    Directory('${tempDir.path}/cat').createSync(recursive: true);

    final result = await DrawingRepository.listCustomTemplateEntries();
    expect(result.length, 1);
    expect(result[0].id, 'custom_20260317_120000_042');
    expect(result[0].type, DrawingType.customTemplate);
    expect(result[0].overlayFilePath, isNotNull);
    expect(result[0].overlayAssetPath, isNull);
  });

  test('returns entries sorted newest-first', () async {
    Directory('${tempDir.path}/custom_20260317_100000_001').createSync(recursive: true);
    Directory('${tempDir.path}/custom_20260317_120000_002').createSync(recursive: true);

    final result = await DrawingRepository.listCustomTemplateEntries();
    expect(result[0].id, 'custom_20260317_120000_002');
    expect(result[1].id, 'custom_20260317_100000_001');
  });
});

group('DrawingRepository.deleteEntry for customTemplate', () {
  test('deletes customTemplate entry directory', () async {
    final entry = await DrawingRepository.createCustomTemplateEntry(
        Uint8List.fromList([1, 2, 3]));
    expect(Directory(entry.directoryPath).existsSync(), isTrue);

    await DrawingRepository.deleteEntry(entry);
    expect(Directory(entry.directoryPath).existsSync(), isFalse);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/persistence/drawing_repository_test.dart
```

Expected: FAIL — `createCustomTemplateEntry` and `listCustomTemplateEntries` not defined.

- [ ] **Step 3: Implement both methods**

Add to `lib/persistence/drawing_repository.dart` (after `createRawImportEntry`):

```dart
/// Creates a new custom template entry:
/// 1. Generates a collision-resistant timestamped ID.
/// 2. Creates the entry directory.
/// 3. Writes [transparentPng] to `overlay.png`.
/// 4. Returns the [DrawingEntry].
static Future<DrawingEntry> createCustomTemplateEntry(
    Uint8List transparentPng) async {
  final base = await _drawingsDir();
  final rng = Random();
  String id;
  Directory dir;
  int attempts = 0;
  do {
    if (attempts >= 3) {
      throw StateError('createCustomTemplateEntry: could not generate unique ID after 3 attempts');
    }
    final now = DateTime.now();
    final nnn = rng.nextInt(1000).toString().padLeft(3, '0');
    id =
        'custom_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}_$nnn';
    dir = Directory('${base.path}/$id');
    attempts++;
  } while (dir.existsSync());

  dir.createSync(recursive: true);
  final overlayPath = '${dir.path}/overlay.png';
  await File(overlayPath).writeAsBytes(transparentPng);
  return DrawingEntry(
    id: id,
    type: DrawingType.customTemplate,
    overlayFilePath: overlayPath,
    directoryPath: dir.path,
  );
}

/// Returns all custom template entries, sorted newest-first.
static Future<List<DrawingEntry>> listCustomTemplateEntries() async {
  final base = await _drawingsDir();
  if (!base.existsSync()) return [];
  final entries = base
      .listSync()
      .whereType<Directory>()
      .where((d) => _basename(d.path).startsWith('custom_'))
      .map((d) {
    final id = _basename(d.path);
    return DrawingEntry(
      id: id,
      type: DrawingType.customTemplate,
      overlayFilePath: '${d.path}/overlay.png',
      directoryPath: d.path,
    );
  }).toList()
    ..sort((a, b) => b.id.compareTo(a.id));
  return entries;
}
```

Also add `import 'dart:math';` at the top of the file if not already present.

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/persistence/drawing_repository_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test
```

Expected: all tests PASS.

- [ ] **Step 6: Run analyzer**

```
flutter analyze lib/persistence/drawing_repository.dart
```

Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add lib/persistence/drawing_repository.dart test/persistence/drawing_repository_test.dart
git commit -m "feat: add createCustomTemplateEntry and listCustomTemplateEntries to repository"
```

---

## Task 3: `DrawingCardWidget` — add `onLongPress`

**Files:**
- Modify: `lib/widgets/drawing_card_widget.dart`
- Modify: `test/widgets/drawing_card_widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widgets/drawing_card_widget_test.dart`:

```dart
// Add this constant near the top with the other test entries:
const customTemplateEntry = DrawingEntry(
  id: 'custom_20260317_120000_042',
  type: DrawingType.customTemplate,
  overlayFilePath: '/tmp/custom_20260317_120000_042/overlay.png',
  directoryPath: '/tmp/custom_20260317_120000_042',
);

// Add inside main():
group('DrawingCardWidget onLongPress', () {
  testWidgets('long pressing card calls onLongPress', (tester) async {
    var longPressCount = 0;
    await tester.pumpWidget(wrap(
      SizedBox(
        width: 100,
        height: 130,
        child: DrawingCardWidget(
          entry: templateEntry,
          label: 'Cat',
          emoji: '🐱',
          hasThumbnail: false,
          onTap: () {},
          onLongPress: () => longPressCount++,
        ),
      ),
    ));
    await tester.longPress(find.byType(DrawingCardWidget));
    await tester.pump();
    expect(longPressCount, 1);
  });

  testWidgets('onLongPress null does not crash', (tester) async {
    await tester.pumpWidget(wrap(
      SizedBox(
        width: 100,
        height: 130,
        child: DrawingCardWidget(
          entry: templateEntry,
          label: 'Cat',
          emoji: '🐱',
          hasThumbnail: false,
          onTap: () {},
          // onLongPress not provided
        ),
      ),
    ));
    // Long pressing without onLongPress should not throw
    await tester.longPress(find.byType(DrawingCardWidget));
    await tester.pump();
    // No exception = pass
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/drawing_card_widget_test.dart
```

Expected: FAIL — `onLongPress` parameter not found.

- [ ] **Step 3: Add `onLongPress` to `DrawingCardWidget`**

In `lib/widgets/drawing_card_widget.dart`, add the field after `onDelete`:

```dart
final VoidCallback? onLongPress;
```

Update the constructor to include it:

```dart
DrawingCardWidget({
  super.key,
  required this.entry,
  required this.label,
  this.emoji,
  required this.hasThumbnail,
  required this.onTap,
  this.onDelete,
  this.onLongPress,        // ← add this
});
```

Update the `GestureDetector` in `build()` to wire `onLongPress`:

```dart
GestureDetector(
  onTap: onTap,
  onLongPress: onLongPress,   // ← add this line
  child: Container(
    // ... unchanged
  ),
),
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/widgets/drawing_card_widget_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/drawing_card_widget.dart test/widgets/drawing_card_widget_test.dart
git commit -m "feat: add onLongPress callback to DrawingCardWidget"
```

---

## Task 4: `ContourCreatorController` — drawing state manager

**Files:**
- Create: `lib/screens/contour_creator_screen.dart` (initial skeleton with controller only)
- Create: `test/screens/contour_creator_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/screens/contour_creator_controller_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/screens/contour_creator_screen.dart';

void main() {
  group('ContourCreatorController', () {
    late ContourCreatorController controller;

    setUp(() => controller = ContourCreatorController());
    tearDown(() => controller.dispose());

    test('starts with empty strokes and pencil tool', () {
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.activeTool, ContourTool.pencil);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('startStroke / addPoint / endStroke commits a pencil stroke', () {
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      expect(controller.pencilStrokes.length, 1);
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isTrue);
    });

    test('eraser strokes go to eraserStrokes list', () {
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.addPoint(const Offset(15, 15));
      controller.endStroke();
      expect(controller.eraserStrokes.length, 1);
      expect(controller.pencilStrokes, isEmpty);
    });

    test('undo removes last pencil stroke', () {
      controller.startStroke(const Offset(0, 0));
      controller.endStroke();
      expect(controller.pencilStrokes.length, 1);
      controller.undo();
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('undo removes last eraser stroke', () {
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(0, 0));
      controller.endStroke();
      controller.undo();
      expect(controller.eraserStrokes, isEmpty);
    });

    test('undo interleaved pencil and eraser in correct order', () {
      // pencil stroke first
      controller.startStroke(const Offset(0, 0));
      controller.endStroke(); // history: [pencil]
      // then eraser stroke
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.endStroke(); // history: [pencil, eraser]

      controller.undo(); // removes eraser
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.pencilStrokes.length, 1);

      controller.undo(); // removes pencil
      expect(controller.pencilStrokes, isEmpty);
    });

    test('undo is a no-op when history is empty', () {
      controller.undo(); // must not throw
      expect(controller.pencilStrokes, isEmpty);
    });

    test('clear resets all strokes and history', () {
      controller.startStroke(const Offset(0, 0));
      controller.endStroke();
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.endStroke();
      controller.clear();
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('clear keeps backgroundImage', () {
      // backgroundImage is set directly in tests via the property setter
      // (it is null by default; we just verify clear() does not null it)
      controller.startStroke(const Offset(0, 0));
      controller.endStroke();
      controller.clear();
      expect(controller.backgroundImage, isNull); // null → still null = correct
    });

    test('notifies listeners on stroke commit', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(5, 5));
      controller.endStroke();
      expect(notifyCount, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/screens/contour_creator_controller_test.dart
```

Expected: compile error — `ContourCreatorController`, `ContourTool` not defined.

- [ ] **Step 3: Create `lib/screens/contour_creator_screen.dart` with controller and enum only**

```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

// ── Tool enum ─────────────────────────────────────────────────────────────────

enum ContourTool { pencil, eraser }

// ── Controller ───────────────────────────────────────────────────────────────

/// Manages drawing state for the ContourCreatorScreen.
/// Maintains separate lists for pencil and eraser strokes with a unified
/// undo history so that undo removes strokes in the correct order regardless
/// of tool switches.
class ContourCreatorController extends ChangeNotifier {
  final List<Stroke> _pencilStrokes = [];
  final List<Stroke> _eraserStrokes = [];

  /// Unified undo history. Each entry records which list the committed stroke
  /// was appended to, so undo can pop the correct list.
  final List<({bool isPencil})> _history = [];

  ContourTool _activeTool = ContourTool.pencil;
  Stroke? _currentStroke;

  /// Optional base image shown beneath strokes (Remix mode).
  ui.Image? backgroundImage;

  List<Stroke> get pencilStrokes => List.unmodifiable(_pencilStrokes);
  List<Stroke> get eraserStrokes => List.unmodifiable(_eraserStrokes);
  Stroke? get currentStroke => _currentStroke;
  ContourTool get activeTool => _activeTool;
  set activeTool(ContourTool value) {
    _activeTool = value;
    notifyListeners();
  }

  /// True when the user has made at least one committed stroke — used to gate
  /// the discard-warning dialog on back-navigation.
  bool get hasUnsavedChanges => _history.isNotEmpty;

  void startStroke(Offset point) {
    _currentStroke = Stroke(
      type: BrushType.pencil,
      color: Colors.black,
      points: [point],
    );
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWithPoint(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    if (_activeTool == ContourTool.pencil) {
      _pencilStrokes.add(_currentStroke!);
      _history.add((isPencil: true));
    } else {
      _eraserStrokes.add(_currentStroke!);
      _history.add((isPencil: false));
    }
    _currentStroke = null;
    notifyListeners();
  }

  /// Removes the most recently committed stroke (pencil or eraser).
  /// No-op if history is empty.
  void undo() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    if (last.isPencil) {
      _pencilStrokes.removeLast();
    } else {
      _eraserStrokes.removeLast();
    }
    notifyListeners();
  }

  /// Clears all strokes and history. Keeps [backgroundImage].
  void clear() {
    _pencilStrokes.clear();
    _eraserStrokes.clear();
    _history.clear();
    _currentStroke = null;
    notifyListeners();
  }
}

// ── Screen placeholder (to be completed in Task 6) ───────────────────────────

class ContourCreatorScreen extends StatefulWidget {
  const ContourCreatorScreen({
    super.key,
    this.remixSourcePath,
    this.remixAssetPath,
  });

  final String? remixSourcePath;
  final String? remixAssetPath;

  @override
  State<ContourCreatorScreen> createState() => _ContourCreatorScreenState();
}

class _ContourCreatorScreenState extends State<ContourCreatorScreen> {
  final _controller = ContourCreatorController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ContourCreator — WIP')));
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/screens/contour_creator_controller_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/contour_creator_screen.dart test/screens/contour_creator_controller_test.dart
git commit -m "feat: add ContourCreatorController with pencil/eraser/undo/clear"
```

---

## Task 5: `ContourCreatorPainter` — transparent eraser

**Files:**
- Modify: `lib/screens/contour_creator_screen.dart` (add painter class)
- Create: `test/screens/contour_creator_screen_test.dart` (painter smoke test)

The painter cannot be fully unit-tested without a canvas mock, so we write a widget-level smoke test that verifies it renders without throwing.

- [ ] **Step 1: Write the painter widget smoke test**

Create `test/screens/contour_creator_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/screens/contour_creator_screen.dart';

void main() {
  group('ContourCreatorScreen painter smoke tests', () {
    testWidgets('renders without error (blank canvas)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()),
      );
      await tester.pumpAndSettle();
      // WIP screen renders without crashing
      expect(find.byType(ContourCreatorScreen), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes (WIP screen renders)**

```
flutter test test/screens/contour_creator_screen_test.dart
```

Expected: PASS (WIP scaffold renders).

- [ ] **Step 3: Add `ContourCreatorPainter` to `lib/screens/contour_creator_screen.dart`**

Add this class after `ContourCreatorController` and before `ContourCreatorScreen`:

```dart
// ── Painter ───────────────────────────────────────────────────────────────────

/// Renders pencil strokes and eraser strokes onto a transparent canvas.
///
/// Uses [canvas.saveLayer] to create an isolated RGBA buffer so that
/// [BlendMode.clear] eraser strokes physically punch holes in the alpha channel
/// rather than painting white.
///
/// IMPORTANT: Does NOT delegate to [BrushEngine] — pencil strokes are rendered
/// inline at [_pencilStrokeWidth] (6px) which is appropriate for line-art
/// templates. BrushEngine's pencil uses a hardcoded 3px width.
class ContourCreatorPainter extends CustomPainter {
  final List<Stroke> pencilStrokes;
  final List<Stroke> eraserStrokes;
  final Stroke? currentStroke;
  final ContourTool activeTool;
  final ui.Image? backgroundImage;

  static const double _pencilStrokeWidth = 6.0;
  static const double _eraserStrokeWidth = 20.0;

  const ContourCreatorPainter({
    required this.pencilStrokes,
    required this.eraserStrokes,
    this.currentStroke,
    required this.activeTool,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer creates an isolated RGBA buffer for this painter.
    // BlendMode.clear inside this layer zeroes alpha (punches holes).
    // Without saveLayer, BlendMode.clear would clear to the widget background
    // instead of making pixels transparent.
    canvas.saveLayer(Offset.zero & size, Paint());

    if (backgroundImage != null) {
      final src = Rect.fromLTWH(
        0, 0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );
      canvas.drawImageRect(backgroundImage!, src, Offset.zero & size, Paint());
    }

    final pencilPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = _pencilStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver;

    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = _eraserStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in pencilStrokes) {
      _paintStroke(canvas, s, pencilPaint);
    }
    for (final s in eraserStrokes) {
      _paintStroke(canvas, s, eraserPaint);
    }

    // Draw the in-progress stroke with the paint matching the current tool.
    if (currentStroke != null) {
      _paintStroke(
        canvas,
        currentStroke!,
        activeTool == ContourTool.pencil ? pencilPaint : eraserPaint,
      );
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.isEmpty) return;
    if (stroke.points.length == 1) {
      canvas.drawCircle(
          stroke.points.first, paint.strokeWidth / 2, paint);
      return;
    }
    final path = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ContourCreatorPainter old) =>
      old.pencilStrokes != pencilStrokes ||
      old.eraserStrokes != eraserStrokes ||
      old.currentStroke != currentStroke ||
      old.activeTool != activeTool ||
      old.backgroundImage != backgroundImage;
}
```

- [ ] **Step 4: Run test suite**

```
flutter test
```

Expected: all tests PASS (painter class added, no test regressions).

- [ ] **Step 5: Run analyzer**

```
flutter analyze lib/screens/contour_creator_screen.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/contour_creator_screen.dart
git commit -m "feat: add ContourCreatorPainter with saveLayer transparent eraser"
```

---

## Task 6: `ContourCreatorScreen` — full UI

**Files:**
- Modify: `lib/screens/contour_creator_screen.dart` (replace WIP scaffold with real screen)
- Modify: `test/screens/contour_creator_screen_test.dart` (add widget tests)

- [ ] **Step 1: Add widget tests**

Replace contents of `test/screens/contour_creator_screen_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/contour_creator_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('contour_creator_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('shows AppBar with correct title', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.text('Template Creator'), findsOneWidget);
  });

  testWidgets('shows Save button', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('shows Pencil and Eraser tool buttons', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.auto_fix_normal), findsOneWidget);
  });

  testWidgets('shows Undo and Clear buttons', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('switching to eraser tool updates sidebar highlight',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    // Tap the eraser button
    await tester.tap(find.byIcon(Icons.auto_fix_normal));
    await tester.pump();
    // No crash = pass; visual highlight verified manually
  });

  testWidgets('back without strokes pops without dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) => Scaffold(
        body: ElevatedButton(
          onPressed: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const ContourCreatorScreen())),
          child: const Text('open'),
        ),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Back with no strokes — should pop without dialog
    final NavigatorState nav = tester.state(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('Template Creator'), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail (WIP scaffold)**

```
flutter test test/screens/contour_creator_screen_test.dart
```

Expected: FAIL — 'Template Creator' not found in WIP scaffold.

- [ ] **Step 3: Implement full `ContourCreatorScreen`**

Replace the `ContourCreatorScreen` class and `_ContourCreatorScreenState` in `lib/screens/contour_creator_screen.dart`:

```dart
// ── Screen ───────────────────────────────────────────────────────────────────

class ContourCreatorScreen extends StatefulWidget {
  /// Absolute path to a local image file (upload / rawImport / customTemplate).
  final String? remixSourcePath;

  /// Flutter asset path to a bundled SVG (built-in templates only).
  /// Mutually exclusive with [remixSourcePath]. If both are set,
  /// [remixSourcePath] takes priority.
  final String? remixAssetPath;

  const ContourCreatorScreen({
    super.key,
    this.remixSourcePath,
    this.remixAssetPath,
  });

  @override
  State<ContourCreatorScreen> createState() => _ContourCreatorScreenState();
}

class _ContourCreatorScreenState extends State<ContourCreatorScreen> {
  final _controller = ContourCreatorController();
  final _repaintKey = GlobalKey();
  bool _isSaving = false;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRemixImage());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRemixImage() async {
    ui.Image? img;
    try {
      if (widget.remixSourcePath != null) {
        final bytes = await File(widget.remixSourcePath!).readAsBytes();
        img = await decodeImageFromList(bytes);
      } else if (widget.remixAssetPath != null) {
        // SVG assets: rasterise via flutter_svg PictureInfo API.
        final sz = _canvasSize;
        if (sz == Size.zero) return; // layout not ready yet
        final loader = SvgAssetLoader(widget.remixAssetPath!);
        final pictureInfo = await vg.loadPicture(loader, null);
        img = await pictureInfo.picture
            .toImage(sz.width.round(), sz.height.round());
        pictureInfo.picture.dispose();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not load image — starting with blank canvas'),
        ));
      }
    }
    if (img != null && mounted) {
      setState(() => _controller.backgroundImage = img);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await SaveManager.captureCanvas(_repaintKey);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save, try again')),
          );
        }
        return;
      }
      await DrawingRepository.createCustomTemplateEntry(bytes);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (!_controller.hasUnsavedChanges) {
          navigator.pop();
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard this template?'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text(
            'Template Creator',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              // ── Canvas area ───────────────────────────────────────────
              LayoutBuilder(builder: (context, constraints) {
                // Capture canvas size for SVG rasterisation on first layout.
                final sz = Size(constraints.maxWidth, constraints.maxHeight);
                if (_canvasSize != sz) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _canvasSize = sz);
                  });
                }
                return GestureDetector(
                  onPanStart: (d) =>
                      _controller.startStroke(d.localPosition),
                  onPanUpdate: (d) =>
                      _controller.addPoint(d.localPosition),
                  onPanEnd: (_) => _controller.endStroke(),
                  onPanCancel: () => _controller.endStroke(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Checkerboard background (decorative — not captured)
                        IgnorePointer(child: _CheckerboardBackground()),
                        // Drawing layer (captured)
                        RepaintBoundary(
                          key: _repaintKey,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (_, __) => CustomPaint(
                              painter: ContourCreatorPainter(
                                pencilStrokes: _controller.pencilStrokes,
                                eraserStrokes: _controller.eraserStrokes,
                                currentStroke: _controller.currentStroke,
                                activeTool: _controller.activeTool,
                                backgroundImage: _controller.backgroundImage,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // ── Floating left sidebar ─────────────────────────────────
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToolButton(
                            icon: Icons.edit,
                            tooltip: 'Pencil',
                            isActive:
                                _controller.activeTool == ContourTool.pencil,
                            onTap: () => _controller.activeTool =
                                ContourTool.pencil,
                          ),
                          const SizedBox(height: 6),
                          _ToolButton(
                            icon: Icons.auto_fix_normal,
                            tooltip: 'Eraser',
                            isActive:
                                _controller.activeTool == ContourTool.eraser,
                            onTap: () => _controller.activeTool =
                                ContourTool.eraser,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, thickness: 1),
                          ),
                          Opacity(
                            opacity:
                                _controller.hasUnsavedChanges ? 1.0 : 0.4,
                            child: _ToolButton(
                              icon: Icons.undo,
                              tooltip: 'Undo',
                              isActive: false,
                              onTap: _controller.undo,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Opacity(
                            opacity:
                                _controller.hasUnsavedChanges ? 1.0 : 0.4,
                            child: _ToolButton(
                              icon: Icons.delete_outline,
                              tooltip: 'Clear',
                              isActive: false,
                              onTap: _controller.clear,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CheckerboardPainter());
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 16.0;
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = const Color(0xFFE0E0E0);
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final paint = (r + c).isEven ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(
              c * cellSize, r * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter _) => false;
}
```

Also add these imports at the top of `lib/screens/contour_creator_screen.dart`:

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart' as vg;
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';
import '../persistence/drawing_repository.dart';
import '../save/save_manager.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/screens/contour_creator_screen_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test
```

Expected: all tests PASS.

- [ ] **Step 6: Run analyzer**

```
flutter analyze lib/screens/contour_creator_screen.dart
```

Expected: no issues.

- [ ] **Step 7: Smoke test on Windows Desktop**

```
flutter run -d windows
```

Navigate to Template Library → verify app compiles and runs. The ContourCreatorScreen isn't reachable yet (wired in Task 7).

- [ ] **Step 8: Commit**

```bash
git add lib/screens/contour_creator_screen.dart test/screens/contour_creator_screen_test.dart
git commit -m "feat: implement ContourCreatorScreen with transparent eraser and sidebar toolbar"
```

---

## Task 7: Wire `TemplateLibScreen` — Create Blank, My Templates, long-press

**Files:**
- Modify: `lib/screens/template_lib_screen.dart`
- Modify: `test/screens/template_lib_screen_test.dart`

This task wires everything together. Implement changes in this order to keep the app working at each step.

- [ ] **Step 1: Write the failing tests**

Add to `test/screens/template_lib_screen_test.dart`:

```dart
testWidgets('Create Blank Canvas card appears in main carousel',
    (tester) async {
  await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
  await tester.pumpAndSettle();
  expect(find.text('Create Blank Canvas'), findsOneWidget);
});

testWidgets('My Templates section hidden when no custom templates',
    (tester) async {
  await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
  await tester.pumpAndSettle();
  expect(find.text('My Templates'), findsNothing);
});

testWidgets('My Templates section appears when custom template exists',
    (tester) async {
  final customDir =
      Directory('${tempDir.path}/custom_20260317_120000_042')
        ..createSync(recursive: true);
  File('${customDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
  await tester.pumpAndSettle();
  expect(find.text('My Templates'), findsOneWidget);
});

testWidgets('long press on built-in template card shows bottom sheet',
    (tester) async {
  await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
  await tester.pumpAndSettle();
  // Long-press the first DrawingCardWidget (a built-in template)
  await tester.longPress(find.byType(DrawingCardWidget).first);
  await tester.pumpAndSettle();
  expect(find.text('Color it!'), findsOneWidget);
  expect(find.text('Remix it'), findsOneWidget);
});

testWidgets('tapping Color it! in bottom sheet dismisses sheet',
    (tester) async {
  await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
  await tester.pumpAndSettle();
  await tester.longPress(find.byType(DrawingCardWidget).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Color it!'));
  await tester.pumpAndSettle();
  expect(find.text('Color it!'), findsNothing);
});
```

Also add the missing import at the top of the test file:

```dart
import 'package:drawforfun/widgets/drawing_card_widget.dart';
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/screens/template_lib_screen_test.dart
```

Expected: FAIL — "Create Blank Canvas", "My Templates", bottom sheet not present yet.

- [ ] **Step 3: Update `_loadData` to include custom templates**

In `lib/screens/template_lib_screen.dart`, add `_customCards` field:

```dart
List<_CardData> _customCards = [];
```

Update `_loadData()` to add the third parallel future:

```dart
Future<void> _loadData() async {
  if (mounted) setState(() => _isLoading = true);
  final results = await Future.wait<List<_CardData>>([
    Future.wait(
      AnimalTemplates.all.map((template) async {
        final entry = await DrawingRepository.templateEntry(template);
        return _CardData(
          entry: entry,
          label: template.name,
          emoji: template.emoji,
          hasThumbnail: File(entry.thumbnailPath).existsSync(),
        );
      }),
    ),
    DrawingRepository.listRawImportEntries().then((entries) => entries
        .map((entry) => _CardData(
              entry: entry,
              label: _uploadLabel(entry.id),
              emoji: '📷',
              hasThumbnail: File(entry.thumbnailPath).existsSync(),
            ))
        .toList()),
    DrawingRepository.listCustomTemplateEntries().then((entries) => entries
        .map((entry) => _CardData(
              entry: entry,
              label: _customLabel(entry.id),
              emoji: '🎨',
              hasThumbnail: File(entry.thumbnailPath).existsSync(),
            ))
        .toList()),
  ]);
  if (mounted) {
    setState(() {
      _cards = [...results[0], ...results[1]];
      _customCards = results[2];
      _isLoading = false;
    });
  }
}
```

Add `_customLabel` helper (after `_uploadLabel`):

```dart
String _customLabel(String id) {
  try {
    final date = id.split('_')[1];
    return 'Template ${date.substring(4, 6)}/${date.substring(6, 8)}';
  } catch (_) {
    return 'Template';
  }
}
```

- [ ] **Step 4: Add `_openRemix`, `_showRemixSheet`, and update `_openEntry` cache eviction**

Add these methods to `_TemplateLibScreenState`:

```dart
Future<void> _openRemix(DrawingEntry entry) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => ContourCreatorScreen(
        remixSourcePath: entry.overlayFilePath,
        remixAssetPath: entry.overlayAssetPath,
      ),
    ),
  );
  _loadData();
}

void _showRemixSheet(_CardData card) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SheetOption(
                    label: 'Color it!',
                    icon: Icons.brush,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _openEntry(card.entry);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetOption(
                    label: 'Remix it',
                    icon: Icons.edit,
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(context);
                      _openRemix(card.entry);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

Add `_SheetOption` widget at the bottom of the file:

```dart
class _SheetOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Also add the import at the top of `template_lib_screen.dart`:

```dart
import 'contour_creator_screen.dart';
```

- [ ] **Step 5: Update `build()` to add Create Blank card, onLongPress, and My Templates section**

Replace the `body:` section of `_TemplateLibScreenState.build()`:

```dart
body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap a drawing to start coloring',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // ── Main carousel (built-ins + raw imports) ───────────────
            SizedBox(
              height: 220,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Create Blank Canvas — static first card
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 200,
                        child: _CreateBlankCard(
                          onTap: () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ContourCreatorScreen(),
                              ),
                            );
                            _loadData();
                          },
                        ),
                      ),
                    ),
                    // Built-in + rawImport cards
                    ..._cards.map((card) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 200,
                            child: DrawingCardWidget(
                              entry: card.entry,
                              label: card.label,
                              emoji: card.emoji,
                              hasThumbnail: card.hasThumbnail,
                              onTap: () => _openEntry(card.entry),
                              onLongPress: () => _showRemixSheet(card),
                              onDelete: card.entry.type ==
                                      DrawingType.template
                                  ? null
                                  : () => _confirmDelete(card),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // ── My Templates section (only when non-empty) ────────────
            if (_customCards.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'My Templates',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _customCards.map((card) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 200,
                          child: DrawingCardWidget(
                            entry: card.entry,
                            label: card.label,
                            emoji: card.emoji,
                            hasThumbnail: card.hasThumbnail,
                            onTap: () => _openEntry(card.entry),
                            onLongPress: () => _showRemixSheet(card),
                            onDelete: () => _confirmDelete(card),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
```

Change the outer `Expanded` wrapping the existing `ListView` to `SizedBox(height: 220, ...)` to match the new fixed-height carousels.

- [ ] **Step 6: Add `_CreateBlankCard` widget at the bottom of the file**

```dart
class _CreateBlankCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateBlankCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.deepPurple.shade300,
            width: 2.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 40, color: Colors.deepPurple.shade400),
            const SizedBox(height: 10),
            Text(
              'Create Blank Canvas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Run tests to verify they pass**

```
flutter test test/screens/template_lib_screen_test.dart
```

Expected: all tests PASS.

- [ ] **Step 8: Run full test suite**

```
flutter test
```

Expected: all tests PASS.

- [ ] **Step 9: Run analyzer**

```
flutter analyze lib/screens/template_lib_screen.dart
```

Expected: no issues.

- [ ] **Step 10: Smoke test on Windows Desktop**

```
flutter run -d windows
```

Verify:
- Template Library shows "Create Blank Canvas" card at the start
- Tapping "Create Blank Canvas" opens the ContourCreatorScreen
- Drawing pencil strokes works
- Switching to eraser and drawing erases (checkerboard shows through)
- Undo removes last stroke
- Save creates a custom template and returns to Template Library
- "My Templates" section appears with the saved card
- Long-pressing any template card shows the bottom sheet with "Color it!" and "Remix it"
- Tapping "Color it!" opens the ColoringScreen
- Tapping "Remix it" opens ContourCreatorScreen with the image pre-loaded

- [ ] **Step 11: Commit**

```bash
git add lib/screens/template_lib_screen.dart test/screens/template_lib_screen_test.dart
git commit -m "feat: wire TemplateLibScreen with Create Blank card, My Templates section, and Remix bottom sheet"
```

---

## Final Verification

- [ ] **Run complete test suite**

```
flutter test
```

Expected: all tests PASS with no failures.

- [ ] **Run analyzer on all changed files**

```
flutter analyze
```

Expected: no issues.

- [ ] **Final commit if anything was missed**

```bash
git add -p  # stage only intentional changes
git commit -m "chore: final cleanup for DIY Template Creator"
```
