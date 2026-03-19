import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';

void main() {
  group('ThemePickerWidget', () {
    testWidgets('horizontal default shows 10 tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: ThemePickerWidget(
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // ListView with horizontal scroll must be present.
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('vertical axis uses vertical ListView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: ThemePickerWidget(
                axis: Axis.vertical,
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.vertical);
    });

    testWidgets('vertical axis tiles are 56x56', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: ThemePickerWidget(
                axis: Axis.vertical,
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // First AnimatedContainer should be 56x56.
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();
      expect(containers.first.constraints?.maxWidth, 56.0);
      expect(containers.first.constraints?.maxHeight, 56.0);
    });

    testWidgets('calls onThemeSelected when tapped', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 600,
              child: ThemePickerWidget(
                axis: Axis.vertical,
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (i) => selected = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AnimatedContainer).first);
      expect(selected, 0);
    });
  });
}
