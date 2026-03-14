import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:drawforfun/line_art/line_art_engine.dart';

Uint8List _makeSolidColorPng(int width, int height, img.ColorRgb8 color) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: color);
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('LineArtEngine', () {
    test('returns non-empty bytes for a valid image', () async {
      final inputBytes = _makeSolidColorPng(100, 100, img.ColorRgb8(200, 150, 100));
      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('returns null for invalid bytes', () async {
      final result = await LineArtEngine.convert(Uint8List.fromList([0, 1, 2, 3]));
      expect(result, isNull);
    });

    test('output is a valid PNG (starts with PNG magic bytes)', () async {
      final inputBytes = _makeSolidColorPng(80, 80, img.ColorRgb8(255, 0, 0));
      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);
      // PNG magic: 137 80 78 71 13 10 26 10
      expect(result![0], 137);
      expect(result[1], 80);
      expect(result[2], 78);
      expect(result[3], 71);
    });

    test('solid color image produces mostly transparent output (no edges)', () async {
      // A solid color image has no edges — output should be nearly all transparent
      final inputBytes = _makeSolidColorPng(50, 50, img.ColorRgb8(128, 128, 128));
      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);

      final outputImage = img.decodePng(result!)!;
      int opaquePixels = 0;
      for (final pixel in outputImage) {
        if (pixel.a > 0) opaquePixels++;
      }
      // Very few opaque pixels expected (edge artifacts only at border)
      expect(opaquePixels, lessThan(outputImage.width * 2));
    });

    test('image is resized to max 1024px on longest edge', () async {
      // Create a 2000x500 image
      final large = img.Image(width: 2000, height: 500);
      img.fill(large, color: img.ColorRgb8(100, 100, 100));
      final inputBytes = Uint8List.fromList(img.encodePng(large));

      final result = await LineArtEngine.convert(inputBytes);
      expect(result, isNotNull);

      final outputImage = img.decodePng(result!)!;
      // Longest edge should be <= 1024
      expect(outputImage.width, lessThanOrEqualTo(1024));
    });
  });
}
