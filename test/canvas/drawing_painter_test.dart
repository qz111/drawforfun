import 'dart:ui';
import 'package:flutter/material.dart' hide Canvas;
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/canvas/drawing_painter.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('DrawingPainter', () {
    test('shouldRepaint returns true when strokes change', () {
      final stroke = Stroke(type: BrushType.pencil, color: Colors.red, points: [Offset.zero]);
      final oldPainter = DrawingPainter(strokes: [], currentStroke: null);
      final newPainter = DrawingPainter(strokes: [stroke], currentStroke: null);
      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when currentStroke changes', () {
      final stroke = Stroke(type: BrushType.pencil, color: Colors.red, points: [Offset.zero]);
      final oldPainter = DrawingPainter(strokes: [], currentStroke: null);
      final newPainter = DrawingPainter(strokes: [], currentStroke: stroke);
      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns false when nothing changed', () {
      final painter = DrawingPainter(strokes: [], currentStroke: null);
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
  });
}
