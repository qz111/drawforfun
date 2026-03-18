import 'dart:math';
import 'package:flutter/material.dart';
import 'brush_type.dart';
import 'stroke.dart';

/// Stateless brush renderer. All visual parameters are hardcoded per brush type.
class BrushEngine {
  BrushEngine._();

  /// Releases all cached pattern tile images (GPU texture memory).
  /// Call from CanvasController.dispose().
  /// Full implementation with caching added in Task 6.
  static void disposeTileCache() {}

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
  // AIRBRUSH — soft radial gradient dots accumulate at each point
  // ---------------------------------------------------------------------------
  static void _paintAirbrush(Canvas canvas, Stroke stroke) {
    const radius = 28.0;
    for (final point in stroke.points) {
      final rect = Rect.fromCircle(center: point, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            stroke.color.withValues(alpha: 0.10),
            stroke.color.withValues(alpha: 0.0),
          ],
        ).createShader(rect)
        ..blendMode = BlendMode.srcOver;
      canvas.drawCircle(point, radius, paint);
    }
  }

  // ---------------------------------------------------------------------------
  // PATTERN — repeating star icon stamped at 24px intervals along path
  // ---------------------------------------------------------------------------
  static void _paintPattern(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    double distanceAccumulator = 0.0;
    const stampInterval = 24.0;
    const iconSize = 14.0;

    _stampStar(canvas, stroke.points.first, iconSize, stroke.color);

    for (int i = 1; i < stroke.points.length; i++) {
      final segment = (stroke.points[i] - stroke.points[i - 1]).distance;
      distanceAccumulator += segment;

      if (distanceAccumulator >= stampInterval) {
        _stampStar(canvas, stroke.points[i], iconSize, stroke.color);
        distanceAccumulator = 0.0;
      }
    }
  }

  /// Draws a 5-pointed star centered at [center].
  static void _stampStar(Canvas canvas, Offset center, double size, Color color) {
    const points = 5;
    final outerRadius = size;
    final innerRadius = size * 0.4;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (pi / points) * i - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
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
      final dropCount = 6 + rng.nextInt(9); // 6–14

      for (int d = 0; d < dropCount; d++) {
        // 60% forward cone (±60°), 40% side spread (±120°)
        final double spreadAngle;
        if (rng.nextDouble() < 0.6) {
          spreadAngle = dirAngle + (rng.nextDouble() - 0.5) * (2 * pi / 3);
        } else {
          spreadAngle = dirAngle + (rng.nextDouble() - 0.5) * (4 * pi / 3);
        }
        final dropDist = 5.0 + rng.nextDouble() * 20.0;
        final dropRadius = 2.0 + rng.nextDouble() * 6.0;
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
