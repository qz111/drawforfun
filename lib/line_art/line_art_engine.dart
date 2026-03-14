import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts an uploaded photo (any format) to a transparent-background,
/// black-line-art PNG suitable for use as a coloring page overlay.
class LineArtEngine {
  LineArtEngine._();

  static const int _maxSize = 1024;
  static const int _edgeThreshold = 40;

  /// Converts [inputBytes] to a transparent line art PNG.
  /// Returns null if decoding fails.
  static Future<Uint8List?> convert(Uint8List inputBytes) async {
    // 1. Decode — wrap in try/catch because some decoders (e.g. PsdDecoder)
    //    throw RangeError on malformed/truncated input instead of returning null.
    img.Image? source;
    try {
      source = img.decodeImage(inputBytes);
    } catch (_) {
      return null;
    }
    if (source == null) return null;

    // 2. Resize to max 1024px (longest edge)
    final resized = _resize(source);

    // 3. Grayscale
    final gray = img.grayscale(resized);

    // 4. Gaussian blur to reduce noise
    final blurred = img.gaussianBlur(gray, radius: 1);

    // 5 & 6. Sobel edge detection → threshold → transparent PNG
    final lineArt = _sobelToTransparent(blurred);

    // 7. Encode as PNG
    return Uint8List.fromList(img.encodePng(lineArt));
  }

  static img.Image _resize(img.Image src) {
    final longest = max(src.width, src.height);
    if (longest <= _maxSize) return src;
    final scale = _maxSize / longest;
    return img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Applies a Sobel operator and returns a new RGBA image where:
  /// - Strong edges → black (0, 0, 0, 255)
  /// - Weak areas → transparent (0, 0, 0, 0)
  static img.Image _sobelToTransparent(img.Image gray) {
    final w = gray.width;
    final h = gray.height;
    final out = img.Image(width: w, height: h, numChannels: 4);

    // Sobel kernels
    const gx = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]
    ];
    const gy = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1]
    ];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        double sumX = 0, sumY = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = gray.getPixel(x + kx, y + ky);
            // In a grayscale image all channels are equal; use red channel
            final brightness = pixel.r.toDouble();
            sumX += brightness * gx[ky + 1][kx + 1];
            sumY += brightness * gy[ky + 1][kx + 1];
          }
        }

        final magnitude = sqrt(sumX * sumX + sumY * sumY);

        if (magnitude > _edgeThreshold) {
          out.setPixelRgba(x, y, 0, 0, 0, 255); // black, opaque
        } else {
          out.setPixelRgba(x, y, 0, 0, 0, 0); // transparent
        }
      }
    }

    return out;
  }
}
