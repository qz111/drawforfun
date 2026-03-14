import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('BrushType', () {
    test('has exactly 5 values', () {
      expect(BrushType.values.length, 5);
    });

    test('contains all required brush names', () {
      final names = BrushType.values.map((e) => e.name).toSet();
      expect(names, containsAll(['pencil', 'marker', 'airbrush', 'pattern', 'splatter']));
    });
  });

  group('Stroke', () {
    test('stores type, color, and points', () {
      final stroke = Stroke(
        type: BrushType.pencil,
        color: Colors.red,
        points: [const Offset(10, 20), const Offset(30, 40)],
      );
      expect(stroke.type, BrushType.pencil);
      expect(stroke.color, Colors.red);
      expect(stroke.points.length, 2);
    });

    test('copyWithPoint adds a point', () {
      final stroke = Stroke(
        type: BrushType.marker,
        color: Colors.blue,
        points: [const Offset(0, 0)],
      );
      final updated = stroke.copyWithPoint(const Offset(5, 5));
      expect(updated.points.length, 2);
      expect(updated.points.last, const Offset(5, 5));
    });
  });
}
