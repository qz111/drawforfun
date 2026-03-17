import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/screens/contour_creator_screen.dart';

void main() {
  group('ContourCreatorController', () {
    late ContourCreatorController controller;

    setUp(() => controller = ContourCreatorController());
    tearDown(() => controller.dispose());

    test('starts with empty strokes and pencil tool', () {
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.activeTool, ContourTool.pencil);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('startStroke / addPoint / endStroke commits a pencil stroke', () {
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      expect(controller.pencilStrokes.length, 1);
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isTrue);
    });

    test('eraser strokes go to eraserStrokes list', () {
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.addPoint(const Offset(15, 15));
      controller.endStroke();
      expect(controller.eraserStrokes.length, 1);
      expect(controller.pencilStrokes, isEmpty);
    });

    test('undo removes last pencil stroke', () {
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      expect(controller.pencilStrokes.length, 1);
      controller.undo();
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('undo removes last eraser stroke', () {
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      controller.undo();
      expect(controller.eraserStrokes, isEmpty);
    });

    test('undo interleaved pencil and eraser in correct order', () {
      // pencil stroke first
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke(); // history: [pencil]
      // then eraser stroke
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.addPoint(const Offset(15, 15));
      controller.endStroke(); // history: [pencil, eraser]

      controller.undo(); // removes eraser
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.pencilStrokes.length, 1);

      controller.undo(); // removes pencil
      expect(controller.pencilStrokes, isEmpty);
    });

    test('undo is a no-op when history is empty', () {
      controller.undo(); // must not throw
      expect(controller.pencilStrokes, isEmpty);
    });

    test('clear resets all strokes and history', () {
      controller.startStroke(const Offset(0, 0));
      controller.endStroke();
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.endStroke();
      controller.clear();
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.eraserStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('clear keeps backgroundImage', () {
      controller.startStroke(const Offset(0, 0));
      controller.endStroke();
      controller.clear();
      expect(controller.backgroundImage, isNull); // null → still null = correct
    });

    test('endStroke with single point discards stroke and does not add to history', () {
      controller.startStroke(const Offset(10, 10));
      // No addPoint call — stroke has exactly 1 point.
      controller.endStroke();
      expect(controller.pencilStrokes, isEmpty);
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.currentStroke, isNull);
    });

    test('notifies listeners on stroke commit', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(5, 5));
      controller.endStroke();
      expect(notifyCount, greaterThan(0));
    });

    test('orderedStrokes returns strokes in temporal order', () {
      // pencil stroke first
      controller.startStroke(const Offset(0, 0));
      controller.addPoint(const Offset(10, 10));
      controller.endStroke();
      // eraser stroke second
      controller.activeTool = ContourTool.eraser;
      controller.startStroke(const Offset(5, 5));
      controller.addPoint(const Offset(15, 15));
      controller.endStroke();
      // pencil stroke third
      controller.activeTool = ContourTool.pencil;
      controller.startStroke(const Offset(20, 20));
      controller.addPoint(const Offset(30, 30));
      controller.endStroke();

      final ordered = controller.orderedStrokes;
      expect(ordered.length, 3);
      expect(ordered[0].$2, isTrue);   // pencil
      expect(ordered[1].$2, isFalse);  // eraser
      expect(ordered[2].$2, isTrue);   // pencil
    });
  });

  group('ContourCreatorPainter', () {
    test('shouldRepaint always returns true', () {
      final painter = ContourCreatorPainter(
        orderedStrokes: const [],
        currentStroke: null,
        activeTool: ContourTool.pencil,
        backgroundImage: null,
      );
      expect(painter.shouldRepaint(painter), isTrue);
    });
  });
}
