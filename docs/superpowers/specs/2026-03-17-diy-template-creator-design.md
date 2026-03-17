# DIY Template Creator — Design Spec
**Date:** 2026-03-17
**Status:** Approved

---

## Overview

A new "DIY Template Creator" phase that lets users draw their own line-art templates with a transparent background. Saved templates appear in the Template Library and are immediately usable as coloring pages. Existing templates can be remixed as a starting point.

---

## 1. Data Model & Persistence

### New `DrawingType`
Add `customTemplate` to the `DrawingType` enum in `lib/persistence/drawing_entry.dart`:

```dart
enum DrawingType { template, upload, rawImport, customTemplate }
```

### Entry structure
A `customTemplate` entry uses `overlayFilePath` (like `upload`/`rawImport`) pointing to a transparent PNG saved as `overlay.png`. It has no `strokes.json` — it is immutable and never re-opened for editing. ID prefix: `custom_<YYYYMMDD_HHmmss>`.

### New repository methods (`drawing_repository.dart`)
- `createCustomTemplateEntry(Uint8List transparentPng)` — generates timestamped ID, creates folder, writes `overlay.png`, returns `DrawingEntry(type: customTemplate, overlayFilePath: ...)`.
- `listCustomTemplateEntries()` — scans for `custom_` folders, returns list sorted newest-first.
- `deleteEntry` — extend the allowed types to include `customTemplate` (currently only permits non-template types).

### `DrawingEntry` constraint
No structural change needed. `customTemplate` uses `overlayFilePath`, satisfying the existing assert.

---

## 2. ContourCreatorScreen

**File:** `lib/screens/contour_creator_screen.dart`

### Entry points
| Source | How opened |
|---|---|
| "Create Blank Canvas" card | `ContourCreatorScreen()` — no arguments |
| Long-press any card → "Remix it" (built-in) | `ContourCreatorScreen(remixAssetPath: entry.overlayAssetPath)` |
| Long-press any card → "Remix it" (file-based) | `ContourCreatorScreen(remixSourcePath: entry.overlayFilePath)` |

### Constructor
```dart
class ContourCreatorScreen extends StatefulWidget {
  final String? remixSourcePath;   // local file path to PNG/image
  final String? remixAssetPath;    // Flutter asset path (SVG or PNG)
}
```

### Controller (`ContourCreatorController`)
A dedicated `ChangeNotifier` (not reusing `CanvasController`) with:
- `List<Stroke> _pencilStrokes`
- `List<Stroke> _eraserStrokes`
- `List<({bool isPencil})> _history` — unified undo stack tracking which list to pop
- `ContourTool activeTool` — `pencil` or `eraser`
- `ui.Image? backgroundImage` — decoded base image for Remix mode
- `void startStroke(Offset)`, `addPoint(Offset)`, `endStroke()`
- `void undo()` — pops from the correct list using `_history`
- `void clear()` — clears both stroke lists and history; keeps `backgroundImage`

A local `enum ContourTool { pencil, eraser }` in the same file. No changes to `BrushType`.

### `ContourCreatorPainter` (CustomPainter)
```
paint(canvas, size):
  canvas.saveLayer(Offset.zero & size, Paint())   // isolated RGBA buffer
  if backgroundImage != null:
    canvas.drawImageRect(backgroundImage, src, dst, Paint())
  for each pencil stroke:
    BrushEngine.paint(canvas, stroke)              // black, BlendMode.srcOver
  for each eraser stroke:
    paint with strokeWidth=20, BlendMode.clear     // punches transparent holes
  canvas.restore()
```

Pencil strokes use the existing `BrushType.pencil` renderer with `color = Colors.black`. Eraser strokes are rendered inline in the painter (not via `BrushEngine`) using `BlendMode.clear`.

### Screen layout
- **AppBar**: back arrow (shows discard-warning dialog if there are unsaved strokes), "✏️ Template Creator" title, green "💾 Save" `TextButton`.
- **Body**: `RepaintBoundary(key: _repaintKey)` containing `CustomPaint(painter: ContourCreatorPainter(...))` wrapped in a `GestureDetector` for pan events.
- **Floating left sidebar**: `Positioned` widget containing a `Column` of 4 icon buttons — Pencil, Eraser (separator), Undo, Clear — active tool highlighted with deepPurple background.

### Save flow
1. `RepaintBoundary → toImage(pixelRatio: 2.0) → toByteData(format: ImageByteFormat.png)` — preserves alpha channel.
2. `DrawingRepository.createCustomTemplateEntry(bytes)`.
3. Pop screen. `TemplateLibScreen._loadData()` called on return (existing pattern via `await Navigator.push` + reload).

### Discard warning
If `_controller` has any strokes and the user taps back, show an `AlertDialog` ("Discard this template?") with Cancel / Discard actions.

### Remix init
In `initState`: if `remixSourcePath` is provided, decode with `decodeImageFromList(File(path).readAsBytesSync())`. If `remixAssetPath` is provided, load via `rootBundle` then decode. Store result in `_controller.backgroundImage` and `setState`.

---

## 3. Template Library Changes

### `TemplateLibScreen` state additions
```dart
List<_CardData> _customCards = [];
```
`_loadData()` runs three futures in parallel:
1. Built-in animal templates (existing)
2. Raw import entries (existing)
3. `DrawingRepository.listCustomTemplateEntries()` → `_customCards`

### Layout
The existing single `ListView` horizontal carousel becomes a `Column` of two sections:

**Section 1 — main carousel:**
- First item: `_CreateBlankCard` widget (dashed purple border, pencil emoji, "Create Blank Canvas" label)
- Followed by all built-in + rawImport cards (existing)

**Section 2 — "✨ My Templates" row:**
- Only rendered when `_customCards.isNotEmpty`
- Section header: `Text('✨ My Templates')`
- Same horizontal `ListView` pattern as main carousel
- Cards are deletable (math-gate dialog); not tappable for editing

### Long-press → Remix bottom sheet
`DrawingCardWidget` gains a nullable `onLongPress` callback. `TemplateLibScreen` supplies `_showRemixSheet(card)` for all cards.

```dart
void _showRemixSheet(_CardData card) {
  showModalBottomSheet(context, builder: (_) => _RemixBottomSheet(
    onColor: () => _openEntry(card.entry),
    onRemix: () => _openRemix(card.entry),
  ));
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

### Tap behaviour
Unchanged — `onTap` directly calls `_openEntry(card.entry)` → `ColoringScreen`.

### Delete
`customTemplate` entries pass `onDelete` (same math-gate flow as rawImport). The `DrawingEntry.type == DrawingType.template` guard in `deleteEntry` is extended to also block `customTemplate` deletion — wait, no: `customTemplate` **is** deletable. The guard only blocks the built-in `template` type.

---

## 4. `DrawingCardWidget` changes

Add `final VoidCallback? onLongPress` parameter. Wire to `GestureDetector.onLongPress` (or `InkWell.onLongPress`).

---

## 5. ColourScreen — no changes

Raw import and upload entries already have `overlayFilePath`. Custom template entries also use `overlayFilePath` and render fine as `lineArtFilePath` in `CanvasStackWidget` (transparent PNG overlay on white background). No changes needed.

---

## 6. Error handling & edge cases

- **Empty save**: if `_repaintKey` capture returns null, show a `SnackBar("Could not save, try again")` and stay on screen.
- **Remix decode failure**: if image decode throws, show a `SnackBar` and open a blank canvas instead.
- **Back with no strokes**: no warning dialog needed — nothing to discard.

---

## 7. Files changed / created

| File | Change |
|---|---|
| `lib/persistence/drawing_entry.dart` | Add `customTemplate` to enum |
| `lib/persistence/drawing_repository.dart` | Add `createCustomTemplateEntry`, `listCustomTemplateEntries`; update `deleteEntry` guard |
| `lib/screens/contour_creator_screen.dart` | **New file** — full screen + controller + painter |
| `lib/screens/template_lib_screen.dart` | Add `_customCards`, "Create Blank" card, long-press sheet, "My Templates" section |
| `lib/widgets/drawing_card_widget.dart` | Add `onLongPress` callback |

No new packages required. No changes to `BrushType`, `BrushEngine`, `CanvasController`, `CanvasStackWidget`, or `ColoringScreen`.
