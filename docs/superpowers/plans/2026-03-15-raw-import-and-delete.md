# Raw Image Import & Universal Delete Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add raw image import to the Templates section and a parental-gate delete function to all user-owned cards.

**Architecture:** Three layers in order — (1) persistence layer gets a new `rawImport` type and three new repository methods; (2) `DrawingCardWidget` gains an optional trash-icon badge; (3) `HomeScreen` gains a `+` import button in the Templates header, raw imports merged into the grid, and a `DeleteConfirmationDialog` with a math gate wired to both sections.

**Tech Stack:** Flutter/Dart, `file_picker` (already in project), `dart:math` for random numbers, `flutter_test` for widget/unit tests.

---

## Chunk 1: Persistence Layer

### Task 1: Add `DrawingType.rawImport` and update entry test

**Files:**
- Modify: `lib/persistence/drawing_entry.dart`
- Modify: `test/persistence/drawing_entry_test.dart`

- [ ] **Step 1: Write the failing test**

Add to the `DrawingEntry` group in `test/persistence/drawing_entry_test.dart`:

```dart
test('rawImport entry has overlayFilePath, no overlayAssetPath', () {
  const entry = DrawingEntry(
    id: 'rawimport_20260315_143000',
    type: DrawingType.rawImport,
    overlayFilePath: '/docs/drawforfun/drawings/rawimport_20260315_143000/overlay.png',
    directoryPath: '/docs/drawforfun/drawings/rawimport_20260315_143000',
  );
  expect(entry.overlayFilePath, isNotNull);
  expect(entry.overlayAssetPath, isNull);
  expect(entry.type, DrawingType.rawImport);
});
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/persistence/drawing_entry_test.dart
```

Expected: FAIL — `DrawingType.rawImport` does not exist yet.

- [ ] **Step 3: Add `rawImport` to the enum**

In `lib/persistence/drawing_entry.dart`, replace:

```dart
enum DrawingType { template, upload }
```

with:

```dart
enum DrawingType { template, upload, rawImport }
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/persistence/drawing_entry_test.dart
```

Expected: All PASS.

- [ ] **Step 5: Run analyzer**

```
flutter analyze lib/persistence/drawing_entry.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/persistence/drawing_entry.dart test/persistence/drawing_entry_test.dart
git commit -m "feat: add DrawingType.rawImport enum value"
```

---

### Task 2: Add `createRawImportEntry`, `listRawImportEntries`, `deleteEntry` to repository

**Files:**
- Modify: `lib/persistence/drawing_repository.dart`
- Modify: `test/persistence/drawing_repository_test.dart`

- [ ] **Step 1: Write the failing tests**

Add three new groups at the end of `test/persistence/drawing_repository_test.dart` (before the closing `}`):

```dart
group('DrawingRepository.createRawImportEntry', () {
  test('creates folder, writes overlay.png, returns rawImport entry', () async {
    final fakeBytes = Uint8List.fromList([11, 22, 33]);
    final entry = await DrawingRepository.createRawImportEntry(fakeBytes);
    expect(entry.type, DrawingType.rawImport);
    expect(entry.id.startsWith('rawimport_'), isTrue);
    expect(entry.overlayFilePath, isNotNull);
    expect(entry.overlayAssetPath, isNull);
    final overlayFile = File(entry.overlayFilePath!);
    expect(overlayFile.existsSync(), isTrue);
    expect(overlayFile.readAsBytesSync(), fakeBytes);
  });
});

group('DrawingRepository.listRawImportEntries', () {
  test('returns empty list when no raw imports exist', () async {
    final result = await DrawingRepository.listRawImportEntries();
    expect(result, isEmpty);
  });

  test('lists rawimport_ folders, ignores upload_ and template folders', () async {
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    File('${rawDir.path}/overlay.png').writeAsBytesSync([1, 2, 3]);
    // These should be ignored:
    Directory('${tempDir.path}/upload_20260315_120000').createSync(recursive: true);
    Directory('${tempDir.path}/cat').createSync(recursive: true);

    final result = await DrawingRepository.listRawImportEntries();
    expect(result.length, 1);
    expect(result[0].id, 'rawimport_20260315_143000');
    expect(result[0].type, DrawingType.rawImport);
  });

  test('returns entries sorted newest-first', () async {
    Directory('${tempDir.path}/rawimport_20260315_100000').createSync(recursive: true);
    Directory('${tempDir.path}/rawimport_20260315_120000').createSync(recursive: true);

    final result = await DrawingRepository.listRawImportEntries();
    expect(result[0].id, 'rawimport_20260315_120000');
    expect(result[1].id, 'rawimport_20260315_100000');
  });
});

group('DrawingRepository.deleteEntry', () {
  test('deletes upload entry directory', () async {
    final fakeOverlay = Uint8List.fromList([1, 2, 3]);
    final entry = await DrawingRepository.createUploadEntry(fakeOverlay);
    expect(Directory(entry.directoryPath).existsSync(), isTrue);

    await DrawingRepository.deleteEntry(entry);
    expect(Directory(entry.directoryPath).existsSync(), isFalse);
  });

  test('deletes rawImport entry directory', () async {
    final fakeBytes = Uint8List.fromList([4, 5, 6]);
    final entry = await DrawingRepository.createRawImportEntry(fakeBytes);
    expect(Directory(entry.directoryPath).existsSync(), isTrue);

    await DrawingRepository.deleteEntry(entry);
    expect(Directory(entry.directoryPath).existsSync(), isFalse);
  });

  test('deletes strokes and thumbnail alongside overlay', () async {
    final entry = await DrawingRepository.createUploadEntry(
      Uint8List.fromList([1]),
    );
    // Write strokes and thumbnail
    await DrawingRepository.saveStrokes(entry, []);
    await DrawingRepository.saveThumbnail(entry, Uint8List.fromList([9]));

    await DrawingRepository.deleteEntry(entry);
    expect(Directory(entry.directoryPath).existsSync(), isFalse);
  });

  test('throws StateError for template entry', () async {
    const template = AnimalTemplate(
      id: 'cat',
      name: 'Cat',
      emoji: '🐱',
      assetPath: 'assets/line_art/cat.svg',
    );
    final entry = await DrawingRepository.templateEntry(template);
    // deleteEntry is async — use expectLater so the Future's error is observed.
    await expectLater(
      DrawingRepository.deleteEntry(entry),
      throwsA(isA<StateError>()),
    );
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/persistence/drawing_repository_test.dart
```

Expected: FAIL — `createRawImportEntry`, `listRawImportEntries`, `deleteEntry` not defined yet.

- [ ] **Step 3: Implement the three new methods**

Add the following three methods to `lib/persistence/drawing_repository.dart`, after the existing `createUploadEntry` method (before `_pad`):

```dart
/// Creates a new raw-import entry:
/// 1. Generates a timestamp-based ID.
/// 2. Creates the entry directory.
/// 3. Writes [bytes] to `overlay.png` without any processing.
/// 4. Returns the [DrawingEntry].
static Future<DrawingEntry> createRawImportEntry(Uint8List bytes) async {
  final now = DateTime.now();
  final id =
      'rawimport_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  final dir = await _entryDir(id);
  final overlayPath = '${dir.path}/overlay.png';
  await File(overlayPath).writeAsBytes(bytes);
  return DrawingEntry(
    id: id,
    type: DrawingType.rawImport,
    overlayFilePath: overlayPath,
    directoryPath: dir.path,
  );
}

/// Returns all raw-import entries, sorted newest-first.
static Future<List<DrawingEntry>> listRawImportEntries() async {
  final base = await _drawingsDir();
  if (!base.existsSync()) return [];
  final entries = base
      .listSync()
      .whereType<Directory>()
      .where((d) => _basename(d.path).startsWith('rawimport_'))
      .map((d) {
    final id = _basename(d.path);
    return DrawingEntry(
      id: id,
      type: DrawingType.rawImport,
      overlayFilePath: '${d.path}/overlay.png',
      directoryPath: d.path,
    );
  }).toList()
    ..sort((a, b) => b.id.compareTo(a.id));
  return entries;
}

/// Permanently deletes a user-owned entry (upload or rawImport) and all its files.
/// Throws [StateError] if called on a built-in [DrawingType.template] entry.
static Future<void> deleteEntry(DrawingEntry entry) async {
  if (entry.type == DrawingType.template) {
    throw StateError('Cannot delete a built-in template entry: ${entry.id}');
  }
  await Directory(entry.directoryPath).delete(recursive: true);
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/persistence/drawing_repository_test.dart
```

Expected: All PASS.

- [ ] **Step 5: Run analyzer**

```
flutter analyze lib/persistence/drawing_repository.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/persistence/drawing_repository.dart test/persistence/drawing_repository_test.dart
git commit -m "feat: add createRawImportEntry, listRawImportEntries, deleteEntry to DrawingRepository"
```

---

## Chunk 2: DrawingCardWidget Delete Badge

### Task 3: Add optional `onDelete` trash-icon badge to `DrawingCardWidget`

**Files:**
- Modify: `lib/widgets/drawing_card_widget.dart`
- Create: `test/widgets/drawing_card_widget_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/widgets/drawing_card_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_entry.dart';
import 'package:drawforfun/widgets/drawing_card_widget.dart';

void main() {
  const templateEntry = DrawingEntry(
    id: 'cat',
    type: DrawingType.template,
    overlayAssetPath: 'assets/line_art/cat.svg',
    directoryPath: '/tmp/cat',
  );
  const uploadEntry = DrawingEntry(
    id: 'upload_20260315_120000',
    type: DrawingType.upload,
    overlayFilePath: '/tmp/upload_20260315_120000/overlay.png',
    directoryPath: '/tmp/upload_20260315_120000',
  );
  const rawImportEntry = DrawingEntry(
    id: 'rawimport_20260315_143000',
    type: DrawingType.rawImport,
    overlayFilePath: '/tmp/rawimport_20260315_143000/overlay.png',
    directoryPath: '/tmp/rawimport_20260315_143000',
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('DrawingCardWidget delete icon', () {
    testWidgets('no delete icon when onDelete is null (template)', (tester) async {
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
            // onDelete not provided → defaults to null
          ),
        ),
      ));
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('shows delete icon when onDelete is provided (upload)', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: uploadEntry,
            label: 'Photo 03/15',
            hasThumbnail: false,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows delete icon when onDelete is provided (rawImport)', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: rawImportEntry,
            label: 'Photo 03/15',
            hasThumbnail: false,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tapping delete icon calls onDelete, not onTap', (tester) async {
      var tapCount = 0;
      var deleteTapCount = 0;
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: uploadEntry,
            label: 'Photo 03/15',
            hasThumbnail: false,
            onTap: () => tapCount++,
            onDelete: () => deleteTapCount++,
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      expect(deleteTapCount, 1);
      expect(tapCount, 0);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/widgets/drawing_card_widget_test.dart
```

Expected: FAIL — `onDelete` parameter does not exist yet.

- [ ] **Step 3: Implement the changes to `DrawingCardWidget`**

In `lib/widgets/drawing_card_widget.dart`:

**3a.** Add the new parameter to the class field list (after `onTap`):

```dart
final VoidCallback? onDelete;
```

**3b.** Add it to the constructor (after `required this.onTap`):

```dart
this.onDelete,
```

**3c.** Replace the `build` method body. Wrap the existing `GestureDetector > Container` in a `Stack`, and add the trash icon as a `Positioned` overlay:

```dart
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      GestureDetector(
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
      ),
      if (onDelete != null)
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
    ],
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/widgets/drawing_card_widget_test.dart
```

Expected: All PASS.

- [ ] **Step 5: Run analyzer**

```
flutter analyze lib/widgets/drawing_card_widget.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/drawing_card_widget.dart test/widgets/drawing_card_widget_test.dart
git commit -m "feat: add optional onDelete trash-icon badge to DrawingCardWidget"
```

---

## Chunk 3: HomeScreen Refactor

### Task 4: Templates `+` button and raw import grid integration

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Modify: `test/screens/home_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Add to `test/screens/home_screen_test.dart`:

```dart
testWidgets('HomeScreen Templates header has + import button', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
});

testWidgets('HomeScreen shows raw import card in Templates grid', (tester) async {
  // Pre-create a rawimport directory so it appears in the grid
  final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
    ..createSync(recursive: true);
  // Write minimal valid PNG header bytes so Image.file doesn't crash
  File('${rawDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  // The raw import label 'Photo 03/15' should appear in the Templates grid
  expect(find.text('Photo 03/15'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/screens/home_screen_test.dart
```

Expected: FAIL on the two new tests.

- [ ] **Step 3: Update `_HomeScreenState`**

**3a.** Add a new state variable for the import-in-progress flag (alongside `_isUploading`):

```dart
bool _isImporting = false;
```

**3b.** Update `_loadData()` to fetch all three data sources in parallel and merge raw imports into `_templateCards` after built-ins:

```dart
Future<void> _loadData() async {
  if (mounted) setState(() => _isLoading = true);

  // Fetch all three sources in parallel
  final results = await Future.wait([
    Future.wait(
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
    ),
    DrawingRepository.listRawImportEntries().then((entries) => entries.map((entry) {
      final hasThumbnail = File(entry.thumbnailPath).existsSync();
      return _CardData(
        // _uploadLabel handles both 'upload_YYYYMMDD_...' and 'rawimport_YYYYMMDD_...'
        // because both have the date segment at split('_')[1].
        entry: entry,
        label: _uploadLabel(entry.id),
        emoji: '📷',
        hasThumbnail: hasThumbnail,
      );
    }).toList()),
    DrawingRepository.listUploadEntries().then((entries) => entries.map((entry) {
      final hasThumbnail = File(entry.thumbnailPath).existsSync();
      return _CardData(
        entry: entry,
        label: _uploadLabel(entry.id),
        hasThumbnail: hasThumbnail,
      );
    }).toList()),
  ]);

  if (mounted) {
    setState(() {
      // Built-in templates first, raw imports appended after
      _templateCards = [...results[0], ...results[1]];
      _uploadCards = results[2];
      _isLoading = false;
    });
  }
}
```

**3c.** Add the `_startRawImport()` method (after `_startUpload`):

```dart
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
```

**3d.** Update the Templates section header row in `build()`. Replace the existing header `Row` (the one with `'🐾 Built-in Templates'` and the `'${_templateCards.length} animals'` label) with:

```dart
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
    _isImporting
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.deepPurple,
            tooltip: 'Add photo to templates',
            onPressed: _startRawImport,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
  ],
),
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/screens/home_screen_test.dart
```

Expected: All PASS.

- [ ] **Step 5: Run analyzer**

```
flutter analyze lib/screens/home_screen.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/home_screen.dart test/screens/home_screen_test.dart
git commit -m "feat: add raw import + button and merge rawImport cards into Templates grid"
```

---

### Task 5: Wire `onDelete` and add `DeleteConfirmationDialog`

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Modify: `test/screens/home_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Add to `test/screens/home_screen_test.dart`:

```dart
testWidgets('delete icon absent on built-in template cards', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  // Built-in template cards must never show a delete icon
  expect(find.byIcon(Icons.delete_outline), findsNothing);
});

testWidgets('delete icon present on rawImport card in Templates grid',
    (tester) async {
  final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
    ..createSync(recursive: true);
  File('${rawDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.delete_outline), findsOneWidget);
});

testWidgets('delete icon present on upload card in My Uploads', (tester) async {
  final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
    ..createSync(recursive: true);
  File('${uploadDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.delete_outline), findsOneWidget);
});

testWidgets('tapping delete icon opens confirmation dialog', (tester) async {
  final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
    ..createSync(recursive: true);
  File('${uploadDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.delete_outline));
  await tester.pumpAndSettle();
  expect(find.text('Delete this image?'), findsOneWidget);
});

testWidgets('wrong answer in dialog shows error text', (tester) async {
  final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
    ..createSync(recursive: true);
  File('${uploadDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.delete_outline));
  await tester.pumpAndSettle();

  // Enter a deliberately wrong answer (0 is always wrong: sums are 10–30)
  await tester.enterText(find.byType(TextField), '0');
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  expect(find.text('Wrong answer, try again'), findsOneWidget);
  // Dialog stays open
  expect(find.text('Delete this image?'), findsOneWidget);
});

testWidgets('correct answer deletes entry and dismisses dialog', (tester) async {
  final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
    ..createSync(recursive: true);
  File('${uploadDir.path}/overlay.png')
      .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.delete_outline));
  await tester.pumpAndSettle();

  // Parse the math question from the dialog to get the correct answer.
  // Scan all Text widgets and find the one whose data starts with 'What is'.
  final texts = tester.widgetList<Text>(find.byType(Text)).toList();
  final questionWidget = texts.firstWhere(
    (t) => (t.data ?? '').startsWith('What is'),
  );
  // Extract A and B from 'What is A + B?'
  final match = RegExp(r'What is (\d+) \+ (\d+)').firstMatch(questionWidget.data!);
  final a = int.parse(match!.group(1)!);
  final b = int.parse(match.group(2)!);

  await tester.enterText(find.byType(TextField), '${a + b}');
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  // Dialog dismissed
  expect(find.text('Delete this image?'), findsNothing);
  // Upload directory deleted
  expect(uploadDir.existsSync(), isFalse);
});
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/screens/home_screen_test.dart
```

Expected: FAIL on the new tests — `onDelete` not wired yet and `DeleteConfirmationDialog` does not exist.

- [ ] **Step 3: Add `_confirmDelete` method to `_HomeScreenState`**

Add after `_startRawImport`:

```dart
void _confirmDelete(_CardData card) {
  showDialog<void>(
    context: context,
    builder: (_) => DeleteConfirmationDialog(
      entry: card.entry,
      onConfirmed: () {
        setState(() {
          // List.remove uses == which defaults to reference equality for _CardData.
          // This is correct: `card` is the exact same object instance stored in
          // _templateCards / _uploadCards, so reference equality finds it reliably.
          _templateCards.remove(card);
          _uploadCards.remove(card);
        });
      },
    ),
  );
}
```

- [ ] **Step 4: Wire `onDelete` in the Templates grid `itemBuilder`**

In the `GridView.builder` `itemBuilder`, update `DrawingCardWidget`:

```dart
itemBuilder: (_, i) {
  final card = _templateCards[i];
  return DrawingCardWidget(
    entry: card.entry,
    label: card.label,
    emoji: card.emoji,
    hasThumbnail: card.hasThumbnail,
    onTap: () => _openEntry(card.entry),
    onDelete: card.entry.type == DrawingType.template
        ? null
        : () => _confirmDelete(card),
  );
},
```

- [ ] **Step 5: Wire `onDelete` in the My Uploads `ListView`**

In the `ListView` inside My Uploads, update `DrawingCardWidget` (the one inside `.map((card) => ...)`):

```dart
child: DrawingCardWidget(
  entry: card.entry,
  label: card.label,
  hasThumbnail: card.hasThumbnail,
  onTap: () => _openEntry(card.entry),
  onDelete: () => _confirmDelete(card),
),
```

- [ ] **Step 6: Add `DeleteConfirmationDialog` at the bottom of `home_screen.dart`**

Add the following after the `_UploadAddButton` class (at end of file). Also add `import 'dart:math';` at the top of the file.

```dart
/// A dialog that requires the user to solve a simple addition problem
/// before permanently deleting a user-owned drawing entry.
///
/// The math gate (sum of two random numbers 5–15) is trivially easy for
/// adults but reliably unsolvable by children aged 3–5.
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
    _a = 5 + rng.nextInt(11); // 5–15
    _b = 5 + rng.nextInt(11); // 5–15
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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

- [ ] **Step 7: Run tests to verify they pass**

```
flutter test test/screens/home_screen_test.dart
```

Expected: All PASS.

- [ ] **Step 8: Run the full test suite**

```
flutter test
```

Expected: All PASS. No regressions.

- [ ] **Step 9: Run analyzer across all changed files**

```
flutter analyze
```

Expected: No issues.

- [ ] **Step 10: Commit**

```bash
git add lib/screens/home_screen.dart test/screens/home_screen_test.dart
git commit -m "feat: wire onDelete, add DeleteConfirmationDialog with math parental gate"
```
