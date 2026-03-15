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
  });
}
