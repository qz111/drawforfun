import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (bottom) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
/// The overlay (SVG template or photo PNG) is wrapped in [IgnorePointer]
/// so all touch always reaches the drawing layer.
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// Optional photo line art PNG bytes (from LineArtEngine). Mutually
  /// exclusive with [lineArtAssetPath] — caller must null one when setting the other.
  final Uint8List? lineArtBytes;

  /// Optional SVG asset path for a built-in animal template
  /// (e.g. 'assets/line_art/cat.svg'). Takes priority over [lineArtBytes]
  /// if both are somehow non-null.
  final String? lineArtAssetPath;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtBytes,
    this.lineArtAssetPath,
  }) : assert(
          lineArtBytes == null || lineArtAssetPath == null,
          'Supply at most one overlay: lineArtBytes or lineArtAssetPath, not both.',
        );

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
      onPanCancel: () => controller.endStroke(),
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

          // Layer 1: Line art overlay (always on top, never intercepts touch).
          // SVG template takes priority; falls back to photo PNG bytes.
          if (lineArtAssetPath != null)
            IgnorePointer(
              child: SvgPicture.asset(
                lineArtAssetPath!,
                fit: BoxFit.fill, // fill ensures overlay and drawing layer share the same coordinate space
                placeholderBuilder: (_) => const SizedBox.expand(), // silent fallback on load error
              ),
            )
          else if (lineArtBytes != null)
            IgnorePointer(
              child: Image.memory(
                lineArtBytes!,
                fit: BoxFit.fill,
                // Transparent pixels in the PNG let the drawing layer show through
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }
}
