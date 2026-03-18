import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'brush_theme.dart';
import 'brush_type.dart';
import 'stroke.dart';

/// Stateless brush renderer. All visual parameters are hardcoded per brush type.
class BrushEngine {
  BrushEngine._();

  // Pattern tile cache: lazily generated, session-scoped.
  // ui.Image holds GPU texture — disposed via disposeTileCache().
  static final Map<int, ui.Image> _tileCache = {};

  /// Releases all cached pattern tile images (GPU texture memory).
  /// Call from CanvasController.dispose().
  static void disposeTileCache() {
    for (final image in _tileCache.values) {
      image.dispose();
    }
    _tileCache.clear();
  }

  /// Entry point: dispatches to the correct brush painter.
  static void paint(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    switch (stroke.type) {
      case BrushType.pencil:
        _paintPencil(canvas, stroke);
        break;
      case BrushType.marker:
        _paintMarker(canvas, stroke);
        break;
      case BrushType.airbrush:
        _paintAirbrush(canvas, stroke);
        break;
      case BrushType.pattern:
        _paintPattern(canvas, stroke);
        break;
      case BrushType.splatter:
        _paintSplatter(canvas, stroke);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // PENCIL — thin, slightly rough strokes with opacity jitter
  // ---------------------------------------------------------------------------
  static void _paintPencil(Canvas canvas, Stroke stroke) {
    final rng = Random(stroke.hashCode);  // deterministic: same stroke = same result
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        1.5,
        Paint()..color = stroke.color.withValues(alpha: 0.8),
      );
      return;
    }

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final opacity = 0.7 + rng.nextDouble() * 0.3;
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: opacity)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
  }

  // ---------------------------------------------------------------------------
  // MARKER — bold, semi-transparent, flat strokes that build up on overlap
  // ---------------------------------------------------------------------------
  static void _paintMarker(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        9.0,
        Paint()..color = stroke.color.withValues(alpha: 0.55),
      );
      return;
    }

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: 0.55)
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  // ---------------------------------------------------------------------------
  // AIRBRUSH — opaque base stroke + emoji particles scattered along path
  // ---------------------------------------------------------------------------
  static void _paintAirbrush(Canvas canvas, Stroke stroke) {
    final theme = BrushTheme.airbrushThemes[stroke.themeIndex ?? 0];
    final rng = Random(stroke.hashCode);

    // Single point
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        12.0,
        Paint()..color = theme.baseColor,
      );
      _paintEmoji(
        canvas,
        theme.emojis[0],
        stroke.points.first - const Offset(0, 18),
        16.0,
        0.0,
      );
      return;
    }

    // Base stroke — thick, fully opaque
    final basePath = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      basePath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(
      basePath,
      Paint()
        ..color = theme.baseColor
        ..strokeWidth = 20.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Emoji particles every ~30px along path
    double distAccum = 0.0;
    const interval = 30.0;
    int particleIndex = 0;

    for (int i = 1; i < stroke.points.length; i++) {
      final p1 = stroke.points[i - 1];
      final p2 = stroke.points[i];
      distAccum += (p2 - p1).distance;

      if (distAccum >= interval) {
        distAccum = 0.0;
        final emojiIndex = (particleIndex + stroke.hashCode) % theme.emojis.length;
        final fontSize = 14.0 + rng.nextDouble() * 8.0; // 14–22px
        final rotation = (rng.nextDouble() - 0.5) * (pi / 3); // ±30°
        final offsetX = (rng.nextDouble() - 0.5) * 30.0; // ±15px
        final offsetY = (rng.nextDouble() - 0.5) * 30.0;
        _paintEmoji(
          canvas,
          theme.emojis[emojiIndex],
          p2 + Offset(offsetX, offsetY),
          fontSize,
          rotation,
        );
        particleIndex++;
      }
    }
  }

  /// Renders a single emoji at [center] with the given [fontSize] and [rotation] (radians).
  static void _paintEmoji(Canvas canvas, String emoji, Offset center, double fontSize, double rotation) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // PATTERN — seamless wallpaper revealed by drawing (ImageShader + TileMode.repeated)
  // ---------------------------------------------------------------------------
  static void _paintPattern(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final styleIndex = stroke.themeIndex ?? 0;
    final style = BrushTheme.patternStyles[styleIndex];

    // On web, toImageSync() is unavailable — fall back to plain fill stroke.
    if (kIsWeb) {
      final fallbackPaint = Paint()
        ..color = style.backgroundColor
        ..strokeWidth = 40.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length < 2) {
        canvas.drawCircle(stroke.points.first, 24.0, fallbackPaint..style = PaintingStyle.fill);
        return;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, fallbackPaint);
      return;
    }

    // Generate tile lazily on first use of this pattern index.
    // Must be called from inside paint() — never from shouldRepaint().
    if (!_tileCache.containsKey(styleIndex)) {
      _tileCache[styleIndex] = _generateTile(style);
    }
    final tile = _tileCache[styleIndex]!;

    final shader = ui.ImageShader(
      tile,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      Float64List.fromList([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]),
    );
    final paint = Paint()
      ..shader = shader
      ..strokeWidth = 40.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        24.0,
        Paint()..shader = shader,
      );
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  /// Generates an 80×80 tiled image for the given pattern style.
  /// Synchronous via toImageSync() — native only.
  static ui.Image _generateTile(PatternStyle style) {
    const tileSize = 80.0;
    final recorder = ui.PictureRecorder();
    final tileCanvas = Canvas(recorder, const Rect.fromLTWH(0, 0, tileSize, tileSize));

    // Background fill
    tileCanvas.drawRect(
      const Rect.fromLTWH(0, 0, tileSize, tileSize),
      Paint()..color = style.backgroundColor,
    );

    // Emoji grid — 2 columns × rows based on emoji count
    final emojis = style.emojis;
    const emojiSize = 28.0;
    const cols = 2;
    final rows = (emojis.length / cols).ceil();
    const cellW = tileSize / cols;
    final cellH = tileSize / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final idx = row * cols + col;
        if (idx >= emojis.length) break;
        final tp = TextPainter(
          text: TextSpan(
            text: emojis[idx],
            style: const TextStyle(fontSize: emojiSize),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final x = col * cellW + (cellW - tp.width) / 2;
        final y = row * cellH + (cellH - tp.height) / 2;
        tp.paint(tileCanvas, Offset(x, y));
      }
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(tileSize.toInt(), tileSize.toInt());
    picture.dispose();
    return image;
  }

  // ---------------------------------------------------------------------------
  // SPLATTER — thick central blob + directional opaque droplets
  // ---------------------------------------------------------------------------
  static void _paintSplatter(Canvas canvas, Stroke stroke) {
    final rng = Random(stroke.hashCode);

    // Single point: circle + 3 radial droplets
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        8.0,
        Paint()..color = stroke.color,
      );
      for (int i = 0; i < 3; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final dist = 6.0 + rng.nextDouble() * 10.0;
        canvas.drawCircle(
          stroke.points.first + Offset(cos(angle) * dist, sin(angle) * dist),
          2.0 + rng.nextDouble() * 3.0,
          Paint()..color = stroke.color,
        );
      }
      return;
    }

    // Central blob path
    final blobPath = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      blobPath.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(
      blobPath,
      Paint()
        ..color = stroke.color
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Directional droplets per segment
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final delta = p2 - p1;
      final dist = delta.distance;
      if (dist == 0) continue;

      final dirAngle = atan2(delta.dy, delta.dx);
      final segRng = Random(stroke.hashCode + i);
      final dropCount = 6 + segRng.nextInt(9); // 6–14

      for (int d = 0; d < dropCount; d++) {
        // 60% forward cone (±60°), 40% side spread (±120°)
        final double spreadAngle;
        if (segRng.nextDouble() < 0.6) {
          spreadAngle = dirAngle + (segRng.nextDouble() - 0.5) * (2 * pi / 3);
        } else {
          spreadAngle = dirAngle + (segRng.nextDouble() - 0.5) * (4 * pi / 3);
        }
        final dropDist = 5.0 + segRng.nextDouble() * 20.0;
        final dropRadius = 2.0 + segRng.nextDouble() * 6.0;
        final dropCenter = p1 + Offset(
          cos(spreadAngle) * dropDist,
          sin(spreadAngle) * dropDist,
        );
        canvas.drawCircle(
          dropCenter,
          dropRadius,
          Paint()..color = stroke.color,
        );
      }
    }
  }
}
