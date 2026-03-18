import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';
import 'package:drawforfun/brushes/brush_type.dart';

void main() {
  group('CanvasController', () {
    late CanvasController controller;

    setUp(() {
      controller = CanvasController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with empty strokes and no current stroke', () {
      expect(controller.strokes, isEmpty);
      expect(controller.currentStroke, isNull);
    });

    test('startStroke creates a new current stroke', () {
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(10, 10));
      expect(controller.currentStroke, isNotNull);
      expect(controller.currentStroke!.type, BrushType.pencil);
      expect(controller.currentStroke!.points.length, 1);
    });

    test('addPoint appends to current stroke', () {
      controller.startStroke(BrushType.marker, Colors.blue, const Offset(0, 0));
      controller.addPoint(const Offset(5, 5));
      controller.addPoint(const Offset(10, 10));
      expect(controller.currentStroke!.points.length, 3);
    });

    test('endStroke commits current stroke to strokes list', () {
      controller.startStroke(BrushType.pencil, Colors.green, const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      expect(controller.strokes.length, 1);
      expect(controller.currentStroke, isNull);
    });

    test('undo removes the last committed stroke', () {
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(0, 0));
      controller.endStroke();
      controller.startStroke(BrushType.marker, Colors.blue, const Offset(5, 5));
      controller.endStroke();
      controller.undo();
      expect(controller.strokes.length, 1);
    });

    test('clear removes all strokes', () {
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(0, 0));
      controller.endStroke();
      controller.clear();
      expect(controller.strokes, isEmpty);
    });

    test('undo on empty list does not throw', () {
      expect(() => controller.undo(), returnsNormally);
    });

    test('activeThemeIndex defaults to 0 for airbrush', () {
      controller.setActiveBrush(BrushType.airbrush);
      expect(controller.activeThemeIndex, 0);
    });

    test('activeThemeIndex defaults to 0 for pattern', () {
      controller.setActiveBrush(BrushType.pattern);
      expect(controller.activeThemeIndex, 0);
    });

    test('setActiveTheme updates airbrush index independently', () {
      controller.setActiveBrush(BrushType.airbrush);
      controller.setActiveTheme(4);
      expect(controller.activeThemeIndex, 4);

      // switching to pattern should show its own index (still 0)
      controller.setActiveBrush(BrushType.pattern);
      expect(controller.activeThemeIndex, 0);

      // switching back to airbrush restores 4
      controller.setActiveBrush(BrushType.airbrush);
      expect(controller.activeThemeIndex, 4);
    });

    test('setActiveTheme updates pattern index independently', () {
      controller.setActiveBrush(BrushType.pattern);
      controller.setActiveTheme(7);

      controller.setActiveBrush(BrushType.airbrush);
      controller.setActiveTheme(2);

      controller.setActiveBrush(BrushType.pattern);
      expect(controller.activeThemeIndex, 7);
    });

    test('startStroke sets themeIndex for airbrush', () {
      controller.setActiveBrush(BrushType.airbrush);
      controller.setActiveTheme(3);
      controller.startStroke(BrushType.airbrush, Colors.red, const Offset(0, 0));
      expect(controller.currentStroke!.themeIndex, 3);
    });

    test('startStroke sets null themeIndex for pencil', () {
      controller.setActiveBrush(BrushType.pencil);
      controller.startStroke(BrushType.pencil, Colors.red, const Offset(0, 0));
      expect(controller.currentStroke!.themeIndex, isNull);
    });

    test('startStroke sets null themeIndex for splatter', () {
      controller.setActiveBrush(BrushType.splatter);
      controller.startStroke(BrushType.splatter, Colors.red, const Offset(0, 0));
      expect(controller.currentStroke!.themeIndex, isNull);
    });

    test('setActiveTheme notifies listeners', () {
      controller.setActiveBrush(BrushType.airbrush);
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setActiveTheme(5);
      expect(notified, isTrue);
    });
  });
}
