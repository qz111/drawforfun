import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_theme.dart';

void main() {
  group('BrushTheme', () {
    test('has exactly 10 airbrush themes', () {
      expect(BrushTheme.airbrushThemes.length, 10);
    });

    test('has exactly 10 pattern styles', () {
      expect(BrushTheme.patternStyles.length, 10);
    });

    test('every airbrush theme has a non-empty emojis list and label', () {
      for (final theme in BrushTheme.airbrushThemes) {
        expect(theme.emojis, isNotEmpty);
        expect(theme.label, isNotEmpty);
      }
    });

    test('every pattern style has a non-empty emojis list and label', () {
      for (final style in BrushTheme.patternStyles) {
        expect(style.emojis, isNotEmpty);
        expect(style.label, isNotEmpty);
      }
    });

    test('airbrush theme 0 is Blue + Gold Flowers', () {
      final theme = BrushTheme.airbrushThemes[0];
      expect(theme.label, 'Blue + Gold Flowers');
      expect(theme.baseColor, const Color(0xFF1565C0));
    });

    test('pattern style 0 is Stars', () {
      final style = BrushTheme.patternStyles[0];
      expect(style.label, 'Stars');
      expect(style.backgroundColor, const Color(0xFFFFF9C4));
    });
  });
}
