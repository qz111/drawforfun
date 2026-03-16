import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts an uploaded photo to a transparent-background, black-line-art PNG
/// suitable for use as a coloring page overlay.
///
/// Algorithm: symmetric DoG (Difference of Gaussians) with soft threshold
///
///   decode → resize
///   → two independent Gaussian blurs on the RGB image (radius 1 and radius 4)
///   → per-pixel: luminance(fine) and luminance(coarse)
///   → absolute DoG = |L_fine − L_coarse|   (symmetric — both edge directions)
///   → soft tanh threshold
///   → dilate 1 px → RGBA PNG
///
/// Why absolute DoG instead of the asymmetric XDoG formula:
///   The original XDoG formula (1+p)·G_fine − p·G_coarse only fires when
///   the fine blur is DARKER than the coarse blur (dark-on-light edges).
///   Using the absolute difference detects both dark-on-light and
///   light-on-dark edges, so light-coloured objects on any background
///   are captured correctly.
class LineArtEngine {
  LineArtEngine._();

  static const int _maxSize = 1024;

  /// Radius difference that most affects quality:
  ///   radius 1 (fine) preserves sharp edges.
  ///   radius 4 (coarse) smooths them into a blurred reference.
  ///   A larger gap (1 vs 4 rather than 1 vs 3) makes the DoG signal stronger.
  static const int _radiusFine   = 1;
  static const int _radiusCoarse = 4;

  /// DoG values above this threshold are treated as edges.
  /// Range [0, 1] — DoG is the normalised luminance difference between the
  /// two blurs.  Real edges are typically 0.05–0.30; texture noise is < 0.03.
  static const double _dogBreak = 0.06;

  /// Sharpness of the soft threshold.  Higher = harder edge/no-edge cutoff.
  static const double _phi = 10.0;

  /// Converts [inputBytes] to a transparent line art PNG.
  /// Returns null if decoding fails.
  ///
  /// Must be called via [compute] to avoid blocking the UI thread.
  static Future<Uint8List?> convert(Uint8List inputBytes) async {
    img.Image? source;
    try {
      source = img.decodeImage(inputBytes);
    } catch (_) {
      return null;
    }
    if (source == null) return null;

    // 1. Resize — cap longest edge at 1024 px
    final resized = _resize(source);

    // 2. Apply both Gaussian blurs to the RGB image (not grayscale).
    //    img.gaussianBlur modifies its input in-place (separableConvolution
    //    mutates src and returns it), so we must clone resized for each blur
    //    to keep the two blurred copies independent.
    final blurFine   = img.gaussianBlur(img.Image.from(resized), radius: _radiusFine);
    final blurCoarse = img.gaussianBlur(img.Image.from(resized), radius: _radiusCoarse);

    // 3. Symmetric DoG → transparent RGBA
    final lineArt = _dogEdges(blurFine, blurCoarse, resized.width, resized.height);

    return Uint8List.fromList(img.encodePng(lineArt));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

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

  /// Computes the absolute DoG edge map and returns a transparent RGBA image.
  static img.Image _dogEdges(
    img.Image blurFine,
    img.Image blurCoarse,
    int w,
    int h,
  ) {
    // --- Step A: per-pixel absolute DoG -------------------------------------
    //
    // L(pixel) = perceived luminance from the blurred RGB pixel.
    // dog = |L_fine − L_coarse| / 255   →   range [0, 1]
    //
    // Using absolute value means we detect both:
    //   • dark-on-light edges  (L_fine < L_coarse → positive before abs)
    //   • light-on-dark edges  (L_fine > L_coarse → negative before abs)
    //
    // Soft threshold via tanh centred on _dogBreak:
    //   response = tanh(φ · (dog − dogBreak))
    //   response > 0  →  edge     (dog above break-point)
    //   response ≤ 0  →  no edge  (dog below break-point)

    final edges = Uint8List(w * h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pf = blurFine.getPixel(x, y);
        final pc = blurCoarse.getPixel(x, y);

        // Simple average luminance — avoids channel-access quirks on
        // different image formats (grayscale, RGB, RGBA).
        final lFine   = (pf.r + pf.g + pf.b) / 3.0;
        final lCoarse = (pc.r + pc.g + pc.b) / 3.0;

        final dog = (lFine - lCoarse).abs() / 255.0;

        // Soft threshold: positive response = above break-point = edge
        if (_tanh(_phi * (dog - _dogBreak)) > 0) {
          edges[y * w + x] = 1;
        }
      }
    }

    // --- Step B: build RGBA — lines black opaque, rest transparent ----------
    final out = img.Image(width: w, height: h, numChannels: 4);
    img.fill(out, color: img.ColorRgba8(0, 0, 0, 0));
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (edges[y * w + x] == 1) {
          out.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }
    return out;
  }

  /// tanh via exp — dart:math has no tanh. Clamped to avoid overflow.
  static double _tanh(double x) {
    if (x > 20.0)  return  1.0;
    if (x < -20.0) return -1.0;
    final e2x = exp(2.0 * x);
    return (e2x - 1.0) / (e2x + 1.0);
  }
}
