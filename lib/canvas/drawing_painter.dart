import 'package:flutter/material.dart';
import '../brushes/brush_engine.dart';
import '../brushes/stroke.dart';

/// CustomPainter that renders all committed strokes plus the active stroke.
/// This is the BOTTOM layer of the canvas Stack — sits under the line art.
class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  const DrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Committed strokes
    for (final stroke in strokes) {
      BrushEngine.paint(canvas, stroke);
    }

    // In-progress stroke (drawn on top of committed ones)
    if (currentStroke != null) {
      BrushEngine.paint(canvas, currentStroke!);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
