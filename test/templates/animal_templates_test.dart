import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/templates/animal_template.dart';
import 'package:drawforfun/templates/animal_templates.dart';

void main() {
  group('AnimalTemplates', () {
    test('has exactly 25 animals', () {
      expect(AnimalTemplates.all.length, 25);
    });

    test('all ids are unique', () {
      final ids = AnimalTemplates.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all assetPaths are unique', () {
      final paths = AnimalTemplates.all.map((t) => t.assetPath).toList();
      expect(paths.toSet().length, paths.length);
    });

    test('all assetPaths follow assets/line_art/<id>.svg pattern', () {
      for (final t in AnimalTemplates.all) {
        expect(t.assetPath, 'assets/line_art/${t.id}.svg');
      }
    });

    test('AnimalTemplate equality is value-based on id', () {
      const a = AnimalTemplate(id: 'cat', name: 'Cat', emoji: '🐱', assetPath: 'assets/line_art/cat.svg');
      const b = AnimalTemplate(id: 'cat', name: 'Cat', emoji: '🐱', assetPath: 'assets/line_art/cat.svg');
      expect(a, equals(b));
    });
  });
}
