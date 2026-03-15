import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (bottom) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// Optional line art PNG bytes. When null, shows blank canvas.
  final Uint8List? lineArtBytes;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtBytes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => controller.startStroke(
        controller.activeBrushType,
        controller.activeColor,
        d.localPosition,
      ),
      onPanUpdate: (d) => controller.addPoint(d.localPosition),
      onPanEnd: (_) => controller.endStroke(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Drawing (colors)
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              painter: DrawingPainter(
                strokes: controller.strokes,
                currentStroke: controller.currentStroke,
              ),
            ),
          ),

          // Layer 1: Line art (always on top — lines never covered)
          if (lineArtBytes != null)
            Image.memory(
              lineArtBytes!,
              fit: BoxFit.contain,
              // Transparent pixels in the PNG let the drawing layer show through
              gaplessPlayback: true,
            ),
        ],
      ),
    );
  }
}
