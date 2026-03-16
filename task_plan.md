# Task Plan: Flutter Children's Coloring App

## Goal
Build an iOS-targeted Flutter coloring app for ages 3–8 with 5 hardcoded brush types, an on-device photo-to-line-art converter, and a Stack canvas that always renders black lines above the color layer.

## Current Phase
Phase 1 — complete (requirements clarified, plan written)

## Phases

### Phase 1: Requirements & Discovery
- [x] Clarify target platform (iOS, iPad)
- [x] Clarify brush types (pencil, marker, airbrush, pattern, splatter — no sliders)
- [x] Clarify pattern brush (repeating icon/star stamp along stroke)
- [x] Clarify color palette (24 fixed swatches)
- [x] Clarify save behavior (in-app + device photo library)
- [x] Clarify line art engine (on-device, Sobel edge detection)
- [x] Write full implementation plan → `docs/superpowers/plans/2026-03-14-flutter-coloring-app.md`
- **Status:** complete

### Phase 2: Project Setup & Core Models
- [ ] Update pubspec.yaml with dependencies
- [ ] Create lib/main.dart and lib/app.dart
- [ ] Implement ColorPalette (24 swatches)
- [ ] Implement BrushType enum and Stroke model
- [ ] Run flutter pub get + flutter analyze
- **Status:** pending

### Phase 3: Brush Engine & Canvas
- [ ] Implement BrushEngine (all 5 brush types)
- [ ] Implement CanvasController (state, undo, clear)
- [ ] Implement DrawingPainter (CustomPainter)
- [ ] Implement CanvasStackWidget (Stack with line art overlay)
- [ ] Run flutter test for all above
- **Status:** pending

### Phase 4: Line Art Engine
- [ ] Implement LineArtEngine (on-device Sobel edge detection)
- [ ] Unit test with synthetic images
- [ ] Integrate with ColoriingScreen via FilePicker
- **Status:** pending

### Phase 5: Save & UI Assembly
- [ ] Implement SaveManager (in-app + gallery, Windows stub)
- [ ] Add iOS Info.plist permissions
- [ ] Implement BrushSelectorWidget
- [ ] Implement PaletteWidget
- [ ] Implement ColoriingScreen (full assembly)
- **Status:** pending

### Phase 6: Testing & Visual QA
- [ ] Run full flutter test suite
- [ ] Run flutter analyze (0 issues)
- [ ] Visual QA via flutter run -d windows
- [ ] Verify all 5 brushes visually
- [ ] Verify line art overlay stays on top
- [ ] Verify save flow works
- **Status:** pending

## Key Questions
1. ✅ On-device or server-side line art? → On-device (Sobel via `image` package)
2. ✅ Target platform? → iOS (iPad), dev on Windows
3. ✅ Pattern brush type? → Repeating star icon stamped along stroke
4. ✅ Color palette? → 24 fixed swatches, no picker
5. ✅ Save? → In-app (documents dir) + iOS photo library

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Sobel edge detection via `image` package | Pure Dart, cross-platform, no server needed |
| CanvasController extends ChangeNotifier | Simple, no Provider boilerplate for internal canvas state |
| BrushEngine as pure static functions | Testable, stateless, easy to extend |
| Stack: drawing layer (bottom) + line art Image (top) | Simplest way to ensure lines always show above color |
| Windows dev guard in SaveManager | `image_gallery_saver` crashes on Windows; Platform check prevents it |
| `flutter run -d windows` for visual preview | Cannot run iOS simulator on Windows per claude.md |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| — | — | — |

## Notes
- **CRITICAL**: Never run `pod install`, `xcodebuild`, or iOS simulator commands (Windows env)
- Test commands: `flutter test`, `flutter analyze`, `flutter run -d windows`
- Visual QA is always manual — do not assert visual outcomes in code
- Ask before adding packages beyond those listed in Phase 2 pubspec.yaml
- Implementation plan: `docs/superpowers/plans/2026-03-14-flutter-coloring-app.md`
