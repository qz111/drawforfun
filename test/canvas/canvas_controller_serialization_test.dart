import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';

void main() {
  group('CanvasController serialization', () {
    test('strokesToJson returns empty list when no strokes', () {
      final controller = CanvasController();
      expect(controller.strokesToJson(), isEmpty);
      controller.dispose();
    });

    test('strokesToJson serializes all committed strokes', () {
      final controller = CanvasController();
      controller.startStroke(BrushType.marker, const Color(0xFFFF0000), const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      final json = controller.strokesToJson();
      expect(json.length, 1);
      expect(json[0]['brushType'], 'marker');
      controller.dispose();
    });

    test('loadStrokes replaces existing strokes and notifies', () {
      final controller = CanvasController();
      controller.startStroke(BrushType.pencil, const Color(0xFF000000), const Offset(0, 0));
      controller.endStroke();
      expect(controller.strokes.length, 1);

      final newStrokes = [
        const Stroke(type: BrushType.airbrush, color: Color(0xFF00FF00), points: [Offset(5, 5)]),
        const Stroke(type: BrushType.marker, color: Color(0xFF0000FF), points: [Offset(1, 2)]),
      ];
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.loadStrokes(newStrokes);

      expect(controller.strokes.length, 2);
      expect(controller.strokes[0].type, BrushType.airbrush);
      expect(controller.strokes[1].type, BrushType.marker);
      expect(notifyCount, greaterThan(0));
      controller.dispose();
    });

    test('strokesToJson / loadStrokes roundtrip preserves all data', () {
      final original = CanvasController();
      original.startStroke(BrushType.splatter, const Color(0xFFABCDEF), const Offset(1.5, 2.5));
      original.addPoint(const Offset(3.0, 4.0));
      original.endStroke();

      final json = original.strokesToJson();
      final restored = CanvasController();
      restored.loadStrokes(json.map(Stroke.fromJson).toList());

      expect(restored.strokes.length, 1);
      expect(restored.strokes[0].type, BrushType.splatter);
      expect(restored.strokes[0].color, const Color(0xFFABCDEF));
      expect(restored.strokes[0].points[0], const Offset(1.5, 2.5));
      expect(restored.strokes[0].points[1], const Offset(3.0, 4.0));

      original.dispose();
      restored.dispose();
    });
  });
}
