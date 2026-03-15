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
      final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
        ..createSync(recursive: true);
      File('${uploadDir.path}/overlay.png').writeAsBytesSync([1, 2, 3]);
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
      // overlay.png not required for listing — method constructs DrawingEntry from path string only
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
}
