# Design Spec: Raw Image Import to Templates + Universal Delete

**Date:** 2026-03-15
**Status:** Approved

---

## Overview

Two new features for the DrawForFun children's coloring app:

1. **Raw Image Import to Templates** — A `+` button in the Templates section lets users pick any photo and save it directly to local storage without edge detection. The Templates grid then displays both built-in animal templates and these raw imports together.

2. **Universal Delete** — A trash icon on deletable cards (uploads and raw imports) triggers a parental-gate math confirmation dialog before permanently removing the image, thumbnail, and saved drawing state.

---

## 1. Data Model & Persistence

### DrawingType enum

Add a third value:

```dart
enum DrawingType { template, upload, rawImport }
```

- `template` — built-in SVG asset, never deletable
- `upload` — user-uploaded image processed through `LineArtEngine` (existing)
- `rawImport` — user-imported image saved raw, no processing

### DrawingEntry

No structural changes. A `rawImport` entry uses `overlayFilePath` (pointing to the raw bytes saved as `overlay.png`) and leaves `overlayAssetPath` null — identical to an `upload` entry. This satisfies the existing constructor assert which enforces exactly one of the two fields is non-null. The directory ID prefix is `rawimport_<timestamp>` (e.g. `rawimport_20260315_143000`).

> **ID collision note:** IDs have second-level precision. If two imports happen within the same second, the second call reuses the existing directory and overwrites `overlay.png`. This is the same accepted risk as in the existing `createUploadEntry` — rare enough in practice for a children's app to be ignored.

### DrawingRepository — new methods

**`createRawImportEntry(Uint8List bytes)`**
- Generates ID: `rawimport_YYYYMMDD_HHmmss`
- Creates directory under `<app_documents>/drawforfun/drawings/<id>/`
- Writes raw bytes to `overlay.png`
- Returns `DrawingEntry` with `type: DrawingType.rawImport`, `overlayFilePath` set, `overlayAssetPath` null

**`listRawImportEntries()`**
- Scans directories starting with `rawimport_`
- Returns list sorted newest-first (same pattern as `listUploadEntries`)

**`deleteEntry(DrawingEntry entry)`**
- Guard: throws `StateError` if `entry.type == DrawingType.template`
- Deletes the entire directory using `await Directory(entry.directoryPath).delete(recursive: true)` (async, consistent with the rest of the repository)
- Removes `overlay.png`, `thumbnail.png`, and `strokes.json` in one operation

---

## 2. Templates Tab Refactor

### Header

The Templates section header row gains a purple `+` button (icon: `Icons.add_circle_outline`, color: `deepPurple`) on the right side, mirroring the green Upload button in My Uploads. While a raw import is being saved, the button is replaced by a small `CircularProgressIndicator`.

The existing animal count label (`${_templateCards.length} animals`) is removed from the header — once raw imports are mixed in, the label would misleadingly count photos as animals.

### Grid content

`_loadData()` fetches two data sources in parallel:
1. Built-in animal templates (existing — `AnimalTemplates.all`)
2. Raw import entries (new — `DrawingRepository.listRawImportEntries()`)

The grid renders built-ins first, raw imports appended after. No interleaving or sorting between the two groups.

Raw import cards:
- Label: `Photo MM/DD` (same format as upload labels)
- Placeholder emoji: `📷`
- Thumbnail: shows colored thumbnail if exists, otherwise shows the raw `overlay.png` as preview (same as current upload card behavior)

### Navigation on import

After saving a raw import, the app does **not** navigate to `ColoringScreen`. It simply reloads the grid. (This differs from the current upload flow which immediately opens `ColoringScreen`.)

---

## 3. Universal Delete UI

### DrawingCardWidget changes

New optional parameter:
```dart
final VoidCallback? onDelete;
```

When `onDelete` is non-null, a trash icon badge is rendered in the top-right corner of the card:
- Icon: `Icons.delete_outline`, size 18px
- Wrapped in a small rounded white pill container (semi-transparent background)
- Positioned using a `Stack` over the existing card content
- Tapping it calls `onDelete()`

When `onDelete` is null (template entries), no icon is shown — no visual difference for built-ins.

### HomeScreen wiring

Inside the `itemBuilder` lambdas for both the Templates grid and the My Uploads list, `DrawingCardWidget` receives `onDelete` only for `upload` and `rawImport` entries:

```dart
onDelete: entry.type == DrawingType.template
    ? null
    : () => _confirmDelete(card),
```

`_confirmDelete(card)` opens `DeleteConfirmationDialog` via `showDialog`. The dialog receives an `onConfirmed` callback. When the callback fires, `HomeScreen` calls `setState` to remove the card from the appropriate list (`_templateCards` or `_uploadCards`).

### DeleteConfirmationDialog

A reusable `StatefulWidget` defined at the bottom of `home_screen.dart`:

```dart
class DeleteConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirmed;
  // ...
}
```

Interface:
- Constructor takes `onConfirmed` callback — called after `deleteEntry` succeeds
- Returned via `showDialog<void>(...)`; `HomeScreen` acts on `onConfirmed`, not the dialog's return value

Behaviour:
- **Title:** "Delete this image?"
- **Body:** Randomly generated addition problem displayed as large text: "What is **A + B**?"
  - `A` and `B` are random integers in range 5–15 (sum range: 10–30)
  - Generated once in `initState` using `dart:math` `Random`
- **Input:** `TextField` with `keyboardType: TextInputType.number`, autofocused
- **Buttons:** "Cancel" (calls `Navigator.pop`) / "Delete" (validates answer)
- **On correct answer:** calls `await DrawingRepository.deleteEntry(entry)`, then `onConfirmed()`, then `Navigator.pop`
- **On wrong answer:** shows inline error text "Wrong answer, try again" — dialog stays open, input clears

### Math difficulty

Numbers 5–15 per operand ensures sums are in range 10–30. This is reliably unsolvable by a 3-year-old and trivially easy for any adult or older child.

---

## 4. Coloring Screen — rawImport display

When a `rawImport` entry is opened in `ColoringScreen`, the raw image (`overlayFilePath`) is displayed directly as the background using `Image.file()` — the same code path already used for `upload` entries. No changes needed to `ColoringScreen`.

---

## 5. Files Affected

| File | Change |
|------|--------|
| `lib/persistence/drawing_entry.dart` | Add `DrawingType.rawImport` |
| `lib/persistence/drawing_repository.dart` | Add `createRawImportEntry`, `listRawImportEntries`, `deleteEntry` |
| `lib/widgets/drawing_card_widget.dart` | Add optional `onDelete` param + trash icon badge |
| `lib/screens/home_screen.dart` | Templates `+` button, merge raw imports into grid, wire `onDelete` in both section `itemBuilder`s, add `DeleteConfirmationDialog` |

No changes needed to: `coloring_screen.dart`, `line_art_engine.dart`, `animal_templates.dart`, `canvas_*`.

---

## 6. Out of Scope

- Editing the label of a raw import
- Reordering cards
- Deleting built-in templates
- Any processing/filtering of raw imported images
