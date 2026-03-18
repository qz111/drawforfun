import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/brushes/stroke.dart';

void main() {
  group('BrushType', () {
    test('has exactly 6 values', () {
      expect(BrushType.values.length, 6);
    });

    test('contains all required brush names', () {
      final names = BrushType.values.map((e) => e.name).toSet();
      expect(names, containsAll(['pencil', 'marker', 'airbrush', 'pattern', 'splatter', 'eraser']));
    });
  });

  group('Stroke', () {
    test('stores type, color, and points', () {
      const stroke = Stroke(
        type: BrushType.pencil,
        color: Colors.red,
        points: [Offset(10, 20), Offset(30, 40)],
      );
      expect(stroke.type, BrushType.pencil);
      expect(stroke.color, Colors.red);
      expect(stroke.points.length, 2);
    });

    test('copyWithPoint adds a point', () {
      const stroke = Stroke(
        type: BrushType.marker,
        color: Colors.blue,
        points: [Offset(0, 0)],
      );
      final updated = stroke.copyWithPoint(const Offset(5, 5));
      expect(updated.points.length, 2);
      expect(updated.points.last, const Offset(5, 5));
    });

    test('themeIndex defaults to null', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.red,
        points: [],
      );
      expect(stroke.themeIndex, isNull);
    });

    test('themeIndex is stored when provided', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.red,
        points: [],
        themeIndex: 3,
      );
      expect(stroke.themeIndex, 3);
    });

    test('copyWithPoint preserves themeIndex', () {
      const stroke = Stroke(
        type: BrushType.airbrush,
        color: Colors.blue,
        points: [Offset(0, 0)],
        themeIndex: 5,
      );
      final updated = stroke.copyWithPoint(const Offset(10, 10));
      expect(updated.themeIndex, 5);
    });

    test('toJson includes themeIndex', () {
      const stroke = Stroke(
        type: BrushType.pattern,
        color: Colors.green,
        points: [],
        themeIndex: 7,
      );
      final json = stroke.toJson();
      expect(json['themeIndex'], 7);
    });

    test('fromJson with themeIndex round-trips correctly', () {
      const original = Stroke(
        type: BrushType.airbrush,
        color: Colors.red,
        points: [],
        themeIndex: 2,
      );
      final restored = Stroke.fromJson(original.toJson());
      expect(restored.themeIndex, 2);
    });

    test('fromJson without themeIndex (old saved stroke) loads with null', () {
      final json = {
        'brushType': 'pencil',
        'color': Colors.black.toARGB32(),
        'points': <Map<String, dynamic>>[],
      };
      final stroke = Stroke.fromJson(json);
      expect(stroke.themeIndex, isNull);
    });
  });
}
