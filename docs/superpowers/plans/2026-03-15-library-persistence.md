# Library & Persistence Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Home Screen with two persistent libraries (Built-in Templates + My Uploads), auto-save drawing state (JSON strokes + PNG thumbnail) on exit, live thumbnails on library cards, and a Clear Canvas that keeps the line art overlay.

**Architecture:** A `DrawingRepository` (file-based, `path_provider`) stores each drawing in `<app_docs>/drawforfun/drawings/<id>/` with `strokes.json` and `thumbnail.png`. `ColoringScreen` receives a `DrawingEntry`, loads saved strokes on open, and auto-saves on back via `PopScope`. `HomeScreen` shows all 25 template cards and uploaded photo cards with live thumbnails pre-computed at load time.

**Tech Stack:** Flutter (Dart), `path_provider` (already installed), `dart:io` for file I/O, `flutter_svg` (already installed), `file_picker` (already installed).

---

## Chunk 1: Persistence Foundation

### Task 1: Stroke serialization — `toJson` / `fromJson`

**Files:**
- Modify: `lib/brushes/stroke.dart`
- Create: `test/brushes/stroke_serialization_test.dart`

**Context:** `Stroke` has three fields: `BrushType type` (note: field name is `type`, not `brushType`), `Color color`, `List<Offset> points`. The JSON key for type is `'brushType'` but the Dart field accessor is `type`.

- [ ] **Step 1: Write failing test**

Create `test/brushes/stroke_serialization_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('Stroke serialization', () {
    test('toJson/fromJson roundtrip — marker', () {
      const stroke = Stroke(
        type: BrushType.marker,
        color: Color(0xFFFF0000),
        points: [Offset(1.0, 2.0), Offset(3.5, 4.5)],
      );
      final json = stroke.toJson();
      final restored = Stroke.fromJson(json);
      expect(restored.type, stroke.type);
      expect(restored.color, stroke.color);
      expect(restored.points.length, 2);
      expect(restored.points[0].dx, 1.0);
      expect(restored.points[0].dy, 2.0);
      expect(restored.points[1].dx, 3.5);
      expect(restored.points[1].dy, 4.5);
    });

    test('roundtrips all 5 brush types', () {
      for (final brushType in BrushType.values) {
        final stroke = Stroke(
          type: brushType,
          color: const Color(0xFF0000FF),
          points: const [Offset(0, 0)],
        );
        final restored = Stroke.fromJson(stroke.toJson());
        expect(restored.type, brushType);
      }
    });

    test('roundtrip with empty points list', () {
      const stroke = Stroke(
        type: BrushType.pencil,
        color: Color(0xFF123456),
        points: [],
      );
      final restored = Stroke.fromJson(stroke.toJson());
      expect(restored.points, isEmpty);
    });

    test('toJson uses brushType key', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Color(0xFF000000),
        points: [],
      );
      final json = stroke.toJson();
      expect(json.containsKey('brushType'), isTrue);
      expect(json['brushType'], 'airbrush');
      expect(json.containsKey('color'), isTrue);
      expect(json.containsKey('points'), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/brushes/stroke_serialization_test.dart
```
Expected: FAIL — `toJson` not defined.

- [ ] **Step 3: Add `toJson` and `fromJson` to `lib/brushes/stroke.dart`**

Add after `copyWithPoint`:

```dart
  /// Serializes this stroke to a JSON-compatible map.
  /// JSON key 'brushType' maps to the Dart field [type].
  Map<String, dynamic> toJson() => {
        'brushType': type.name,
        'color': color.value,
        'points': points
            .map((p) => {'dx': p.dx, 'dy': p.dy})
            .toList(),
      };

  /// Restores a [Stroke] from the map produced by [toJson].
  /// Returns null-safe: unknown brushType names throw [ArgumentError] via [byName].
  static Stroke fromJson(Map<String, dynamic> json) => Stroke(
        type: BrushType.values.byName(json['brushType'] as String),
        color: Color(json['color'] as int),
        points: (json['points'] as List)
            .map((p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ))
            .toList(),
      );
```

- [ ] **Step 4: Run test to confirm it passes**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/brushes/stroke_serialization_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 5: Run full suite to confirm no regressions**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/brushes/stroke.dart test/brushes/stroke_serialization_test.dart
git commit -m "feat: add Stroke toJson/fromJson serialization"
```

---

### Task 2: CanvasController serialization — `strokesToJson` / `loadStrokes`

**Files:**
- Modify: `lib/canvas/canvas_controller.dart`
- Create: `test/canvas/canvas_controller_serialization_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/canvas/canvas_controller_serialization_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';

void main() {
  group('CanvasController serialization', () {
    test('strokesToJson returns empty list when no strokes', () {
      final controller = CanvasController();
      expect(controller.strokesToJson(), isEmpty);
      controller.dispose();
    });

    test('strokesToJson serializes all committed strokes', () {
      final controller = CanvasController();
      controller.startStroke(BrushType.marker, const Color(0xFFFF0000), const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      final json = controller.strokesToJson();
      expect(json.length, 1);
      expect(json[0]['brushType'], 'marker');
      controller.dispose();
    });

    test('loadStrokes replaces existing strokes and notifies', () {
      final controller = CanvasController();
      // Add a stroke first
      controller.startStroke(BrushType.pencil, const Color(0xFF000000), const Offset(0, 0));
      controller.endStroke();
      expect(controller.strokes.length, 1);

      // Load different strokes
      final newStrokes = [
        const Stroke(type: BrushType.airbrush, color: Color(0xFF00FF00), points: [Offset(5, 5)]),
        const Stroke(type: BrushType.marker, color: Color(0xFF0000FF), points: [Offset(1, 2)]),
      ];
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.loadStrokes(newStrokes);

      expect(controller.strokes.length, 2);
      expect(controller.strokes[0].type, BrushType.airbrush);
      expect(controller.strokes[1].type, BrushType.marker);
      expect(notifyCount, greaterThan(0));
      controller.dispose();
    });

    test('strokesToJson / loadStrokes roundtrip preserves all data', () {
      final original = CanvasController();
      original.startStroke(BrushType.splatter, const Color(0xFFABCDEF), const Offset(1.5, 2.5));
      original.addPoint(const Offset(3.0, 4.0));
      original.endStroke();

      final json = original.strokesToJson();
      final restored = CanvasController();
      restored.loadStrokes(json.map(Stroke.fromJson).toList());

      expect(restored.strokes.length, 1);
      expect(restored.strokes[0].type, BrushType.splatter);
      expect(restored.strokes[0].color, const Color(0xFFABCDEF));
      expect(restored.strokes[0].points[0], const Offset(1.5, 2.5));
      expect(restored.strokes[0].points[1], const Offset(3.0, 4.0));

      original.dispose();
      restored.dispose();
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/canvas/canvas_controller_serialization_test.dart
```
Expected: FAIL — `strokesToJson` / `loadStrokes` not defined.

- [ ] **Step 3: Add `strokesToJson` and `loadStrokes` to `lib/canvas/canvas_controller.dart`**

Add after the `setActiveColor` method:

```dart
  /// Returns all committed strokes serialized as a JSON-compatible list.
  List<Map<String, dynamic>> strokesToJson() =>
      _strokes.map((s) => s.toJson()).toList();

  /// Replaces the stroke history with [strokes] and notifies listeners.
  /// Clears any in-progress stroke.
  void loadStrokes(List<Stroke> strokes) {
    _strokes
      ..clear()
      ..addAll(strokes);
    _currentStroke = null;
    notifyListeners();
  }
```

- [ ] **Step 4: Run test to confirm it passes**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/canvas/canvas_controller_serialization_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 5: Run full suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/canvas/canvas_controller.dart test/canvas/canvas_controller_serialization_test.dart
git commit -m "feat: add CanvasController strokesToJson and loadStrokes"
```

---

### Task 3: DrawingEntry data class

**Files:**
- Create: `lib/persistence/drawing_entry.dart`
- Create: `test/persistence/drawing_entry_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/persistence/drawing_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_entry.dart';

void main() {
  group('DrawingEntry', () {
    test('computed paths are correct', () {
      const entry = DrawingEntry(
        id: 'cat',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/cat.svg',
        directoryPath: '/docs/drawforfun/drawings/cat',
      );
      expect(entry.strokesPath, '/docs/drawforfun/drawings/cat/strokes.json');
      expect(entry.thumbnailPath, '/docs/drawforfun/drawings/cat/thumbnail.png');
      expect(entry.overlayPngPath, '/docs/drawforfun/drawings/cat/overlay.png');
    });

    test('template entry has overlayAssetPath, no overlayFilePath', () {
      const entry = DrawingEntry(
        id: 'dog',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/dog.svg',
        directoryPath: '/docs/drawforfun/drawings/dog',
      );
      expect(entry.overlayAssetPath, isNotNull);
      expect(entry.overlayFilePath, isNull);
      expect(entry.type, DrawingType.template);
    });

    test('upload entry has overlayFilePath, no overlayAssetPath', () {
      const entry = DrawingEntry(
        id: 'upload_20260315_120000',
        type: DrawingType.upload,
        overlayFilePath: '/docs/drawforfun/drawings/upload_20260315_120000/overlay.png',
        directoryPath: '/docs/drawforfun/drawings/upload_20260315_120000',
      );
      expect(entry.overlayFilePath, isNotNull);
      expect(entry.overlayAssetPath, isNull);
      expect(entry.type, DrawingType.upload);
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/persistence/drawing_entry_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Create `lib/persistence/drawing_entry.dart`**

```dart
/// Identifies whether a drawing is a built-in animal template or a user upload.
enum DrawingType { template, upload }

/// Represents one saved drawing session.
///
/// Template entries have [overlayAssetPath] (SVG asset).
/// Upload entries have [overlayFilePath] (local PNG file).
/// Exactly one of the two is non-null.
class DrawingEntry {
  /// Folder name: animal ID (e.g. 'cat') or timestamp (e.g. 'upload_20260315_120000').
  final String id;

  final DrawingType type;

  /// SVG asset path — templates only. e.g. 'assets/line_art/cat.svg'.
  final String? overlayAssetPath;

  /// Absolute path to the converted line art PNG — uploads only.
  final String? overlayFilePath;

  /// Absolute path to this entry's storage folder.
  final String directoryPath;

  const DrawingEntry({
    required this.id,
    required this.type,
    this.overlayAssetPath,
    this.overlayFilePath,
    required this.directoryPath,
  });

  /// Path to the serialized stroke history JSON file.
  String get strokesPath => '$directoryPath/strokes.json';

  /// Path to the latest colored PNG thumbnail.
  String get thumbnailPath => '$directoryPath/thumbnail.png';

  /// Path to the overlay PNG file (uploads only).
  String get overlayPngPath => '$directoryPath/overlay.png';
}
```

- [ ] **Step 4: Run test to confirm it passes**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/persistence/drawing_entry_test.dart
```
Expected: All 3 tests pass.

- [ ] **Step 5: Run full suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/persistence/drawing_entry.dart test/persistence/drawing_entry_test.dart
git commit -m "feat: DrawingEntry data class with template/upload types"
```

---

### Task 4: DrawingRepository — file-based persistence

**Files:**
- Create: `lib/persistence/drawing_repository.dart`
- Create: `test/persistence/drawing_repository_test.dart`

**Context:** Uses `dart:io` + `path_provider`. For testability, a static `_testOverrideDir` lets tests inject a temp directory, bypassing `getApplicationDocumentsDirectory`. A private `_basename` helper avoids the external `path` package.

- [ ] **Step 1: Write failing tests**

Create `test/persistence/drawing_repository_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';
import 'package:drawforfun/persistence/drawing_entry.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/templates/animal_template.dart';

// NOTE: When _testOverrideDir is set, _drawingsDir() returns it directly
// (no 'drawings/' subfolder). Test entries use tempDir.path as the root.

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('drawforfun_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('DrawingRepository.loadStrokes', () {
    test('returns empty list when strokes.json is absent', () async {
      final entry = DrawingEntry(
        id: 'cat',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/cat.svg',
        directoryPath: '${tempDir.path}/cat',
      );
      final result = await DrawingRepository.loadStrokes(entry);
      expect(result, isEmpty);
    });

    test('returns empty list when strokes.json contains invalid JSON', () async {
      final dir = Directory('${tempDir.path}/corrupt')..createSync();
      File('${dir.path}/strokes.json').writeAsStringSync('not valid json!!!');
      final entry = DrawingEntry(
        id: 'corrupt',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/cat.svg',
        directoryPath: dir.path,
      );
      final result = await DrawingRepository.loadStrokes(entry);
      expect(result, isEmpty);
    });
  });

  group('DrawingRepository.saveStrokes / loadStrokes roundtrip', () {
    test('saves and reloads a list of strokes', () async {
      const stroke = Stroke(
        type: BrushType.marker,
        color: Color(0xFFFF0000),
        points: [Offset(1.0, 2.0), Offset(3.0, 4.0)],
      );
      final entry = DrawingEntry(
        id: 'cat',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/cat.svg',
        directoryPath: '${tempDir.path}/cat',
      );
      await DrawingRepository.saveStrokes(entry, [stroke.toJson()]);
      final loaded = await DrawingRepository.loadStrokes(entry);
      expect(loaded.length, 1);
      final restored = Stroke.fromJson(loaded[0]);
      expect(restored.type, BrushType.marker);
      expect(restored.color, const Color(0xFFFF0000));
      expect(restored.points[0], const Offset(1.0, 2.0));
    });

    test('overwrites previous save', () async {
      final entry = DrawingEntry(
        id: 'dog',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/dog.svg',
        directoryPath: '${tempDir.path}/dog',
      );
      const s1 = Stroke(type: BrushType.pencil, color: Color(0xFF111111), points: []);
      const s2 = Stroke(type: BrushType.airbrush, color: Color(0xFF222222), points: []);
      await DrawingRepository.saveStrokes(entry, [s1.toJson(), s2.toJson()]);
      await DrawingRepository.saveStrokes(entry, [s1.toJson()]);
      final loaded = await DrawingRepository.loadStrokes(entry);
      expect(loaded.length, 1);
    });
  });

  group('DrawingRepository.saveThumbnail', () {
    test('writes bytes to thumbnailPath', () async {
      final entry = DrawingEntry(
        id: 'fox',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/fox.svg',
        directoryPath: '${tempDir.path}/fox',
      );
      final fakeBytes = [1, 2, 3, 4, 5];
      await DrawingRepository.saveThumbnail(entry, Uint8List.fromList(fakeBytes));
      final file = File(entry.thumbnailPath);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), fakeBytes);
    });
  });

  group('DrawingRepository.createUploadEntry', () {
    test('creates folder, writes overlay.png, returns correct entry', () async {
      final fakeOverlay = Uint8List.fromList([10, 20, 30]);
      final entry = await DrawingRepository.createUploadEntry(fakeOverlay);
      expect(entry.type, DrawingType.upload);
      expect(entry.id.startsWith('upload_'), isTrue);
      expect(entry.overlayFilePath, isNotNull);
      final overlayFile = File(entry.overlayFilePath!);
      expect(overlayFile.existsSync(), isTrue);
      expect(overlayFile.readAsBytesSync(), fakeOverlay);
    });
  });

  group('DrawingRepository.listUploadEntries', () {
    test('returns empty list when no uploads exist', () async {
      final result = await DrawingRepository.listUploadEntries();
      expect(result, isEmpty);
    });

    test('lists upload_ folders, ignores template folders', () async {
      // Create a fake upload folder
      final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
        ..createSync(recursive: true);
      File('${uploadDir.path}/overlay.png').writeAsBytesSync([1, 2, 3]);
      // Create a template folder (should be ignored)
      Directory('${tempDir.path}/cat').createSync(recursive: true);

      final result = await DrawingRepository.listUploadEntries();
      expect(result.length, 1);
      expect(result[0].id, 'upload_20260315_120000');
      expect(result[0].type, DrawingType.upload);
    });
  });

  group('DrawingRepository.templateEntry', () {
    test('returns DrawingEntry with correct fields', () async {
      const template = AnimalTemplate(
        id: 'cat',
        name: 'Cat',
        emoji: '🐱',
        assetPath: 'assets/line_art/cat.svg',
      );
      final entry = await DrawingRepository.templateEntry(template);
      expect(entry.id, 'cat');
      expect(entry.type, DrawingType.template);
      expect(entry.overlayAssetPath, 'assets/line_art/cat.svg');
      expect(entry.overlayFilePath, isNull);
      expect(entry.directoryPath, endsWith('cat'));
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/persistence/drawing_repository_test.dart
```
Expected: FAIL — file not found.

- [ ] **Step 3: Create `lib/persistence/drawing_repository.dart`**

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import '../templates/animal_template.dart';
import 'drawing_entry.dart';

/// File-based persistence for drawing sessions.
///
/// All data lives under `<app_documents>/drawforfun/drawings/<id>/`.
/// Each entry folder contains:
///   strokes.json   — serialized stroke history
///   thumbnail.png  — latest colored snapshot
///   overlay.png    — converted line art PNG (uploads only)
///
/// For testing, call [setTestDirectory] with a temp dir before any operations,
/// and pass null to restore the real path_provider behaviour.
class DrawingRepository {
  DrawingRepository._();

  static Directory? _testOverrideDir;

  /// Injects a temp directory for unit tests, bypassing path_provider.
  @visibleForTesting
  static void setTestDirectory(Directory? dir) => _testOverrideDir = dir;

  // ── Internal path helpers ──────────────────────────────────────────

  static Future<Directory> _drawingsDir() async {
    // In tests, return the injected directory as-is (no 'drawings/' subfolder).
    if (_testOverrideDir != null) return _testOverrideDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final drawings = Directory('${appDir.path}/drawforfun/drawings');
    if (!drawings.existsSync()) drawings.createSync(recursive: true);
    return drawings;
  }

  static Future<Directory> _entryDir(String id) async {
    final base = await _drawingsDir();
    final dir = Directory('${base.path}/$id');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Extracts the last path segment from a platform-native path.
  static String _basename(String p) {
    final clean = p.replaceAll('\\', '/');
    final parts = clean.split('/');
    return parts.lastWhere((s) => s.isNotEmpty, orElse: () => '');
  }

  // ── Public API ────────────────────────────────────────────────────

  /// Builds a [DrawingEntry] for a built-in [AnimalTemplate].
  /// Does not create the directory — it is created lazily on first save.
  static Future<DrawingEntry> templateEntry(AnimalTemplate template) async {
    final base = await _drawingsDir();
    return DrawingEntry(
      id: template.id,
      type: DrawingType.template,
      overlayAssetPath: template.assetPath,
      directoryPath: '${base.path}/${template.id}',
    );
  }

  /// Returns all upload entries, sorted newest-first.
  static Future<List<DrawingEntry>> listUploadEntries() async {
    final base = await _drawingsDir();
    if (!base.existsSync()) return [];
    final entries = base
        .listSync()
        .whereType<Directory>()
        .where((d) => _basename(d.path).startsWith('upload_'))
        .map((d) {
      final id = _basename(d.path);
      return DrawingEntry(
        id: id,
        type: DrawingType.upload,
        overlayFilePath: '${d.path}/overlay.png',
        directoryPath: d.path,
      );
    }).toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // newest first (lexicographic = chronological)
    return entries;
  }

  /// Saves the stroke JSON list to `<entry>/strokes.json`.
  /// Creates the entry directory if it does not exist.
  static Future<void> saveStrokes(
    DrawingEntry entry,
    List<Map<String, dynamic>> json,
  ) async {
    await _entryDir(entry.id);
    await File(entry.strokesPath).writeAsString(jsonEncode(json));
  }

  /// Loads stroke JSON from `<entry>/strokes.json`.
  /// Returns an empty list if the file is absent or contains invalid JSON.
  static Future<List<Map<String, dynamic>>> loadStrokes(
      DrawingEntry entry) async {
    final file = File(entry.strokesPath);
    if (!file.existsSync()) return [];
    try {
      final raw = await file.readAsString();
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // Corrupt file — treat as empty (log in debug builds only)
      assert(() {
        // ignore: avoid_print
        print('DrawingRepository: corrupt strokes.json for ${entry.id}');
        return true;
      }());
      return [];
    }
  }

  /// Writes [bytes] to `<entry>/thumbnail.png`.
  /// Creates the entry directory if it does not exist.
  static Future<void> saveThumbnail(
      DrawingEntry entry, Uint8List bytes) async {
    await _entryDir(entry.id);
    await File(entry.thumbnailPath).writeAsBytes(bytes);
  }

  /// Creates a new upload entry:
  /// 1. Generates a timestamp-based ID.
  /// 2. Creates the entry directory.
  /// 3. Writes [overlayPng] to `overlay.png`.
  /// 4. Returns the [DrawingEntry].
  static Future<DrawingEntry> createUploadEntry(Uint8List overlayPng) async {
    final now = DateTime.now();
    final id =
        'upload_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final dir = await _entryDir(id);
    final overlayPath = '${dir.path}/overlay.png';
    await File(overlayPath).writeAsBytes(overlayPng);
    return DrawingEntry(
      id: id,
      type: DrawingType.upload,
      overlayFilePath: overlayPath,
      directoryPath: dir.path,
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
```

- [ ] **Step 4: Run test to confirm it passes**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/persistence/drawing_repository_test.dart
```
Expected: All 9 tests pass.

- [ ] **Step 5: Run full suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/persistence/drawing_repository.dart test/persistence/drawing_repository_test.dart
git commit -m "feat: DrawingRepository — file-based stroke/thumbnail persistence"
```

---

## Chunk 2: UI Components

### Task 5: CanvasStackWidget — add `lineArtFilePath` parameter

**Files:**
- Modify: `lib/canvas/canvas_stack_widget.dart`

**Context:** Add a third overlay type: `String? lineArtFilePath` (absolute path to a local PNG file — for uploaded photos). Priority order remains: SVG asset → file PNG → memory bytes. Update the mutual-exclusivity assert to cover all three fields.

- [ ] **Step 1: Read `lib/canvas/canvas_stack_widget.dart` in full**

Verify the current assert (checks `lineArtBytes == null || lineArtAssetPath == null`) and the two-branch `if/else if` overlay block.

- [ ] **Step 2: Update `lib/canvas/canvas_stack_widget.dart`**

Add the new parameter and import `dart:io`. Replace the entire file:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (bottom) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
/// All overlay types are wrapped in [IgnorePointer] so touch always
/// reaches the drawing layer regardless of which overlay is active.
///
/// Overlay priority (supply at most one):
///   1. [lineArtAssetPath] — SVG asset (built-in templates)
///   2. [lineArtFilePath]  — local PNG file path (uploaded photos)
///   3. [lineArtBytes]     — in-memory PNG bytes (legacy, kept for compatibility)
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// SVG asset path for a built-in template, e.g. 'assets/line_art/cat.svg'.
  final String? lineArtAssetPath;

  /// Absolute path to a local PNG file for an uploaded photo overlay.
  final String? lineArtFilePath;

  /// In-memory PNG bytes. Kept for backward compatibility; prefer [lineArtFilePath].
  final Uint8List? lineArtBytes;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtAssetPath,
    this.lineArtFilePath,
    this.lineArtBytes,
  }) : assert(
          // At most one overlay field may be non-null.
          (lineArtAssetPath == null ? 0 : 1) +
                  (lineArtFilePath == null ? 0 : 1) +
                  (lineArtBytes == null ? 0 : 1) <=
              1,
          'Supply at most one overlay: lineArtAssetPath, lineArtFilePath, or lineArtBytes.',
        );

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
          if (lineArtAssetPath != null)
            IgnorePointer(
              child: SvgPicture.asset(
                lineArtAssetPath!,
                fit: BoxFit.fill,
                placeholderBuilder: (_) => const SizedBox.expand(),
              ),
            )
          else if (lineArtFilePath != null)
            IgnorePointer(
              child: Image.file(
                File(lineArtFilePath!),
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            )
          else if (lineArtBytes != null)
            IgnorePointer(
              child: Image.memory(
                lineArtBytes!,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

```
/c/Users/klose/flutter/bin/flutter.bat analyze
```
Expected: No issues (ignore file_picker platform warnings in stdout).

- [ ] **Step 4: Run full test suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/canvas/canvas_stack_widget.dart
git commit -m "feat: CanvasStackWidget gains lineArtFilePath for file-based PNG overlays"
```

---

### Task 6: DrawingCardWidget

**Files:**
- Create: `lib/widgets/drawing_card_widget.dart`

**Context:** Displays one library card. Thumbnail image is determined by a pre-computed `hasThumbnail` bool passed by the caller (HomeScreen checks `File.existsSync()` once at load time, not on each build). Card shows either the colored thumbnail, the blank SVG/PNG overlay, or an emoji placeholder.

- [ ] **Step 1: Create `lib/widgets/drawing_card_widget.dart`**

No TDD here — the widget has no logic to unit-test (pure presentation). Visual QA is in Task 10.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../persistence/drawing_entry.dart';

/// A tappable card showing a drawing's thumbnail (or placeholder if not started).
///
/// [hasThumbnail] must be pre-computed by the caller (e.g. `File(entry.thumbnailPath).existsSync()`)
/// to avoid synchronous file I/O inside `build()`.
class DrawingCardWidget extends StatelessWidget {
  final DrawingEntry entry;

  /// Display name shown below the thumbnail.
  final String label;

  /// Emoji shown as fallback placeholder — templates only.
  final String? emoji;

  /// Whether a saved thumbnail PNG exists for this entry.
  final bool hasThumbnail;

  final VoidCallback onTap;

  const DrawingCardWidget({
    super.key,
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: _buildThumbnail(),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasThumbnail ? '● colored' : 'not started',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasThumbnail
                          ? Colors.deepPurple.shade300
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // 1. Colored thumbnail (highest priority)
    if (hasThumbnail) {
      return Image.file(
        File(entry.thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // 2. Template — show blank SVG line art at reduced opacity
    if (entry.type == DrawingType.template &&
        entry.overlayAssetPath != null) {
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
    // 3. Upload — show the raw line art PNG preview.
    // overlayFilePath is always non-null for upload entries and the file is
    // guaranteed to exist (written by createUploadEntry). Use errorBuilder
    // as a safety fallback instead of a synchronous existsSync() check.
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
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Text(
          emoji ?? '📷',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```
/c/Users/klose/flutter/bin/flutter.bat analyze
```
Expected: No issues.

- [ ] **Step 3: Run full test suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/drawing_card_widget.dart
git commit -m "feat: DrawingCardWidget — thumbnail or placeholder with colored/not-started label"
```

---

### Task 7: HomeScreen

**Files:**
- Create: `lib/screens/home_screen.dart`
- Create: `test/screens/home_screen_test.dart`

**Context:** `StatefulWidget`. On init, loads all 25 template entries and all upload entries from `DrawingRepository`, pre-computing `hasThumbnail` for each. Photo upload flow: FilePicker → `compute(LineArtEngine.convert)` → `createUploadEntry` → push `ColoringScreen`. On return from `ColoringScreen`, reloads data so thumbnails reflect any auto-save.

**⚠️ Ordering Constraint:** `HomeScreen` calls `ColoringScreen(entry: entry)`, but the current `ColoringScreen` does not yet accept an `entry` parameter. `flutter test` will fail to compile until Task 8 is complete. **Execute Task 8 before running Steps 4–5 of this task.** Proceed: complete Step 1 (write test), Step 3 (create implementation), and Step 2 (confirm fail — expect compile error, not missing-file error). Then go to Task 8. After Task 8 passes, return here and run Steps 4–6.

- [ ] **Step 1: Write failing test**

Create `test/screens/home_screen_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/home_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('home_screen_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('HomeScreen shows app bar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🎨 Draw For Fun'), findsOneWidget);
  });

  testWidgets('HomeScreen shows Built-in Templates section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🐾 Built-in Templates'), findsOneWidget);
  });

  testWidgets('HomeScreen shows My Uploads section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('📷 My Uploads'), findsOneWidget);
  });

  testWidgets('HomeScreen shows Upload button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Upload'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/screens/home_screen_test.dart
```
Expected: FAIL — `home_screen.dart` not found.

- [ ] **Step 3: Create `lib/screens/home_screen.dart`**

```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../line_art/line_art_engine.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../templates/animal_templates.dart';
import '../widgets/drawing_card_widget.dart';
import 'coloring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isUploading = false;

  List<_CardData> _templateCards = [];
  List<_CardData> _uploadCards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    // Build template cards for all 25 animals
    final templateCards = await Future.wait(
      AnimalTemplates.all.map((template) async {
        final entry = await DrawingRepository.templateEntry(template);
        final hasThumbnail = File(entry.thumbnailPath).existsSync();
        return _CardData(
          entry: entry,
          label: template.name,
          emoji: template.emoji,
          hasThumbnail: hasThumbnail,
        );
      }),
    );

    // Load upload entries
    final uploadEntries = await DrawingRepository.listUploadEntries();
    final uploadCards = uploadEntries.map((entry) {
      final hasThumbnail = File(entry.thumbnailPath).existsSync();
      return _CardData(
        entry: entry,
        label: _uploadLabel(entry.id),
        hasThumbnail: hasThumbnail,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _templateCards = templateCards;
        _uploadCards = uploadCards;
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
    );
    // Reload after returning — auto-save may have updated thumbnails
    _loadData();
  }

  Future<void> _startUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      final overlayPng =
          await compute(LineArtEngine.convert, result.files.single.bytes!);
      if (overlayPng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not convert image — try a different photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final entry = await DrawingRepository.createUploadEntry(overlayPng);
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
        );
        _loadData();
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _uploadLabel(String id) {
    // id: 'upload_YYYYMMDD_HHmmss' → 'Photo MM/DD'
    try {
      final date = id.split('_')[1]; // YYYYMMDD
      return 'Photo ${date.substring(4, 6)}/${date.substring(6, 8)}';
    } catch (_) {
      return 'Photo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          '🎨 Draw For Fun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Built-in Templates ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🐾 Built-in Templates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                      Text(
                        '${_templateCards.length} animals',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple.shade300),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _templateCards.length,
                    itemBuilder: (_, i) {
                      final card = _templateCards[i];
                      return DrawingCardWidget(
                        entry: card.entry,
                        label: card.label,
                        emoji: card.emoji,
                        hasThumbnail: card.hasThumbnail,
                        onTap: () => _openEntry(card.entry),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── My Uploads ─────────────────────────────────────
                  const Text(
                    '📷 My Uploads',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _UploadAddButton(
                          isLoading: _isUploading,
                          onTap: _isUploading ? null : _startUpload,
                        ),
                        ..._uploadCards.map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: SizedBox(
                              width: 90,
                              child: DrawingCardWidget(
                                entry: card.entry,
                                label: card.label,
                                hasThumbnail: card.hasThumbnail,
                                onTap: () => _openEntry(card.entry),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

/// Holds pre-computed card display data to avoid repeated file I/O in build.
class _CardData {
  final DrawingEntry entry;
  final String label;
  final String? emoji;
  final bool hasThumbnail;
  _CardData({
    required this.entry,
    required this.label,
    this.emoji,
    required this.hasThumbnail,
  });
}

class _UploadAddButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _UploadAddButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.green.shade300, width: 2),
          borderRadius: BorderRadius.circular(14),
          color: Colors.green.shade50,
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 28, color: Colors.green.shade400),
                  const SizedBox(height: 4),
                  Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub test/screens/home_screen_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 5: Run full suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/home_screen.dart test/screens/home_screen_test.dart
git commit -m "feat: HomeScreen with Built-in Templates grid and My Uploads horizontal row"
```

---

## Chunk 3: Integration & Cleanup

### Task 8: ColoringScreen — full rewrite

**Files:**
- Modify: `lib/screens/coloring_screen.dart`

**Context:** Receives a `DrawingEntry`. Loads saved strokes asynchronously on init. Uses `PopScope` (Flutter 3.12+) for auto-save on back. Removes the Load Photo and Templates toolbar buttons (both moved to HomeScreen). Clear Canvas now clears strokes only — the overlay stays. Passes `lineArtAssetPath` and `lineArtFilePath` to `CanvasStackWidget`.

**Important:** `_showClearDialog` previously cleared `_lineArtBytes` and `_activeTemplatePath` — the new version does NOT clear the overlay (clears strokes only).

**Note on removed method:** The old `ColoringScreen._saveToGallery` also called `SaveManager.saveToAppDocuments(bytes)`. This call is intentionally removed — `DrawingRepository.saveThumbnail` (called by `_autoSave`) is now the primary persistence mechanism. Only gallery export remains.

**⚠️ After completing this task:** Return to Task 7 and run its deferred Steps 4–6 (tests + commit), then proceed to Task 9.

- [ ] **Step 1: Read `lib/screens/coloring_screen.dart` in full**

Confirm the current file before replacing it.

- [ ] **Step 2: Replace `lib/screens/coloring_screen.dart` with the new implementation**

```dart
import 'package:flutter/material.dart';
import '../brushes/stroke.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/canvas_stack_widget.dart';
import '../palette/palette_widget.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../save/save_manager.dart';
import '../widgets/brush_selector_widget.dart';

class ColoringScreen extends StatefulWidget {
  final DrawingEntry entry;

  const ColoringScreen({super.key, required this.entry});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _controller = CanvasController();
  final _repaintKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedStrokes();
  }

  /// Loads previously saved strokes from disk in the background.
  /// Does nothing if no strokes.json exists for this entry.
  Future<void> _loadSavedStrokes() async {
    final strokesJson = await DrawingRepository.loadStrokes(widget.entry);
    if (strokesJson.isNotEmpty && mounted) {
      _controller.loadStrokes(strokesJson.map(Stroke.fromJson).toList());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Persists current strokes (JSON) and captures a thumbnail PNG.
  /// Called automatically when the user navigates back.
  Future<void> _autoSave() async {
    await DrawingRepository.saveStrokes(
        widget.entry, _controller.strokesToJson());
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes != null) {
      await DrawingRepository.saveThumbnail(widget.entry, bytes);
    }
  }

  /// Saves the current canvas as a PNG to the device photo gallery.
  /// On Windows this is a silent no-op.
  Future<void> _saveToGallery() async {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null || !mounted) return;
    await SaveManager.saveToGallery(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to gallery!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        setState(() => _isSaving = true);
        await _autoSave();
        if (mounted) {
          setState(() => _isSaving = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text(
            'Draw For Fun',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _controller.undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : () => _showClearDialog(context),
              tooltip: 'Clear',
            ),
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _isSaving ? null : _saveToGallery,
              tooltip: 'Save to gallery',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // ── Canvas ──────────────────────────────────────────
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
                          lineArtFilePath: widget.entry.overlayFilePath,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom Panel ─────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
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

            // Auto-save overlay — dims screen and shows spinner while saving
            if (_isSaving)
              const ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text(
            'This will erase your strokes. The line art stays.'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.clear(); // strokes only — overlay intentionally kept
              Navigator.pop(ctx);
            },
            child:
                const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run `flutter analyze`**

```
/c/Users/klose/flutter/bin/flutter.bat analyze
```
Expected: No issues. (If there are unused import warnings, remove those imports.)

- [ ] **Step 4: Run full test suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```

Expected: Most tests pass. `test/widget_test.dart` may fail because it tests `ColoringScreen` directly without a `DrawingEntry`. This is expected and will be fixed in Task 9.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/coloring_screen.dart
git commit -m "feat: ColoringScreen receives DrawingEntry, PopScope auto-save, clear-strokes-only"
```

---

### Task 9: Wire up app.dart, retire TemplateScreen, fix widget test

**Files:**
- Modify: `lib/app.dart`
- Delete: `lib/screens/template_screen.dart`
- Delete: `test/screens/template_screen_test.dart`
- Modify: `test/widget_test.dart`

**Context:** Change the app's home route to `HomeScreen`. Delete `TemplateScreen` (replaced by the HomeScreen Templates grid). Update `test/widget_test.dart` to test the new home screen instead.

- [ ] **Step 1: Update `lib/app.dart`**

Replace the file:

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class DrawForFunApp extends StatelessWidget {
  const DrawForFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Draw For Fun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

- [ ] **Step 2: Delete `lib/screens/template_screen.dart`**

Both files are tracked by git. Use `git rm` to delete from disk and stage the deletion in one step:

```bash
git rm lib/screens/template_screen.dart
```

- [ ] **Step 3: Delete `test/screens/template_screen_test.dart`**

```bash
git rm test/screens/template_screen_test.dart
```

- [ ] **Step 4: Update `test/widget_test.dart`**

Read the current `test/widget_test.dart`, then replace it with a test that verifies the new home screen launches correctly:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/app.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('widget_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('App launches and shows HomeScreen', (tester) async {
    await tester.pumpWidget(const DrawForFunApp());
    await tester.pumpAndSettle();
    expect(find.text('🎨 Draw For Fun'), findsOneWidget);
    expect(find.text('🐾 Built-in Templates'), findsOneWidget);
    expect(find.text('📷 My Uploads'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run `flutter analyze`**

```
/c/Users/klose/flutter/bin/flutter.bat analyze
```
Expected: No issues.

- [ ] **Step 6: Run full test suite**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass (template_screen tests are gone, widget_test updated).

- [ ] **Step 7: Commit**

The `git rm` deletions from Steps 2–3 are already staged. Just add the modified files and commit:

```bash
git add lib/app.dart test/widget_test.dart
git commit -m "feat: wire HomeScreen as app root, retire TemplateScreen"
```

---

### Task 10: Final verification

- [ ] **Step 1: Run full test suite with verbose output**

```
/c/Users/klose/flutter/bin/flutter.bat test --no-pub
```
Expected: All tests pass, 0 failures.

- [ ] **Step 2: Run Flutter analyze**

```
/c/Users/klose/flutter/bin/flutter.bat analyze
```
Expected: No issues (file_picker platform warnings in stdout are noise, not analyzer issues).

- [ ] **Step 3: Visual QA — run on Windows Desktop**

```
/c/Users/klose/flutter/bin/flutter.bat run -d windows
```

Verify:
- [ ] App opens to Home Screen (not drawing screen directly)
- [ ] "🐾 Built-in Templates" section shows 25 animal cards in a 3-column grid
- [ ] Uncolored cards show the SVG line art (dim) + "not started" label
- [ ] "📷 My Uploads" section shows the "+" Upload button
- [ ] Tapping a template card opens the coloring screen with that animal's line art
- [ ] Coloring screen has 3 toolbar buttons: Undo, Clear, Save to gallery
- [ ] Drawing works — strokes appear on top of the line art
- [ ] Clear button dialog says "The line art stays" and only clears strokes (overlay remains)
- [ ] Tapping the back button saves and returns to Home Screen
- [ ] The tapped template card now shows the colored thumbnail + "● colored" label
- [ ] Re-opening the same template restores the drawn strokes exactly
- [ ] Upload button in My Uploads opens photo picker → converts → opens coloring screen
- [ ] Coloring an upload and going back shows colored thumbnail in My Uploads row
- [ ] Save to gallery button shows snackbar (no crash on Windows)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: library & persistence feature complete — visual QA passed"
```
