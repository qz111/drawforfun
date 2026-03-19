import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/brushes/brush_type.dart';
import 'package:drawforfun/widgets/brush_rail_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BrushRailWidget', () {
    testWidgets('renders an icon for every BrushType', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.pencil,
            isStripOpen: false,
            onBrushSelected: (_) {},
            onToggleStrip: () {},
          ),
        ),
      ));
      // 6 icon tiles — one per BrushType.
      expect(find.byType(Icon), findsNWidgets(BrushType.values.length));
    });

    testWidgets('tapping a different brush calls onBrushSelected with that type', (tester) async {
      BrushType? selected;
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.pencil,
            isStripOpen: false,
            onBrushSelected: (t) => selected = t,
            onToggleStrip: () {},
          ),
        ),
      ));
      // Tap the eraser icon (last in column).
      await tester.tap(find.byIcon(Icons.auto_fix_normal));
      expect(selected, BrushType.eraser);
    });

    testWidgets('tapping the selected brush calls onToggleStrip', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.pencil,
            isStripOpen: false,
            onBrushSelected: (_) {},
            onToggleStrip: () => toggled = true,
          ),
        ),
      ));
      // Pencil is the selected brush — tapping it should toggle strip.
      await tester.tap(find.byIcon(Icons.edit));
      expect(toggled, isTrue);
    });

    testWidgets('selected brush icon uses accent color', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 64,
          height: 600,
          child: BrushRailWidget(
            selectedBrush: BrushType.marker,
            isStripOpen: false,
            onBrushSelected: (_) {},
            onToggleStrip: () {},
          ),
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.brush));
      expect(icon.color, isNotNull);
      // Color should differ from unselected (accent vs muted grey) — just check non-null.
      expect(icon.color, isNot(equals(Colors.grey)));
    });
  });
}
