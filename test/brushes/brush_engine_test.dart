import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_engine.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('BrushEngine', () {
    late PictureRecorder recorder;
    late Canvas canvas;

    setUp(() {
      recorder = PictureRecorder();
      canvas = Canvas(recorder);
    });

    tearDown(() {
      recorder.endRecording();
    });

    final testPoints = [
      const Offset(10, 10),
      const Offset(20, 20),
      const Offset(30, 15),
      const Offset(50, 40),
    ];

    for (final type in BrushType.values) {
      test('paints $type brush without throwing', () {
        final stroke = Stroke(type: type, color: Colors.red, points: testPoints);
        expect(
          () => BrushEngine.paint(canvas, stroke),
          returnsNormally,
        );
      });
    }

    test('paintStroke with single point does not throw', () {
      final stroke = Stroke(
        type: BrushType.pencil,
        color: Colors.blue,
        points: [const Offset(5, 5)],
      );
      expect(() => BrushEngine.paint(canvas, stroke), returnsNormally);
    });

    test('paintStroke with empty points does not throw', () {
      final stroke = Stroke(
        type: BrushType.marker,
        color: Colors.green,
        points: [],
      );
      expect(() => BrushEngine.paint(canvas, stroke), returnsNormally);
    });
  });
}
