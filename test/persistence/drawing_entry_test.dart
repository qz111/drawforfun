import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_entry.dart';

void main() {
  group('DrawingEntry', () {
    test('computed paths are correct', () {
      const entry = DrawingEntry(
        id: 'cat',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/cat.svg',
        directoryPath: '/docs/drawforfun/drawings/cat',
      );
      expect(entry.strokesPath, '/docs/drawforfun/drawings/cat/strokes.json');
      expect(entry.thumbnailPath, '/docs/drawforfun/drawings/cat/thumbnail.png');
      expect(entry.overlayPngPath, '/docs/drawforfun/drawings/cat/overlay.png');
    });

    test('template entry has overlayAssetPath, no overlayFilePath', () {
      const entry = DrawingEntry(
        id: 'dog',
        type: DrawingType.template,
        overlayAssetPath: 'assets/line_art/dog.svg',
        directoryPath: '/docs/drawforfun/drawings/dog',
      );
      expect(entry.overlayAssetPath, isNotNull);
      expect(entry.overlayFilePath, isNull);
      expect(entry.type, DrawingType.template);
    });

    test('upload entry has overlayFilePath, no overlayAssetPath', () {
      const entry = DrawingEntry(
        id: 'upload_20260315_120000',
        type: DrawingType.upload,
        overlayFilePath: '/docs/drawforfun/drawings/upload_20260315_120000/overlay.png',
        directoryPath: '/docs/drawforfun/drawings/upload_20260315_120000',
      );
      expect(entry.overlayFilePath, isNotNull);
      expect(entry.overlayAssetPath, isNull);
      expect(entry.type, DrawingType.upload);
    });

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

    test('throws if both overlayAssetPath and overlayFilePath are null', () {
      expect(
        () => DrawingEntry(
          id: 'bad',
          type: DrawingType.template,
          directoryPath: '/tmp/bad',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws if both overlayAssetPath and overlayFilePath are set', () {
      expect(
        () => DrawingEntry(
          id: 'bad',
          type: DrawingType.upload,
          overlayAssetPath: 'assets/line_art/cat.svg',
          overlayFilePath: '/tmp/bad/overlay.png',
          directoryPath: '/tmp/bad',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('DrawingType has customTemplate value', () {
      expect(DrawingType.values, contains(DrawingType.customTemplate));
    });

    test('customTemplate entry with overlayFilePath satisfies assert', () {
      const entry = DrawingEntry(
        id: 'custom_20260317_120000_042',
        type: DrawingType.customTemplate,
        overlayFilePath: '/tmp/custom_20260317_120000_042/overlay.png',
        directoryPath: '/tmp/custom_20260317_120000_042',
      );
      expect(entry.type, DrawingType.customTemplate);
      expect(entry.overlayFilePath, isNotNull);
      expect(entry.overlayAssetPath, isNull);
    });
  });
}
