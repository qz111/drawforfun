import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_theme.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/theme_picker_widget.dart';

void main() {
  group('ThemePickerWidget', () {
    testWidgets('shows label for airbrush theme 0', (tester) async {
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
      expect(find.text(BrushTheme.airbrushThemes[0].label), findsOneWidget);
    });

    testWidgets('shows label for pattern style 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: ThemePickerWidget(
                brushType: BrushType.pattern,
                selectedIndex: 0,
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text(BrushTheme.patternStyles[0].label), findsOneWidget);
    });

    testWidgets('calls onThemeSelected when item tapped', (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: ThemePickerWidget(
                brushType: BrushType.airbrush,
                selectedIndex: 0,
                onThemeSelected: (i) => selected = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(BrushTheme.airbrushThemes[0].label));
      expect(selected, 0);
    });
  });
}
