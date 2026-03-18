import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      // The 'S' tile should be selected — find its container with deepPurple background.
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('S'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.deepPurple.shade100);
    });
  });
}
