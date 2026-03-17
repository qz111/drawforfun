# DIY Template Creator — Design Spec
**Date:** 2026-03-17
**Status:** Approved

---

## Overview

A new "DIY Template Creator" phase that lets users draw their own line-art templates with a transparent background. Saved templates appear in the Template Library and are immediately usable as coloring pages. Any existing template (built-in, upload, or custom) can be remixed as a starting point.

---

## 1. Data Model & Persistence

### New `DrawingType` — **required code change, prerequisite for all downstream routing**
Edit `lib/persistence/drawing_entry.dart` to add `customTemplate`:

```dart
enum DrawingType { template, upload, rawImport, customTemplate }
```

This must be done first. All routing in `ColoringScreen`, `TemplateLibScreen`, and `DrawingCardWidget` depends on this value existing at compile time.

### Entry structure
A `customTemplate` entry is constructed with:
- `overlayFilePath = '<dir>/overlay.png'` (non-null — transparent PNG)
- `overlayAssetPath = null`

This satisfies the existing `DrawingEntry` assert (`exactly one of overlayAssetPath / overlayFilePath must be non-null`).

ID format: `custom_<YYYYMMDD_HHmmss_NNN>` where `NNN` is a zero-padded 3-digit random integer (0–999) generated via `Random().nextInt(1000)`. Collision detection: before calling `_entryDir(id)`, check `Directory('${base.path}/$id').existsSync()`. If it already exists, generate a new `NNN` and retry up to 3 times. Throw a `StateError` after 3 failed attempts.

**"Immutable" defined:** The overlay PNG (`overlay.png`) cannot be re-edited in `ContourCreatorScreen`. Color strokes are persisted normally by `ColoringScreen._autoSave` (writes `strokes.json` and `thumbnail.png`) — identical behavior to `upload`/`rawImport` entries.

### New repository methods (`drawing_repository.dart`)
- `createCustomTemplateEntry(Uint8List transparentPng) → Future<DrawingEntry>` — generates ID, creates folder, writes `overlay.png`, returns `DrawingEntry(id: id, type: DrawingType.customTemplate, overlayFilePath: overlayPath, directoryPath: dir.path)`.
- `listCustomTemplateEntries() → Future<List<DrawingEntry>>` — scans for folders whose basename starts with `custom_`, constructs entries with `overlayFilePath`, sorted newest-first (same pattern as `listUploadEntries` / `listRawImportEntries`).

### `deleteEntry` update
The existing guard `if (entry.type == DrawingType.template) throw StateError(...)` is unchanged. `upload`, `rawImport`, and now `customTemplate` entries are all deletable — no change needed for the first two; `customTemplate` falls through the existing guard naturally.

### Thumbnail
No `thumbnail.png` is written at creation time. In `_loadData()`, `File(entry.thumbnailPath).existsSync()` returns false for a freshly created custom template, so `hasThumbnail: false` is passed to `DrawingCardWidget`, which renders the `overlayFilePath` PNG as the card preview (transparent PNG over white container — black line art is visible). This is the existing fallback behaviour for any entry without a thumbnail. After the user colors and navigates back, `_autoSave` writes `thumbnail.png` and subsequent visits show the colored preview.

---

## 2. `ContourTool` enum & `ContourCreatorController`

### Enum (same file as ContourCreatorScreen)
```dart
enum ContourTool { pencil, eraser }
```

### `ContourCreatorController` (ChangeNotifier)
```dart
class ContourCreatorController extends ChangeNotifier {
  final List<Stroke> _pencilStrokes = [];
  final List<Stroke> _eraserStrokes = [];
  // Unified undo history: records which list each committed stroke belongs to.
  final List<({bool isPencil})> _history = [];

  ContourTool activeTool = ContourTool.pencil;
  ui.Image? backgroundImage;
  Stroke? _currentStroke;

  List<Stroke> get pencilStrokes => List.unmodifiable(_pencilStrokes);
  List<Stroke> get eraserStrokes => List.unmodifiable(_eraserStrokes);
  Stroke? get currentStroke => _currentStroke;
  bool get hasUnsavedChanges => _history.isNotEmpty;

  void startStroke(Offset point) {
    // Color is irrelevant for pencil (always black); stored as Colors.black.
    // BrushType.pencil is reused as the Stroke.type field (no new type needed).
    _currentStroke = Stroke(type: BrushType.pencil, color: Colors.black, points: [point]);
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWithPoint(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    if (activeTool == ContourTool.pencil) {
      _pencilStrokes.add(_currentStroke!);
      _history.add((isPencil: true));
    } else {
      _eraserStrokes.add(_currentStroke!);
      _history.add((isPencil: false));
    }
    _currentStroke = null;
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return; // no-op when nothing to undo
    final last = _history.removeLast();
    if (last.isPencil) _pencilStrokes.removeLast();
    else _eraserStrokes.removeLast();
    notifyListeners();
  }

  void clear() {
    _pencilStrokes.clear();
    _eraserStrokes.clear();
    _history.clear();
    _currentStroke = null;
    notifyListeners();
  }
}
```

---

## 3. `ContourCreatorPainter` (CustomPainter)

`ContourCreatorPainter` renders **all strokes inline** — it does NOT call `BrushEngine.paint()`. `BrushEngine._paintPencil` uses a hardcoded `strokeWidth: 3.0` which is too thin for template line art. The contour pencil is rendered independently at `strokeWidth: 6.0`.

```dart
class ContourCreatorPainter extends CustomPainter {
  final List<Stroke> pencilStrokes;
  final List<Stroke> eraserStrokes;
  final Stroke? currentStroke;
  final ContourTool activeTool;
  final ui.Image? backgroundImage;

  void paint(Canvas canvas, Size size) {
    // Isolated RGBA layer — required for BlendMode.clear to punch transparency.
    canvas.saveLayer(Offset.zero & size, Paint());

    // Optional remix base image.
    if (backgroundImage != null) {
      final src = Rect.fromLTWH(0, 0,
          backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble());
      canvas.drawImageRect(backgroundImage!, src, Offset.zero & size, Paint());
    }

    final pencilPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver;

    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in pencilStrokes) _paintStroke(canvas, s, pencilPaint);
    for (final s in eraserStrokes) _paintStroke(canvas, s, eraserPaint);

    // Active (in-progress) stroke uses the paint matching the current tool.
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!,
          activeTool == ContourTool.pencil ? pencilPaint : eraserPaint);
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Stroke s, Paint paint) {
    if (s.points.length < 2) {
      canvas.drawCircle(s.points.first, paint.strokeWidth / 2, paint);
      return;
    }
    final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
    for (int i = 1; i < s.points.length; i++) {
      path.lineTo(s.points[i].dx, s.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  bool shouldRepaint(ContourCreatorPainter old) =>
      old.pencilStrokes != pencilStrokes ||
      old.eraserStrokes != eraserStrokes ||
      old.currentStroke != currentStroke ||
      old.activeTool != activeTool ||
      old.backgroundImage != backgroundImage;
}
```

The canvas background behind the `saveLayer` is transparent. A decorative checkerboard `CustomPaint` (below the `RepaintBoundary`) visualises transparency during editing and is not captured in the saved PNG.

---

## 4. `ContourCreatorScreen`

**File:** `lib/screens/contour_creator_screen.dart`

### Constructor
```dart
class ContourCreatorScreen extends StatefulWidget {
  /// Absolute path to a local PNG/image file. Used for user entries (upload,
  /// rawImport, customTemplate). Null for blank canvas or asset-based remix.
  final String? remixSourcePath;

  /// Flutter asset path to a bundled SVG (built-in templates only).
  /// Mutually exclusive with remixSourcePath in practice.
  /// If both are non-null (should not happen), remixSourcePath takes priority.
  final String? remixAssetPath;
}
```

**Which field to pass per DrawingType:**

| DrawingType | Field to pass |
|---|---|
| `template` (built-in) | `remixAssetPath: entry.overlayAssetPath` |
| `upload` | `remixSourcePath: entry.overlayFilePath` |
| `rawImport` | `remixSourcePath: entry.overlayFilePath` |
| `customTemplate` | `remixSourcePath: entry.overlayFilePath` |
| Blank canvas | both null |

### Screen layout
- **AppBar**: back arrow (see discard warning below), "✏️ Template Creator" title, green "💾 Save" `TextButton` (disabled and replaced with a `SizedBox(width:20, height:20, child: CircularProgressIndicator(...))` while `_isSaving` is true).
- **Body stack** (bottom to top):
  1. Checkerboard `CustomPaint` (decorative, `IgnorePointer`) — fills canvas area
  2. `GestureDetector` (pan events → `_controller`) wrapping `RepaintBoundary(key: _repaintKey)` → `AnimatedBuilder` → `CustomPaint(painter: ContourCreatorPainter(...))`
  3. `Positioned` floating left sidebar (centered vertically): white card with rounded corners, shadow, containing a `Column` of — Pencil icon button, Eraser icon button, `Divider`, Undo icon button, Clear icon button. Active tool (pencil/eraser) has a deepPurple circular background. Undo/Clear buttons are visible always; if `_history.isEmpty` they are visually dimmed (`opacity: 0.4`).

### Remix init
```dart
Future<void> _loadRemixImage() async {
  ui.Image? img;
  try {
    if (widget.remixSourcePath != null) {
      final bytes = await File(widget.remixSourcePath!).readAsBytes();
      img = await decodeImageFromList(bytes);
    } else if (widget.remixAssetPath != null) {
      // SVG assets: rasterise using flutter_svg PictureInfo API.
      // flutter_svg (already a project dependency) exposes:
      //   final loader = SvgAssetLoader(widget.remixAssetPath!);
      //   final pictureInfo = await vg.loadPicture(loader, null);
      //   img = await pictureInfo.picture.toImage(canvasWidth, canvasHeight);
      //   pictureInfo.picture.dispose();
      // canvasWidth / canvasHeight are obtained from the render box size
      // (captured in _canvasSize after first layout via LayoutBuilder or
      // a post-frame callback reading the RepaintBoundary RenderObject size).
      final loader = SvgAssetLoader(widget.remixAssetPath!);
      final sz = _canvasSize; // set in build via LayoutBuilder
      final pictureInfo = await vg.loadPicture(loader, null);
      img = await pictureInfo.picture.toImage(sz.width.round(), sz.height.round());
      pictureInfo.picture.dispose();
    }
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not load image — starting with blank canvas'),
      ));
    }
  }
  if (img != null && mounted) setState(() => _controller.backgroundImage = img);
}
```

`_canvasSize` is captured via a `LayoutBuilder` wrapping the canvas area; `_loadRemixImage()` is called in a post-frame callback after `initState` once layout is complete.

### Save flow
```dart
Future<void> _save() async {
  setState(() => _isSaving = true);
  try {
    final bytes = await SaveManager.captureCanvas(_repaintKey);
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save, try again')));
      return;
    }
    await DrawingRepository.createCustomTemplateEntry(bytes);
    if (mounted) Navigator.of(context).pop();
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
```

### Discard warning
Via `PopScope` / `onPopInvokedWithResult`:
- If `!_controller.hasUnsavedChanges`: pop immediately, no dialog.
- If `_controller.hasUnsavedChanges`: show `AlertDialog('Discard this template?')` with Cancel / Discard (red). Pop only if user confirms.

---

## 5. Template Library Changes

### `TemplateLibScreen` state additions
```dart
List<_CardData> _customCards = [];
```

`_loadData()` runs three parallel futures:
1. Built-in animal templates (existing)
2. Raw import entries (existing)
3. `DrawingRepository.listCustomTemplateEntries()` → `_customCards`

### Layout
The body `Column` becomes:

**Section 1 — main carousel:**
```
[ _CreateBlankCard ] [ built-in 1 ] [ built-in 2 ] ... [ rawImport 1 ] ...
```
`_CreateBlankCard` is a static widget prepended to the mapped list of `_cards` — it is not part of the async future results. Tapping it pushes `ContourCreatorScreen()` (both remix fields null) then calls `_loadData()` on return. `_CreateBlankCard` does **not** have a long-press handler (the "all card types" long-press rule applies only to `DrawingCardWidget` instances, not to `_CreateBlankCard`).

**Section 2 — "My Templates" row:**
- Header: `Text('My Templates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))` — no emoji (project style).
- Only rendered when `_customCards.isNotEmpty`.
- Same horizontal `ListView` / `ScrollConfiguration` pattern as main carousel.
- Cards use `onTap: () => _openEntry(card.entry)` and `onLongPress: () => _showRemixSheet(card)` and `onDelete: () => _confirmDelete(card)`.

### Long-press → bottom sheet
`DrawingCardWidget` gains a nullable `final VoidCallback? onLongPress` parameter, wired to `GestureDetector.onLongPress` (500ms default — acceptable for age 3–8). All `DrawingCardWidget` instances in the Template Library (both sections) receive `onLongPress: () => _showRemixSheet(card)`.

```dart
void _showRemixSheet(_CardData card) {
  showModalBottomSheet(context: context, shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _SheetOption(
              label: 'Color it!', icon: Icons.brush, color: Colors.green,
              onTap: () { Navigator.pop(context); _openEntry(card.entry); },
            )),
            const SizedBox(width: 12),
            Expanded(child: _SheetOption(
              label: 'Remix it', icon: Icons.edit, color: Colors.deepPurple,
              onTap: () { Navigator.pop(context); _openRemix(card.entry); },
            )),
          ]),
        ]),
      ),
    ),
  );
}

Future<void> _openRemix(DrawingEntry entry) async {
  await Navigator.push(context, MaterialPageRoute(
    builder: (_) => ContourCreatorScreen(
      remixSourcePath: entry.overlayFilePath,
      remixAssetPath: entry.overlayAssetPath,
    ),
  ));
  _loadData();
}
```

### Delete
`customTemplate` and `rawImport` entries both receive `onDelete: () => _confirmDelete(card)` (same math-gate `DeleteConfirmationDialog`). Built-in `template` cards receive `onDelete: null` (unchanged).

---

## 6. `ColoringScreen` — no changes

`customTemplate` entries use `overlayFilePath` (transparent PNG). `ColoringScreen` passes this as `lineArtFilePath` to `CanvasStackWidget` (the transparent PNG is rendered as the top overlay over the white `DrawingPainter` background). `backgroundFilePath` is NOT used for `customTemplate` — only for `rawImport`. `_autoSave` writes `strokes.json` and `thumbnail.png` normally.

No guard or special-casing needed for `customTemplate` in `ColoringScreen`.

---

## 7. Error handling & edge cases

| Scenario | Behaviour |
|---|---|
| `captureCanvas` returns null | SnackBar("Could not save, try again"), `_isSaving = false`, stay on screen |
| Remix image decode fails | SnackBar("Could not load image — starting with blank canvas"), `backgroundImage` stays null |
| Back with no history | Pop immediately, no dialog |
| Back with history | Discard warning dialog |
| Same-second ID collision | Retry up to 3 times with new random suffix; throw after 3 failures |
| Save with zero strokes + no background | Saves empty transparent PNG — valid blank template |
| `undo()` called with empty history | No-op |

---

## 8. Files changed / created

| File | Change |
|---|---|
| `lib/persistence/drawing_entry.dart` | Add `customTemplate` to `DrawingType` enum |
| `lib/persistence/drawing_repository.dart` | Add `createCustomTemplateEntry`, `listCustomTemplateEntries`; no change to `deleteEntry` guard |
| `lib/screens/contour_creator_screen.dart` | **New file** — `ContourTool`, `ContourCreatorController`, `ContourCreatorPainter`, `ContourCreatorScreen` |
| `lib/screens/template_lib_screen.dart` | Add `_customCards`, `_CreateBlankCard`, long-press sheet, "My Templates" section |
| `lib/widgets/drawing_card_widget.dart` | Add nullable `onLongPress` callback |

No new packages required (`flutter_svg` and `vector_graphics` are already project dependencies). No changes to `BrushType`, `BrushEngine`, `CanvasController`, `CanvasStackWidget`, or `ColoringScreen`.
