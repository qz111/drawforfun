import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('Stroke serialization', () {
    test('toJson/fromJson roundtrip — marker', () {
      const stroke = Stroke(
        type: BrushType.marker,
        color: Color(0xFFFF0000),
        points: [Offset(1.0, 2.0), Offset(3.5, 4.5)],
      );
      final json = stroke.toJson();
      final restored = Stroke.fromJson(json);
      expect(restored.type, stroke.type);
      expect(restored.color, stroke.color);
      expect(restored.points.length, 2);
      expect(restored.points[0].dx, 1.0);
      expect(restored.points[0].dy, 2.0);
      expect(restored.points[1].dx, 3.5);
      expect(restored.points[1].dy, 4.5);
    });

    test('roundtrips all brush types', () {
      for (final brushType in BrushType.values) {
        final stroke = Stroke(
          type: brushType,
          color: const Color(0xFF0000FF),
          points: const [Offset(0, 0)],
        );
        final restored = Stroke.fromJson(stroke.toJson());
        expect(restored.type, brushType);
      }
    });

    test('roundtrip with empty points list', () {
      const stroke = Stroke(
        type: BrushType.pencil,
        color: Color(0xFF123456),
        points: [],
      );
      final restored = Stroke.fromJson(stroke.toJson());
      expect(restored.points, isEmpty);
    });

    test('toJson uses brushType key', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Color(0xFF000000),
        points: [],
      );
      final json = stroke.toJson();
      expect(json.containsKey('brushType'), isTrue);
      expect(json['brushType'], 'airbrush');
      expect(json.containsKey('color'), isTrue);
      expect(json.containsKey('points'), isTrue);
    });
  });
}
