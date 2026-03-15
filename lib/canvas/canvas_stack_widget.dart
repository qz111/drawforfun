import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (bottom) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
/// All overlay types are wrapped in [IgnorePointer] so touch always
/// reaches the drawing layer regardless of which overlay is active.
///
/// Overlay priority (supply at most one):
///   1. [lineArtAssetPath] — SVG asset (built-in templates)
///   2. [lineArtFilePath]  — local PNG file path (uploaded photos)
///   3. [lineArtBytes]     — in-memory PNG bytes (legacy, kept for compatibility)
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// SVG asset path for a built-in template, e.g. 'assets/line_art/cat.svg'.
  final String? lineArtAssetPath;

  /// Absolute path to a local PNG file for an uploaded photo overlay.
  final String? lineArtFilePath;

  /// In-memory PNG bytes. Kept for backward compatibility; prefer [lineArtFilePath].
  final Uint8List? lineArtBytes;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtAssetPath,
    this.lineArtFilePath,
    this.lineArtBytes,
  }) : assert(
          // At most one overlay field may be non-null.
          (lineArtAssetPath == null ? 0 : 1) +
                  (lineArtFilePath == null ? 0 : 1) +
                  (lineArtBytes == null ? 0 : 1) <=
              1,
          'Supply at most one overlay: lineArtAssetPath, lineArtFilePath, or lineArtBytes.',
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
          if (lineArtAssetPath != null)
            IgnorePointer(
              child: SvgPicture.asset(
                lineArtAssetPath!,
                fit: BoxFit.fill,
                placeholderBuilder: (_) => const SizedBox.expand(),
              ),
            )
          else if (lineArtFilePath != null)
            IgnorePointer(
              child: Image.file(
                File(lineArtFilePath!),
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            )
          else if (lineArtBytes != null)
            IgnorePointer(
              child: Image.memory(
                lineArtBytes!,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }
}
