# UI Refactor Design — Draw For Fun
**Date:** 2026-03-17
**Status:** Approved

## Overview

Refactor the single `HomeScreen` into a three-screen navigation hierarchy: a new `MainMenuScreen` entry point, and two dedicated library screens (`TemplateLibScreen`, `MyUploadLibScreen`). All drawing, saving, and image-processing logic remains unchanged.

---

## Screen Architecture

### Files changed

| File | Change |
|---|---|
| `lib/screens/main_menu_screen.dart` | **New** — initial screen with two side-by-side cards |
| `lib/screens/template_lib_screen.dart` | **New** — template library screen |
| `lib/screens/my_upload_lib_screen.dart` | **New** — upload library screen |
| `lib/screens/home_screen.dart` | **Deleted** |
| `lib/app.dart` | Updated: `home: HomeScreen()` → `home: MainMenuScreen()` |
| `lib/screens/coloring_screen.dart` | **Unchanged** |
| `lib/widgets/drawing_card_widget.dart` | **Unchanged** |

`_CardData` and `DeleteConfirmationDialog` are moved into their respective lib screen files. Neither is shared between the two screens.

---

## Navigation Flow

```
MainMenuScreen
  ├── tap "Templates"  → Navigator.push → TemplateLibScreen
  │     ├── tap card   → Navigator.push → ColoringScreen(entry)
  │     │     └── back → returns to TemplateLibScreen (stack unwinds)
  │     └── back       → returns to MainMenuScreen
  └── tap "My Uploads" → Navigator.push → MyUploadLibScreen
        ├── tap card   → Navigator.push → ColoringScreen(entry)
        │     └── back → returns to MyUploadLibScreen (stack unwinds)
        └── back       → returns to MainMenuScreen
```

- All navigation uses `Navigator.push` (no named routes, no GoRouter).
- On return from `ColoringScreen`, the lib screen calls `_loadData()` and evicts the stale `FileImage` cache entry.

---

## MainMenuScreen

- Two side-by-side cards, equal width, full-height.
- **Templates card:** white background, purple border (`#7C3AED`), 🐾 emoji, "Templates" title, subtitle "Built-in animals & your raw photos".
- **My Uploads card:** white background, green border (`#059669`), 📷 emoji, "My Uploads" title, subtitle "Edge-detected line art drawings".
- App title centered above cards: "🎨 Draw For Fun".
- No AppBar — the title is inline in the body.

---

## TemplateLibScreen

### AppBar
- Back arrow (returns to `MainMenuScreen`).
- Title: "🐾 Templates".
- Action: `+ Upload` chip button — triggers `_startRawImport()`.

### Body
- Horizontal `ListView.builder` showing 4–5 `DrawingCardWidget` cards visible at once.
- Cards show real `thumbnail.png` when one exists; falls back to SVG line art at reduced opacity for unstarted templates, or raw image preview for raw imports.
- Delete button visible on each card **except** `DrawingType.template` (built-in) cards.

### Data
- Loads `AnimalTemplates.all` (built-in templates) + `DrawingRepository.listRawImportEntries()` (raw imports).
- Each source mapped to `_CardData` with pre-computed `hasThumbnail`.
- Combined into single `_cards` list: built-ins first, raw imports appended.

### Upload (`_startRawImport`)
- Opens file picker (image only).
- Calls `DrawingRepository.createRawImportEntry(bytes)`.
- Reloads strip — does **not** navigate to `ColoringScreen`.

### Delete
- Calls `DeleteConfirmationDialog` (math gate).
- On confirm: evicts `FileImage` cache, calls `DrawingRepository.deleteEntry(entry)`, removes card from list.
- Hidden for `DrawingType.template` entries.

---

## MyUploadLibScreen

### AppBar
- Back arrow (returns to `MainMenuScreen`).
- Title: "📷 My Uploads".
- Action: `+ Upload` chip button — triggers `_startUpload()`.

### Body
- Horizontal `ListView.builder`, same card sizing as `TemplateLibScreen`.
- Cards show real `thumbnail.png` when one exists; falls back to overlay PNG preview.
- Delete button visible on all cards.

### Data
- Loads `DrawingRepository.listUploadEntries()`.
- Mapped to `_CardData` with pre-computed `hasThumbnail`.

### Upload (`_startUpload`)
- Opens file picker (image only).
- Runs `LineArtEngine.convert` via `compute` (edge detection).
- On success: calls `DrawingRepository.createUploadEntry(overlayPng)`, then **pushes `ColoringScreen` immediately**.
- On failure: shows error `SnackBar`.

### Delete
- Calls `DeleteConfirmationDialog` (math gate).
- On confirm: evicts `FileImage` cache entries (overlay + thumbnail), calls `DrawingRepository.deleteEntry(entry)`, removes card from list.
- Visible on all cards.

---

## ColoringScreen

No changes. Receives a `DrawingEntry`, handles all drawing, undo, clear, save-to-gallery, and auto-save on pop. Back navigation unwinds the stack naturally to the lib screen that pushed it.

---

## Carousel Card Sizing

Cards in the horizontal strip should be sized so that 4–5 are visible simultaneously on a standard iPad screen (~1024 pt wide). Target card width: ~180–200 pt. `DrawingCardWidget` aspect ratio maintained at ~0.82 (existing value).

---

## Constraints

- All drawing, saving, and image-processing logic (canvas, strokes, thumbnails, `LineArtEngine`, `SaveManager`, `DrawingRepository`) must remain unchanged.
- No new third-party packages.
- Child-friendly UI: large tap targets, rounded corners, vibrant colors.
- Windows Desktop (`flutter run -d windows`) must remain the local test target.
