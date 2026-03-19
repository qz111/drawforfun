import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/theme/app_theme.dart';
import 'package:drawforfun/widgets/eraser_size_picker_widget.dart';

void main() {
  group('EraserSizePickerWidget', () {
    testWidgets('shows all three size labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: EraserSizePickerWidget(
                selectedIndex: 1,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('calls onSizeSelected with correct index when tapped', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: EraserSizePickerWidget(
                selectedIndex: 1,
                onSizeSelected: (i) => tapped = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('S'));
      expect(tapped, 0);

      await tester.tap(find.text('L'));
      expect(tapped, 2);
    });

    testWidgets('selected tile shows deepPurple highlight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: EraserSizePickerWidget(
                selectedIndex: 0,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // The 'S' tile should be selected — find its container with accentPrimary highlight.
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('S'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.accentPrimary.withValues(alpha: 0.12));
    });

    testWidgets('vertical axis shows tiles in a vertical list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 300,
              child: EraserSizePickerWidget(
                axis: Axis.vertical,
                selectedIndex: 0,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // A vertical SingleChildScrollView (or ListView) must be present.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // All labels still render.
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('vertical axis tile height is 64', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 72,
              height: 300,
              child: EraserSizePickerWidget(
                axis: Axis.vertical,
                selectedIndex: 0,
                onSizeSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('S'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      expect(container.constraints?.maxHeight, 64.0);
    });
  });
}
