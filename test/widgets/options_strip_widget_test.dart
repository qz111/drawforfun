import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/canvas/canvas_controller.dart';
import 'package:drawforfun/palette/palette_widget.dart';
import 'package:drawforfun/widgets/eraser_size_picker_widget.dart';
import 'package:drawforfun/widgets/options_strip_widget.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

CanvasController _controller() => CanvasController();

void main() {
  group('OptionsStripWidget', () {
    testWidgets('when not visible, strip is wrapped in IgnorePointer(ignoring: true)', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: false,
          activeBrush: BrushType.pencil,
          controller: ctrl,
        ),
      )));
      final ip = tester.widget<IgnorePointer>(
          find.byKey(const ValueKey('options_strip_ignore_pointer')));
      expect(ip.ignoring, isTrue);
    });

    testWidgets('when visible, IgnorePointer is not ignoring', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.pencil,
          controller: ctrl,
        ),
      )));
      final ip = tester.widget<IgnorePointer>(
          find.byKey(const ValueKey('options_strip_ignore_pointer')));
      expect(ip.ignoring, isFalse);
    });

    testWidgets('pencil brush shows PaletteWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.pencil,
          controller: ctrl,
        ),
      )));
      await tester.pump(); // settle animation
      expect(find.byType(PaletteWidget), findsOneWidget);
    });

    testWidgets('eraser brush shows EraserSizePickerWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.eraser,
          controller: ctrl,
        ),
      )));
      await tester.pump();
      expect(find.byType(EraserSizePickerWidget), findsOneWidget);
    });

    testWidgets('airbrush shows ThemePickerWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.airbrush,
          controller: ctrl,
        ),
      )));
      await tester.pump();
      expect(find.byType(ThemePickerWidget), findsOneWidget);
    });

    testWidgets('pattern brush also shows ThemePickerWidget', (tester) async {
      final ctrl = _controller();
      await tester.pumpWidget(_wrap(SizedBox(
        width: 72,
        height: 600,
        child: OptionsStripWidget(
          isVisible: true,
          activeBrush: BrushType.pattern,
          controller: ctrl,
        ),
      )));
      await tester.pump();
      expect(find.byType(ThemePickerWidget), findsOneWidget);
    });
  });
}
