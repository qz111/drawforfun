# Library & Persistence — Design Spec

**Date:** 2026-03-15
**Project:** DrawForFun — Flutter children's coloring app (ages 3–8)
**Status:** Approved

---

## Overview

Replace the current single-screen architecture with a Home Screen that shows two persistent libraries: Built-in Templates and My Uploads. Drawing state (strokes) is serialized to JSON and auto-saved when the user leaves the canvas, so they can resume exactly where they left off. Live colored thumbnails are captured at the same time and displayed on the library cards.

---

## Goals

1. **Clear Canvas** — clear strokes only, keep the line art overlay, so children can re-color the same template without losing it
2. **Two libraries on Home Screen** — Built-in Templates (3-column grid, all 25 animals) and My Uploads (horizontal scroll row with a "+" add button)
3. **Resume drawing** — strokes serialized to JSON on exit, loaded on re-entry; the child continues exactly where they left off
4. **Live thumbnails** — PNG snapshot captured on exit; library cards display the latest colored state

---

## Storage Layout

All persistent data lives under the app documents directory:

```
<app_documents>/drawforfun/drawings/
  cat/
    strokes.json          ← stroke history (JSON array)
    thumbnail.png         ← latest colored snapshot (PNG)
  dog/
    strokes.json
    thumbnail.png
  upload_20260315_143022/
    overlay.png           ← converted line art PNG (moved here from temp)
    strokes.json
    thumbnail.png
```

- **Template entries** use the animal ID as folder name (`cat`, `dog`, etc.)
- **Upload entries** use a timestamp ID: `upload_YYYYMMDD_HHmmss`
- A folder is only created when the user first opens that drawing
- `strokes.json` and `thumbnail.png` are only written on first auto-save (exit)
- Unstarted template cards show the SVG emoji placeholder; unstarted upload cards show the line art PNG as a static image

---

## Data Model

### `lib/persistence/drawing_entry.dart`

```dart
enum DrawingType { template, upload }

class DrawingEntry {
  final String id;                 // 'cat' | 'upload_20260315_143022'
  final DrawingType type;
  final String? overlayAssetPath;  // 'assets/line_art/cat.svg' — templates only
  final String? overlayFilePath;   // absolute path to overlay.png — uploads only
  final String directoryPath;      // absolute path to this entry's folder

  const DrawingEntry({
    required this.id,
    required this.type,
    this.overlayAssetPath,
    this.overlayFilePath,
    required this.directoryPath,
  });

  String get strokesPath   => '$directoryPath/strokes.json';
  String get thumbnailPath => '$directoryPath/thumbnail.png';
  String get overlayPngPath => '$directoryPath/overlay.png'; // uploads only
}
```

Invariant: exactly one of `overlayAssetPath` or `overlayFilePath` is non-null.

### Stroke Serialization

`lib/brushes/stroke.dart` gains `toJson` / `fromJson`:

```dart
Map<String, dynamic> toJson() => {
  'brushType': brushType.name,
  'color': color.value,
  'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
};

static Stroke fromJson(Map<String, dynamic> json) => Stroke(
  brushType: BrushType.values.byName(json['brushType'] as String),
  color: Color(json['color'] as int),
  points: (json['points'] as List)
      .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
      .toList(),
);
```

`CanvasController` gains:
```dart
List<Map<String, dynamic>> strokesToJson();  // serializes _strokes
void loadStrokes(List<Stroke> strokes);       // replaces _strokes, notifies
```

---

## `lib/persistence/drawing_repository.dart`

Static utility class. All methods are async and operate on the file system via `path_provider` (already a dependency).

```dart
class DrawingRepository {
  // Returns the root drawings directory, creating it if needed
  static Future<Directory> _drawingsDir() async { ... }

  // Returns the directory for a specific entry ID, creating it if needed
  static Future<Directory> entryDir(String id) async { ... }

  // Builds a DrawingEntry for a template (does not create directories)
  static Future<DrawingEntry> templateEntry(AnimalTemplate template) async { ... }

  // Lists all upload entries (scans drawingsDir for upload_* folders)
  static Future<List<DrawingEntry>> listUploadEntries() async { ... }

  // Saves stroke JSON to entry's strokes.json
  static Future<void> saveStrokes(DrawingEntry entry, List<Map<String, dynamic>> json) async { ... }

  // Loads stroke JSON from entry's strokes.json; returns [] if file absent
  static Future<List<Map<String, dynamic>>> loadStrokes(DrawingEntry entry) async { ... }

  // Saves thumbnail PNG bytes to entry's thumbnail.png
  static Future<void> saveThumbnail(DrawingEntry entry, Uint8List bytes) async { ... }

  // Creates a new upload entry: saves overlay PNG, returns the DrawingEntry
  static Future<DrawingEntry> createUploadEntry(Uint8List overlayPng) async { ... }
}
```

---

## New Screens & Widgets

### `lib/screens/home_screen.dart`

`StatefulWidget`. Loads data in `initState` via `DrawingRepository`.

**Layout:**
```
Scaffold
  AppBar: "🎨 Draw For Fun", deep-purple
  Body: SingleChildScrollView
    Column:
      Section header: "🐾 Built-in Templates"  (25 animals count label)
      GridView(crossAxisCount: 3, shrinkWrap, NeverScrollableScrollPhysics)
        DrawingCardWidget × 25
      SizedBox(height: 24)
      Section header: "📷 My Uploads"
      SingleChildScrollView(scrollDirection: horizontal)
        Row:
          _UploadAddButton  ← "+" card, taps to start upload flow
          DrawingCardWidget × N  ← one per upload entry
```

**On tap (template or upload card):**
1. Build the `DrawingEntry` for that card
2. `Navigator.push(ColoringScreen(entry: entry))`
3. On return (pop), call `setState` to reload thumbnails (in case auto-save updated them)

**Upload flow (tap "+" button):**
1. `FilePicker.platform.pickFiles(type: FileType.image, withData: true)`
2. If bytes null → return
3. Show loading indicator
4. `compute(LineArtEngine.convert, bytes)` → `overlayPng`
5. If null → show error snackbar, return
6. `DrawingRepository.createUploadEntry(overlayPng)` → `entry`
7. `Navigator.push(ColoringScreen(entry: entry))`

### `lib/widgets/drawing_card_widget.dart`

`StatelessWidget`. Displays one library card.

```dart
class DrawingCardWidget extends StatelessWidget {
  final DrawingEntry entry;
  final String label;           // animal name or upload timestamp label
  final String? emoji;          // for templates: '🐱'; null for uploads
  final VoidCallback onTap;
  ...
}
```

**Thumbnail logic:**
- If `thumbnail.png` exists → `Image.file(File(entry.thumbnailPath))` (colored snapshot)
- Else if template → show `SvgPicture.asset(entry.overlayAssetPath!)` with dim opacity
- Else (upload, no thumbnail) → `Image.file(File(entry.overlayFilePath!))` (line art preview)

Status label below card:
- thumbnail exists → `"● colored"` in purple/green
- no thumbnail → `"not started"` in grey

---

## Modified Files

### `lib/screens/coloring_screen.dart`

**Constructor gains `DrawingEntry entry` parameter.**

**`initState` additions:**
```dart
// 1. Set overlay from entry
_activeTemplatePath = entry.overlayAssetPath;
_overlayFilePath    = entry.overlayFilePath;   // new field — File-based overlay for uploads

// 2. Load saved strokes
final strokesJson = await DrawingRepository.loadStrokes(entry);
if (strokesJson.isNotEmpty) {
  _controller.loadStrokes(strokesJson.map(Stroke.fromJson).toList());
}
```

**Back button — `WillPopScope` (or `PopScope` in Flutter 3.12+):**
```dart
onWillPop: () async {
  await _autoSave();
  return true;
}
```

**`_autoSave()`:**
```dart
Future<void> _autoSave() async {
  // 1. Serialize strokes
  await DrawingRepository.saveStrokes(entry, _controller.strokesToJson());
  // 2. Capture thumbnail
  final bytes = await SaveManager.captureCanvas(_repaintKey);
  if (bytes != null) {
    await DrawingRepository.saveThumbnail(entry, bytes);
  }
}
```

**Toolbar — buttons removed:**
- ❌ "Load Photo" (`Icons.photo_library`) — removed
- ❌ "Templates" (`Icons.pets`) — removed

**Toolbar — remaining:** Undo · Clear Canvas · Save to Gallery

**Clear Canvas dialog — updated behaviour:**
- Clears `_controller.clear()` only
- Does NOT clear `_activeTemplatePath` or `_overlayFilePath` (overlay stays)
- Dialog title: "Clear drawing?" — same confirmation UX as before

**`CanvasStackWidget` call — upload overlays:**

`CanvasStackWidget` gains a third overlay type: `lineArtFilePath` (a `String?` pointing to a local PNG file for uploads). Rendering priority:
1. `lineArtAssetPath` (template SVG) — highest
2. `lineArtFilePath` (upload PNG file) — middle
3. `lineArtBytes` (in-memory bytes, now unused post-refactor) — lowest

In practice only one is ever set. `lineArtBytes` field is kept for backward compatibility but no longer set from `ColoringScreen`.

### `lib/canvas/canvas_stack_widget.dart`

Add `String? lineArtFilePath` parameter. Rendering order (`if / else if / else if`):
```dart
if (lineArtAssetPath != null)
  IgnorePointer(child: SvgPicture.asset(lineArtAssetPath!, fit: BoxFit.fill, ...))
else if (lineArtFilePath != null)
  IgnorePointer(child: Image.file(File(lineArtFilePath!), fit: BoxFit.fill, gaplessPlayback: true))
else if (lineArtBytes != null)
  IgnorePointer(child: Image.memory(lineArtBytes!, fit: BoxFit.fill, gaplessPlayback: true))
```

Update the mutual-exclusivity assert to cover all three fields.

### `lib/app.dart`

```dart
home: const HomeScreen(),
```

### `lib/screens/template_screen.dart`

**Retired.** File deleted. All imports removed. The home screen's Built-in Templates grid replaces it entirely.

---

## Navigation Flow (complete)

```
App start
  └─ HomeScreen
        ├─ tap template card  → ColoringScreen(entry: templateEntry)
        │       └─ back → _autoSave() → pop → HomeScreen reloads thumbnails
        ├─ tap upload card    → ColoringScreen(entry: uploadEntry)
        │       └─ back → _autoSave() → pop → HomeScreen reloads thumbnails
        └─ tap "+" (uploads)
              → FilePicker → compute(LineArtEngine.convert)
              → DrawingRepository.createUploadEntry(overlayPng)
              → ColoringScreen(entry: newEntry)
                    └─ back → _autoSave() → pop → HomeScreen reloads thumbnails
```

---

## Packages

No new packages required. All dependencies (`path_provider`, `file_picker`, `flutter_svg`, `image`) are already declared.

---

## Testing

| Test file | What it covers |
|-----------|----------------|
| `test/persistence/drawing_entry_test.dart` | computed paths, overlay invariant |
| `test/persistence/drawing_repository_test.dart` | save/load strokes roundtrip, createUploadEntry, listUploadEntries |
| `test/brushes/stroke_serialization_test.dart` | toJson/fromJson roundtrip for all brush types and edge cases (empty points) |
| `test/screens/home_screen_test.dart` | renders both sections; template cards show correct labels; upload "+" card present |

`CanvasStackWidget` file-overlay rendering and thumbnail accuracy require manual `flutter run -d windows` review.

---

## Constraints

- Windows dev environment — `flutter run -d windows` for visual QA
- `File`-based image loading (`Image.file`) works on Windows desktop
- `PopScope` preferred over deprecated `WillPopScope` if Flutter version supports it; fall back to `WillPopScope` if not
- Auto-save is synchronous from the user's perspective (brief await before pop) — acceptable given small JSON payload and fast PNG capture
- `TemplateScreen` deletion will break any existing imports — all call sites must be cleaned up
