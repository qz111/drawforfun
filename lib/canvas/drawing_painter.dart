import 'package:flutter/material.dart';
import '../brushes/brush_engine.dart';
import '../brushes/brush_type.dart';
import '../brushes/stroke.dart';

/// CustomPainter that renders all committed strokes plus the active stroke.
/// This is the BOTTOM layer of the canvas Stack — sits under the line art.
///
/// All stroke rendering happens inside [canvas.saveLayer] so that
/// eraser strokes using [BlendMode.clear] punch holes in the coloring layer
/// without affecting the line-art overlay widget above.
class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  /// When false, the white background fill is skipped (used when a background
  /// image is rendered as a separate widget below this painter).
  final bool paintBackground;

  // Stroke widths for the three eraser sizes: Small / Medium / Large.
  static const _eraserWidths = [20.0, 40.0, 70.0];

  const DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    this.paintBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // White background drawn OUTSIDE saveLayer — acts as the "erased-to" canvas floor.
    // Eraser holes in the saveLayer reveal this white rect below.
    // Skipped for rawImport entries (paintBackground=false) so erased areas instead
    // show through to the background photo widget (Layer 0 in CanvasStackWidget).
    if (paintBackground) {
      canvas.drawRect(bounds, Paint()..color = Colors.white);
    }

    // saveLayer isolates this layer so BlendMode.clear punches holes in the
    // coloring strokes without clearing the widget tree above (line-art overlay).
    canvas.saveLayer(bounds, Paint());

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.type == BrushType.eraser) {
      _paintEraser(canvas, stroke);
    } else {
      BrushEngine.paint(canvas, stroke);
    }
  }

  /// Renders an eraser stroke using BlendMode.clear to punch transparent holes
  /// in the coloring layer. Size is encoded in [Stroke.themeIndex] (0=S, 1=M, 2=L).
  void _paintEraser(Canvas canvas, Stroke stroke) {
    final w = _eraserWidths[stroke.themeIndex ?? 1];

    // Single-point tap: fill circle.
    // PaintingStyle.fill with radius w/2 matches the visual endpoint size of
    // a stroke path with strokeWidth=w (cap radius = w/2).
    if (stroke.points.length < 2) {
      canvas.drawCircle(
        stroke.points.first,
        w / 2,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final p in stroke.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.paintBackground != paintBackground;
  }
}
