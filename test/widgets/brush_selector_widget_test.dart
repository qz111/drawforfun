import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/theme/app_theme.dart';
import 'package:drawforfun/widgets/brush_selector_widget.dart';

void main() {
  group('BrushSelectorWidget', () {
    testWidgets('shows a button for every BrushType including eraser', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrushSelectorWidget(
              selectedBrush: BrushType.pencil,
              onBrushSelected: (_) {},
            ),
          ),
        ),
      );
      // Every BrushType must have a label — missing entry crashes with null assertion.
      expect(find.text('Pencil'), findsOneWidget);
      expect(find.text('Marker'), findsOneWidget);
      expect(find.text('Air'),    findsOneWidget);
      expect(find.text('Stars'),  findsOneWidget);
      expect(find.text('Splat'),  findsOneWidget);
      expect(find.text('Erase'),  findsOneWidget); // eraser
    });

    testWidgets('calls onBrushSelected with eraser when eraser tapped', (tester) async {
      BrushType? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrushSelectorWidget(
              selectedBrush: BrushType.pencil,
              onBrushSelected: (t) => selected = t,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Erase'));
      expect(selected, BrushType.eraser);
    });

    testWidgets('eraser button shows selected highlight when active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrushSelectorWidget(
              selectedBrush: BrushType.eraser,
              onBrushSelected: (_) {},
            ),
          ),
        ),
      );
      // The 'Erase' tile container should carry accentPrimary highlight.
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('Erase'),
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.accentPrimary.withValues(alpha: 0.12));
    });
  });
}
