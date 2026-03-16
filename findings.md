# Findings & Decisions

## Requirements
<!-- Captured from user request + clarification Q&A -->
- Flutter app for iOS (iPad), targeting children ages 3–8
- CustomPainter canvas with two layers in a Stack
- Exactly 5 brush types, hardcoded behavior, **no thickness sliders**:
  - Pencil: thin, slight opacity jitter
  - Marker: bold, semi-transparent, builds up
  - Airbrush: soft radial gradient dots
  - Pattern: repeating star icon stamped along stroke path (every 24px)
  - Splatter: random dots scattered around touch point
- On-device photo-to-line-art conversion (transparent background, B&W)
- Stack rendering: color layer (bottom) → line art PNG (top) — lines always visible
- Fixed color grid: 24 crayola-style swatches (no color picker)
- Save: in-app (documents directory) + iOS photo library

## Research Findings
- `image` package (Dart): pure Dart image processing — grayscale, gaussianBlur, copyResize, pixel iteration. Sobel must be implemented manually via pixel manipulation (no built-in `sobel()` function confirmed for v4.x)
- `image_gallery_saver`: iOS/Android only. Must be guarded with `Platform.isIOS || Platform.isAndroid` to avoid crashes on Windows dev machine
- `file_picker`: cross-platform, works on Windows Desktop for dev testing
- `RepaintBoundary` + `boundary.toImage()` is the standard Flutter approach for canvas capture

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| Sobel via manual pixel iteration | `image` package v4.x has no built-in sobel(); pixel-level is pure Dart, testable |
| CanvasController as ChangeNotifier | No Provider needed at canvas level; AnimatedBuilder listens directly |
| BrushEngine: pure static dispatch | No state needed per brush; switch on BrushType enum |
| star shape via Path math | No asset files needed; drawn programmatically |
| Stroke as immutable value + copyWithPoint | Avoids mutation bugs; safe to pass to CustomPainter |
| SaveManager Platform guard | `image_gallery_saver` throws on Windows; guard prevents dev-time crashes |
| stub_gallery_saver.dart | Conditional import for web/Windows during dev |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| — | — |

## Resources
- Implementation plan: `docs/superpowers/plans/2026-03-14-flutter-coloring-app.md`
- CLAUDE.md constraints: Windows OS, no iOS build commands, use `flutter run -d windows`
- `image` package docs: https://pub.dev/packages/image
- `image_gallery_saver` docs: https://pub.dev/packages/image_gallery_saver
- `file_picker` docs: https://pub.dev/packages/file_picker

## Visual/Browser Findings
- Visual QA is always manual (`flutter run -d windows` or Chrome)
- All brush realism, edge detection quality, and UI aesthetics require human review
- Do not assert visual outcomes in automated tests

---
*Update this file after every 2 view/browser/search operations*
