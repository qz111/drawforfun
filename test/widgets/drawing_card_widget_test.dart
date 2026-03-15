import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_entry.dart';
import 'package:drawforfun/widgets/drawing_card_widget.dart';

void main() {
  const templateEntry = DrawingEntry(
    id: 'cat',
    type: DrawingType.template,
    overlayAssetPath: 'assets/line_art/cat.svg',
    directoryPath: '/tmp/cat',
  );
  const uploadEntry = DrawingEntry(
    id: 'upload_20260315_120000',
    type: DrawingType.upload,
    overlayFilePath: '/tmp/upload_20260315_120000/overlay.png',
    directoryPath: '/tmp/upload_20260315_120000',
  );
  const rawImportEntry = DrawingEntry(
    id: 'rawimport_20260315_143000',
    type: DrawingType.rawImport,
    overlayFilePath: '/tmp/rawimport_20260315_143000/overlay.png',
    directoryPath: '/tmp/rawimport_20260315_143000',
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('DrawingCardWidget delete icon', () {
    testWidgets('no delete icon when onDelete is null (template)', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: templateEntry,
            label: 'Cat',
            emoji: '🐱',
            hasThumbnail: false,
            onTap: () {},
            // onDelete not provided → defaults to null
          ),
        ),
      ));
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('shows delete icon when onDelete is provided (upload)', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: uploadEntry,
            label: 'Photo 03/15',
            hasThumbnail: false,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows delete icon when onDelete is provided (rawImport)', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: rawImportEntry,
            label: 'Photo 03/15',
            hasThumbnail: false,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tapping delete icon calls onDelete, not onTap', (tester) async {
      var tapCount = 0;
      var deleteTapCount = 0;
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 100,
          height: 130,
          child: DrawingCardWidget(
            entry: uploadEntry,
            label: 'Photo 03/15',
            hasThumbnail: false,
            onTap: () => tapCount++,
            onDelete: () => deleteTapCount++,
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      expect(deleteTapCount, 1);
      expect(tapCount, 0);
    });
  });
}
