import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/palette/color_palette.dart';

void main() {
  group('ColorPalette', () {
    test('has exactly 24 colors', () {
      expect(ColorPalette.swatches.length, 24);
    });

    test('all colors are fully opaque', () {
      for (final color in ColorPalette.swatches) {
        expect((color.a * 255.0).round().clamp(0, 255), 255,
            reason: 'Color $color should be opaque');
      }
    });

    test('eraser color is white', () {
      expect(ColorPalette.eraser, Colors.white);
    });
  });
}
