import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_engine.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

/// Helper: render a stroke onto an in-memory canvas and return the image.
Future<ui.Image> renderStroke(Stroke stroke) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 400),
    Paint()..color = Colors.white,
  );
  BrushEngine.paint(canvas, stroke);
  final picture = recorder.endRecording();
  return picture.toImage(400, 400);
}

void main() {
  group('BrushEngine.splatter', () {
    test('renders without throwing for multi-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.red,
        points: [
          const Offset(100, 100),
          const Offset(150, 120),
          const Offset(200, 100),
        ],
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      final stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.blue,
        points: [const Offset(200, 200)],
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('is deterministic — same stroke renders identically', () async {
      final stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.green,
        points: [
          const Offset(50, 50),
          const Offset(100, 80),
          const Offset(150, 50),
        ],
      );
      final img1 = await renderStroke(stroke);
      final img2 = await renderStroke(stroke);
      final bytes1 = await img1.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes2 = await img2.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes1!.buffer.asUint8List(), bytes2!.buffer.asUint8List());
    });
  });

  group('BrushEngine.disposeTileCache', () {
    test('can be called safely when cache is empty', () {
      expect(() => BrushEngine.disposeTileCache(), returnsNormally);
    });
  });
}
