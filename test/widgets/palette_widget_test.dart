import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/palette/palette_widget.dart';
import 'package:drawforfun/palette/color_palette.dart';

void main() {
  group('PaletteWidget', () {
    testWidgets('horizontal default uses Wrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaletteWidget(
              selectedColor: Colors.red,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('vertical axis uses ListView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: PaletteWidget(
                axis: Axis.vertical,
                selectedColor: Colors.red,
                onColorSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('vertical axis shows exactly 24 swatches', (tester) async {
      // Expand the test surface so all 24 items fit in the ListView viewport.
      // 24 items × (44px height + 8px separator) + 16px padding = ~1264px.
      tester.view.physicalSize = const Size(72, 1300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaletteWidget(
              axis: Axis.vertical,
              selectedColor: Colors.red,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );
      // One GestureDetector per swatch (eraser sentinel excluded).
      expect(
        find.byType(GestureDetector),
        findsNWidgets(ColorPalette.swatches.length),
      );
    });

    testWidgets('calls onColorSelected when a swatch is tapped', (tester) async {
      Color? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: PaletteWidget(
                axis: Axis.vertical,
                selectedColor: Colors.red,
                onColorSelected: (c) => picked = c,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      expect(picked, isNotNull);
    });
  });
}
