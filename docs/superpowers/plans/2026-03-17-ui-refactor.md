# UI Refactor — Three-Screen Navigation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single `HomeScreen` with a `MainMenuScreen` → `TemplateLibScreen` / `MyUploadLibScreen` → `ColoringScreen` navigation hierarchy, without changing any drawing, saving, or image-processing logic.

**Architecture:** Approach B — delete `home_screen.dart` entirely, create three clean new screen files. `_CardData` and `DeleteConfirmationDialog` move into their respective lib screen files. `_UploadAddButton` is retired; each lib screen uses an AppBar chip instead. `app.dart` updated to point to `MainMenuScreen`.

**Tech Stack:** Flutter (Dart), `flutter_test` for widget tests, `flutter analyze` for static analysis. Local test target: `flutter run -d windows`.

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/screens/main_menu_screen.dart` | Two side-by-side menu cards, navigates to lib screens |
| Create | `lib/screens/template_lib_screen.dart` | Horizontal carousel of templates + raw imports; raw import upload; delete with math gate |
| Create | `lib/screens/my_upload_lib_screen.dart` | Horizontal carousel of processed uploads; edge-detection upload; delete with math gate |
| Modify | `lib/app.dart` | Change `home:` from `HomeScreen` to `MainMenuScreen` |
| Delete | `lib/screens/home_screen.dart` | Replaced entirely by the three files above |
| Create | `test/screens/main_menu_screen_test.dart` | Widget tests for MainMenuScreen |
| Create | `test/screens/template_lib_screen_test.dart` | Widget tests for TemplateLibScreen |
| Create | `test/screens/my_upload_lib_screen_test.dart` | Widget tests for MyUploadLibScreen |
| Delete | `test/screens/home_screen_test.dart` | Replaced by the three test files above |
| Unchanged | `lib/screens/coloring_screen.dart` | No changes |
| Unchanged | `lib/widgets/drawing_card_widget.dart` | No changes |
| Unchanged | `lib/persistence/drawing_repository.dart` | No changes |

---

## Task 1: Create `MainMenuScreen`

**Files:**
- Create: `lib/screens/main_menu_screen.dart`
- Create: `test/screens/main_menu_screen_test.dart`

- [ ] **Step 1.1: Write the failing tests**

Create `test/screens/main_menu_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/screens/main_menu_screen.dart';

void main() {
  testWidgets('MainMenuScreen shows app title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.text('🎨 Draw For Fun'), findsOneWidget);
  });

  testWidgets('MainMenuScreen shows Templates card', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.text('Templates'), findsOneWidget);
  });

  testWidgets('MainMenuScreen shows My Uploads card', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.text('My Uploads'), findsOneWidget);
  });

  testWidgets('MainMenuScreen has no AppBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.byType(AppBar), findsNothing);
  });
}
```

- [ ] **Step 1.2: Run tests — verify they fail**

```bash
flutter test test/screens/main_menu_screen_test.dart
```

Expected: compilation error — `MainMenuScreen` not found.

- [ ] **Step 1.3: Implement `MainMenuScreen`**

Create `lib/screens/main_menu_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'template_lib_screen.dart';
import 'my_upload_lib_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎨 Draw For Fun',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4C1D95),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _MenuCard(
                      emoji: '🐾',
                      label: 'Templates',
                      subtitle: 'Built-in animals & your raw photos',
                      borderColor: const Color(0xFF7C3AED),
                      labelColor: const Color(0xFF4C1D95),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const TemplateLibScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _MenuCard(
                      emoji: '📷',
                      label: 'My Uploads',
                      subtitle: 'Edge-detected line art drawings',
                      borderColor: const Color(0xFF059669),
                      labelColor: const Color(0xFF065F46),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const MyUploadLibScreen()),
                      ),
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
}

class _MenuCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.borderColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 1.4: Run tests — verify they pass**

```bash
flutter test test/screens/main_menu_screen_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 1.5: Run analyzer**

```bash
flutter analyze lib/screens/main_menu_screen.dart
```

Expected: No issues.

- [ ] **Step 1.6: Commit**

```bash
git add lib/screens/main_menu_screen.dart test/screens/main_menu_screen_test.dart
git commit -m "feat: add MainMenuScreen with two side-by-side menu cards"
```

---

## Task 2: Create `TemplateLibScreen`

**Files:**
- Create: `lib/screens/template_lib_screen.dart`
- Create: `test/screens/template_lib_screen_test.dart`

- [ ] **Step 2.1: Write the failing tests**

Create `test/screens/template_lib_screen_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/template_lib_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('template_lib_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('TemplateLibScreen shows AppBar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🐾 Templates'), findsOneWidget);
  });

  testWidgets('TemplateLibScreen shows Upload button in AppBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('+ Upload'), findsOneWidget);
  });

  testWidgets('TemplateLibScreen shows built-in template cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    // AnimalTemplates.all contains at least one template — check any renders
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('delete icon absent on built-in template cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('rawImport card appears and shows delete icon', (tester) async {
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    File('${rawDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Photo 03/15'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping delete icon opens confirmation dialog', (tester) async {
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    File('${rawDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this image?'), findsOneWidget);
  });
}
```

- [ ] **Step 2.2: Run tests — verify they fail**

```bash
flutter test test/screens/template_lib_screen_test.dart
```

Expected: compilation error — `TemplateLibScreen` not found.

- [ ] **Step 2.3: Implement `TemplateLibScreen`**

Create `lib/screens/template_lib_screen.dart`. This file contains:
- `TemplateLibScreen` widget
- `_CardData` helper class
- `DeleteConfirmationDialog` (copied verbatim from `home_screen.dart` — do not modify it)

Key implementation notes:
- `_loadData()` fetches `AnimalTemplates.all` + `DrawingRepository.listRawImportEntries()` in parallel with `Future.wait`, same as current `HomeScreen`
- `_uploadLabel(id)` helper (same logic as current `HomeScreen`)
- Carousel: `ListView.builder` with `scrollDirection: Axis.horizontal` inside an `Expanded` or `SizedBox` with fixed height
- Card width: `200` logical pixels (gives 4–5 visible on a 1024 pt iPad screen). Use `SizedBox(width: 200, child: DrawingCardWidget(...))` for each card
- `onDelete`: pass `null` for `DrawingType.template` cards; pass `() => _confirmDelete(card)` for all others
- After `_startRawImport()` completes: call `_loadData()`, do **not** push `ColoringScreen`
- On return from `ColoringScreen`: evict `FileImage(File(entry.thumbnailPath))` then call `_loadData()`

```dart
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../templates/animal_templates.dart';
import '../widgets/drawing_card_widget.dart';
import 'coloring_screen.dart';

class TemplateLibScreen extends StatefulWidget {
  const TemplateLibScreen({super.key});

  @override
  State<TemplateLibScreen> createState() => _TemplateLibScreenState();
}

class _TemplateLibScreenState extends State<TemplateLibScreen> {
  bool _isLoading = true;
  bool _isImporting = false;
  List<_CardData> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
    ]);
    if (mounted) {
      setState(() {
        _cards = [...results[0], ...results[1]];
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
    );
    await FileImage(File(entry.thumbnailPath)).evict();
    _loadData();
  }

  Future<void> _startRawImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!mounted) return;
    setState(() => _isImporting = true);
    try {
      await DrawingRepository.createRawImportEntry(result.files.single.bytes!);
      _loadData();
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _confirmDelete(_CardData card) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        entry: card.entry,
        onConfirmed: () {
          setState(() => _cards.remove(card));
        },
      ),
    );
  }

  String _uploadLabel(String id) {
    try {
      final date = id.split('_')[1];
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
          '🐾 Templates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: const Text('+ Upload'),
                onPressed: _startRawImport,
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cards.length,
                      itemBuilder: (_, i) {
                        final card = _cards[i];
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
                              onDelete: card.entry.type == DrawingType.template
                                  ? null
                                  : () => _confirmDelete(card),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

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

// ── DeleteConfirmationDialog ─────────────────────────────────────────────────
// Copied verbatim from home_screen.dart. Handles cache eviction and file
// deletion internally; onConfirmed only updates the caller's UI list.

class DeleteConfirmationDialog extends StatefulWidget {
  final DrawingEntry entry;
  final VoidCallback onConfirmed;

  const DeleteConfirmationDialog({
    super.key,
    required this.entry,
    required this.onConfirmed,
  });

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  late final int _a;
  late final int _b;
  late final int _answer;
  final _controller = TextEditingController();
  String? _errorText;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 5 + rng.nextInt(11);
    _b = 5 + rng.nextInt(11);
    _answer = _a + _b;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    final input = int.tryParse(_controller.text.trim());
    if (input != _answer) {
      setState(() {
        _errorText = 'Wrong answer, try again';
        _controller.clear();
      });
      return;
    }
    setState(() => _isDeleting = true);
    try {
      final overlayFile = widget.entry.overlayFilePath;
      if (overlayFile != null) {
        imageCache.evict(FileImage(File(overlayFile)));
      }
      imageCache.evict(FileImage(File(widget.entry.thumbnailPath)));
      await DrawingRepository.deleteEntry(widget.entry);
      widget.onConfirmed();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete this image?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What is $_a + $_b?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Your answer',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _onDelete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2.4: Run tests — verify they pass**

```bash
flutter test test/screens/template_lib_screen_test.dart
```

Expected: All 6 tests pass.

- [ ] **Step 2.5: Run analyzer**

```bash
flutter analyze lib/screens/template_lib_screen.dart
```

Expected: No issues.

- [ ] **Step 2.6: Commit**

```bash
git add lib/screens/template_lib_screen.dart test/screens/template_lib_screen_test.dart
git commit -m "feat: add TemplateLibScreen with horizontal carousel and raw import upload"
```

---

## Task 3: Create `MyUploadLibScreen`

**Files:**
- Create: `lib/screens/my_upload_lib_screen.dart`
- Create: `test/screens/my_upload_lib_screen_test.dart`

- [ ] **Step 3.1: Write the failing tests**

Create `test/screens/my_upload_lib_screen_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/my_upload_lib_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('my_upload_lib_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('MyUploadLibScreen shows AppBar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('📷 My Uploads'), findsOneWidget);
  });

  testWidgets('MyUploadLibScreen shows Upload button in AppBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('+ Upload'), findsOneWidget);
  });

  testWidgets('empty state renders without error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('upload card appears with delete icon', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Photo 03/15'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping delete icon opens confirmation dialog', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this image?'), findsOneWidget);
  });

  testWidgets('correct answer deletes entry and dismisses dialog', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    final questionWidget =
        texts.firstWhere((t) => (t.data ?? '').startsWith('What is'));
    final match =
        RegExp(r'What is (\d+) \+ (\d+)').firstMatch(questionWidget.data!);
    final a = int.parse(match!.group(1)!);
    final b = int.parse(match.group(2)!);

    await tester.enterText(find.byType(TextField), '${a + b}');
    await tester.runAsync(() async {
      await tester.tap(find.text('Delete'));
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (uploadDir.existsSync() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete this image?'), findsNothing);
    expect(uploadDir.existsSync(), isFalse);
  });
}
```

- [ ] **Step 3.2: Run tests — verify they fail**

```bash
flutter test test/screens/my_upload_lib_screen_test.dart
```

Expected: compilation error — `MyUploadLibScreen` not found.

- [ ] **Step 3.3: Implement `MyUploadLibScreen`**

Create `lib/screens/my_upload_lib_screen.dart`. This file contains `MyUploadLibScreen` and its own `_CardData` (identical struct to `TemplateLibScreen`'s — not shared). It does **not** include `DeleteConfirmationDialog`; import it from `template_lib_screen.dart` instead.

Key implementation notes:
- `_loadData()` calls only `DrawingRepository.listUploadEntries()`
- `_startUpload()` runs `LineArtEngine.convert` via `compute`, creates entry, then **pushes `ColoringScreen` immediately** (same as current `HomeScreen._startUpload`)
- `onDelete` is provided for every card (all uploads are deletable)
- `DeleteConfirmationDialog` is imported from `template_lib_screen.dart` — do not duplicate it

```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../line_art/line_art_engine.dart';
import '../persistence/drawing_entry.dart';
import '../persistence/drawing_repository.dart';
import '../widgets/drawing_card_widget.dart';
import 'coloring_screen.dart';
import 'template_lib_screen.dart' show DeleteConfirmationDialog;

class MyUploadLibScreen extends StatefulWidget {
  const MyUploadLibScreen({super.key});

  @override
  State<MyUploadLibScreen> createState() => _MyUploadLibScreenState();
}

class _MyUploadLibScreenState extends State<MyUploadLibScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<_CardData> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    final entries = await DrawingRepository.listUploadEntries();
    if (mounted) {
      setState(() {
        _cards = entries
            .map((entry) => _CardData(
                  entry: entry,
                  label: _uploadLabel(entry.id),
                  hasThumbnail: File(entry.thumbnailPath).existsSync(),
                ))
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _openEntry(DrawingEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ColoringScreen(entry: entry)),
    );
    await FileImage(File(entry.thumbnailPath)).evict();
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
              content: Text('Could not convert image — try a different photo'),
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
        await FileImage(File(entry.thumbnailPath)).evict();
        _loadData();
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _confirmDelete(_CardData card) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        entry: card.entry,
        onConfirmed: () {
          setState(() => _cards.remove(card));
        },
      ),
    );
  }

  String _uploadLabel(String id) {
    try {
      final date = id.split('_')[1];
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
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          '📷 My Uploads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: const Text('+ Upload'),
                onPressed: _startUpload,
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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
                  Expanded(
                    child: _cards.isEmpty
                        ? const Center(
                            child: Text(
                              'No uploads yet.\nTap + Upload to add a photo.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black45),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _cards.length,
                            itemBuilder: (_, i) {
                              final card = _cards[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 200,
                                  child: DrawingCardWidget(
                                    entry: card.entry,
                                    label: card.label,
                                    hasThumbnail: card.hasThumbnail,
                                    onTap: () => _openEntry(card.entry),
                                    onDelete: () => _confirmDelete(card),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CardData {
  final DrawingEntry entry;
  final String label;
  final bool hasThumbnail;
  _CardData({
    required this.entry,
    required this.label,
    required this.hasThumbnail,
  });
}
```

- [ ] **Step 3.4: Run tests — verify they pass**

```bash
flutter test test/screens/my_upload_lib_screen_test.dart
```

Expected: All 6 tests pass.

- [ ] **Step 3.5: Run analyzer**

```bash
flutter analyze lib/screens/my_upload_lib_screen.dart
```

Expected: No issues.

- [ ] **Step 3.6: Commit**

```bash
git add lib/screens/my_upload_lib_screen.dart test/screens/my_upload_lib_screen_test.dart
git commit -m "feat: add MyUploadLibScreen with horizontal carousel and edge-detection upload"
```

---

## Task 4: Wire `MainMenuScreen` into `app.dart` and delete `home_screen.dart`

**Files:**
- Modify: `lib/app.dart`
- Delete: `lib/screens/home_screen.dart`
- Delete: `test/screens/home_screen_test.dart`

- [ ] **Step 4.1: Update `app.dart`**

Edit `lib/app.dart`:
- Replace `import 'screens/home_screen.dart';` with `import 'screens/main_menu_screen.dart';`
- Replace `home: const HomeScreen()` with `home: const MainMenuScreen()`

Final `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

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
      home: const MainMenuScreen(),
    );
  }
}
```

- [ ] **Step 4.2: Delete `home_screen.dart` and its test**

```bash
rm lib/screens/home_screen.dart
rm test/screens/home_screen_test.dart
```

- [ ] **Step 4.3: Update `widget_test.dart` if it references `HomeScreen`**

Check `test/widget_test.dart` for any `HomeScreen` import or usage and replace with `MainMenuScreen`. If the file already tests something unrelated, just remove the `HomeScreen` reference.

- [ ] **Step 4.4: Run the full test suite**

```bash
flutter test
```

Expected: All tests pass, no references to `HomeScreen` remaining.

- [ ] **Step 4.5: Run analyzer**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 4.6: Commit**

```bash
git add lib/app.dart lib/screens/home_screen.dart test/screens/home_screen_test.dart test/widget_test.dart
git commit -m "feat: wire MainMenuScreen as app entry point, remove HomeScreen"
```

Note: `git add` on a deleted file stages the deletion. Alternatively use `git rm lib/screens/home_screen.dart test/screens/home_screen_test.dart`.

---

## Task 5: Smoke-test on Windows Desktop

- [ ] **Step 5.1: Run on Windows Desktop**

```bash
flutter run -d windows
```

Manually verify:
1. App opens to `MainMenuScreen` — two side-by-side cards visible
2. Tap **Templates** → `TemplateLibScreen` opens with horizontal carousel of animal templates
3. Tap a template card → `ColoringScreen` opens, draw something, press back → returns to `TemplateLibScreen`, thumbnail updated
4. Back from `TemplateLibScreen` → returns to `MainMenuScreen`
5. Tap **My Uploads** → `MyUploadLibScreen` opens (empty state message shown if no uploads)
6. Back from `MyUploadLibScreen` → returns to `MainMenuScreen`
7. In `TemplateLibScreen`: tap **+ Upload** → file picker opens; after picking, card appears in carousel (no navigation to drawing screen)
8. In `MyUploadLibScreen`: tap **+ Upload** → file picker opens; after edge detection, `ColoringScreen` opens immediately
9. Delete button hidden on built-in template cards; visible on raw import and upload cards
10. Delete dialog requires correct math answer; wrong answer shows error; correct answer removes card

- [ ] **Step 5.2: Final commit if any last tweaks were needed**

```bash
git add -p
git commit -m "fix: post-smoke-test adjustments"
```

(Skip this step if no changes were needed.)
