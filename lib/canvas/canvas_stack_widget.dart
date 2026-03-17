import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'canvas_controller.dart';
import 'drawing_painter.dart';

/// The main canvas: drawing layer (middle) + line art overlay (top).
/// Touch events are forwarded to [CanvasController].
/// All overlay types are wrapped in [IgnorePointer] so touch always
/// reaches the drawing layer regardless of which overlay is active.
///
/// Overlay priority (supply at most one of the line art fields):
///   1. [lineArtAssetPath] — SVG asset (built-in templates)
///   2. [lineArtFilePath]  — local PNG file path (transparent line art)
///   3. [lineArtBytes]     — in-memory PNG bytes (legacy, kept for compatibility)
///
/// For opaque background images (raw imports), use [backgroundFilePath] instead.
/// This renders the image BELOW the stroke layer so drawing is visible on top.
class CanvasStackWidget extends StatelessWidget {
  final CanvasController controller;

  /// SVG asset path for a built-in template, e.g. 'assets/line_art/cat.svg'.
  final String? lineArtAssetPath;

  /// Absolute path to a local transparent PNG for an uploaded line art overlay.
  final String? lineArtFilePath;

  /// In-memory PNG bytes. Kept for backward compatibility; prefer [lineArtFilePath].
  final Uint8List? lineArtBytes;

  /// Absolute path to an opaque background image (raw imports).
  /// Rendered below strokes so drawing appears on top of the photo.
  final String? backgroundFilePath;

  const CanvasStackWidget({
    super.key,
    required this.controller,
    this.lineArtAssetPath,
    this.lineArtFilePath,
    this.lineArtBytes,
    this.backgroundFilePath,
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
          // Layer 0: Background image for raw imports (opaque photo, below strokes).
          if (backgroundFilePath != null)
            Image.file(
              File(backgroundFilePath!),
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),

          // Layer 1: Drawing (colors) — white fill skipped when background image is present.
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              painter: DrawingPainter(
                strokes: controller.strokes,
                currentStroke: controller.currentStroke,
                paintBackground: backgroundFilePath == null,
              ),
            ),
          ),

          // Layer 2: Line art overlay (always on top, never intercepts touch).
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
