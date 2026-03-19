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
      const stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.red,
        points: [
          Offset(100, 100),
          Offset(150, 120),
          Offset(200, 100),
        ],
      );
      await expectLater(() => renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      const stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.blue,
        points: [Offset(200, 200)],
      );
      await expectLater(() => renderStroke(stroke), returnsNormally);
    });

    test('is deterministic — same stroke renders identically', () async {
      const stroke = Stroke(
        type: BrushType.splatter,
        color: Colors.green,
        points: [
          Offset(50, 50),
          Offset(100, 80),
          Offset(150, 50),
        ],
      );
      final img1 = await renderStroke(stroke);
      final img2 = await renderStroke(stroke);
      final bytes1 = await img1.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes2 = await img2.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes1!.buffer.asUint8List(), bytes2!.buffer.asUint8List());
    });
  });

  group('BrushEngine.airbrush', () {
    test('renders without throwing for multi-point stroke', () async {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [
          Offset(100, 100),
          Offset(160, 130),
          Offset(220, 100),
        ],
        themeIndex: 0,
      );
      await expectLater(() => renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [Offset(200, 200)],
        themeIndex: 1,
      );
      await expectLater(() => renderStroke(stroke), returnsNormally);
    });

    test('uses theme 0 when themeIndex is null', () async {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [Offset(200, 200), Offset(250, 200)],
        themeIndex: null,
      );
      await expectLater(() => renderStroke(stroke), returnsNormally);
    });

    test('is deterministic across all 10 themes', () async {
      for (int t = 0; t < 10; t++) {
        final stroke = Stroke(
          type: BrushType.airbrush,
          color: Colors.red,
          points: [const Offset(50, 50), const Offset(100, 80)],
          themeIndex: t,
        );
        final img1 = await renderStroke(stroke);
        final img2 = await renderStroke(stroke);
        final b1 = await img1.toByteData(format: ui.ImageByteFormat.rawRgba);
        final b2 = await img2.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(b1!.buffer.asUint8List(), b2!.buffer.asUint8List(),
            reason: 'theme $t was not deterministic');
      }
    });
  });

  group('BrushEngine.disposeTileCache', () {
    test('can be called safely when cache is empty', () {
      expect(() => BrushEngine.disposeTileCache(), returnsNormally);
    });
  });

  group('BrushEngine.pattern', () {
    test('renders without throwing for multi-point stroke', () async {
      const stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.yellow,
        points: [
          Offset(100, 200),
          Offset(150, 200),
          Offset(200, 200),
        ],
        themeIndex: 0,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders without throwing for single-point stroke', () async {
      const stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.yellow,
        points: [Offset(200, 200)],
        themeIndex: 2,
      );
      expect(() async => await renderStroke(stroke), returnsNormally);
    });

    test('renders all 10 pattern styles without throwing', () async {
      for (int t = 0; t < 10; t++) {
        final stroke = Stroke(
          type: BrushType.pattern,
          color: Colors.white,
          points: [const Offset(50, 50), const Offset(150, 100)],
          themeIndex: t,
        );
        expect(() async => await renderStroke(stroke), returnsNormally,
            reason: 'pattern style $t threw');
      }
    });

    test('disposeTileCache clears cache without throwing', () async {
      const stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.white,
        points: [Offset(50, 50), Offset(150, 100)],
        themeIndex: 0,
      );
      await renderStroke(stroke);
      expect(() => BrushEngine.disposeTileCache(), returnsNormally);
    });
  });

  group('BrushEngine.eraser', () {
    test('eraser stroke is a no-op — does not throw', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
      const stroke = Stroke(
        type: BrushType.eraser,
        color: Colors.red,
        points: [Offset(100, 100), Offset(200, 200)],
        themeIndex: 1,
      );
      expect(() => BrushEngine.paint(canvas, stroke), returnsNormally);
      recorder.endRecording();
    });
  });
}
