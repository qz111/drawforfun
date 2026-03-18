import 'dart:ui';
import 'package:flutter/material.dart' hide Canvas;
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/canvas/drawing_painter.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('DrawingPainter', () {
    test('shouldRepaint returns true when strokes change', () {
      const stroke = Stroke(type: BrushType.pencil, color: Colors.red, points: [Offset.zero]);
      const oldPainter = DrawingPainter(strokes: [], currentStroke: null);
      const newPainter = DrawingPainter(strokes: [stroke], currentStroke: null);
      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when currentStroke changes', () {
      const stroke = Stroke(type: BrushType.pencil, color: Colors.red, points: [Offset.zero]);
      const oldPainter = DrawingPainter(strokes: [], currentStroke: null);
      const newPainter = DrawingPainter(strokes: [], currentStroke: stroke);
      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns false when nothing changed', () {
      const painter = DrawingPainter(strokes: [], currentStroke: null);
      expect(painter.shouldRepaint(painter), isFalse);
    });

    test('paint does not throw with multiple brush types', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final strokes = BrushType.values.map((type) => Stroke(
        type: type,
        color: Colors.blue,
        points: [const Offset(10, 10), const Offset(50, 50)],
      )).toList();

      final painter = DrawingPainter(strokes: strokes, currentStroke: null);
      expect(
        () => painter.paint(canvas, const Size(400, 400)),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('paint handles eraser stroke without throwing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const eraser = Stroke(
        type: BrushType.eraser,
        color: Colors.red, // ignored by eraser renderer
        points: [Offset(50, 50), Offset(150, 150)],
        themeIndex: 1, // Medium
      );
      const painter = DrawingPainter(strokes: [eraser], currentStroke: null);
      expect(
        () => painter.paint(canvas, const Size(400, 400)),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('paint handles eraser single-point tap without throwing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const eraser = Stroke(
        type: BrushType.eraser,
        color: Colors.blue,
        points: [Offset(200, 200)],
        themeIndex: 2, // Large
      );
      const painter = DrawingPainter(strokes: [eraser], currentStroke: null);
      expect(
        () => painter.paint(canvas, const Size(400, 400)),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('paint handles eraser with null themeIndex (defaults to Medium)', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const eraser = Stroke(
        type: BrushType.eraser,
        color: Colors.green,
        points: [Offset(10, 10), Offset(100, 100)],
        // themeIndex omitted → null → defaults to index 1 (Medium)
      );
      const painter = DrawingPainter(strokes: [eraser], currentStroke: null);
      expect(
        () => painter.paint(canvas, const Size(400, 400)),
        returnsNormally,
      );
      recorder.endRecording();
    });
  });
}
