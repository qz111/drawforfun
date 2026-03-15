import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/save/save_manager.dart';

void main() {
  group('SaveManager', () {
    test('generateFilename returns a .png string with timestamp', () {
      final name = SaveManager.generateFilename();
      expect(name.endsWith('.png'), isTrue);
      expect(name.startsWith('coloring_'), isTrue);
    });

    test('generateFilename produces correctly formatted name', () {
      final name = SaveManager.generateFilename();
      expect(name, matches(RegExp(r'^coloring_\d{8}_\d{6}\.png$')));
    });
  });
}
