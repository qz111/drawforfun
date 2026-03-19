import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/template_lib_screen.dart';
import 'package:drawforfun/widgets/polaroid_card_widget.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('template_lib_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('TemplateLibScreen shows AppBar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🐾 Templates'), findsOneWidget);
  });

  testWidgets('TemplateLibScreen shows Upload button in AppBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('+ Upload'), findsOneWidget);
  });

  testWidgets('TemplateLibScreen shows built-in template cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    // AnimalTemplates.all contains at least one template — check any renders
    expect(find.byType(ListView), findsAtLeastNWidgets(1));
  });

  testWidgets('delete icon absent on built-in template cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('rawImport card appears and shows delete icon', (tester) async {
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    File('${rawDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    // Built-in templates come first; scroll the horizontal list until the
    // rawImport card is built and visible.
    await tester.scrollUntilVisible(
      find.text('Photo 03/15'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Photo 03/15'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping delete icon opens confirmation dialog', (tester) async {
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    File('${rawDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    // Built-in templates come first; scroll until the delete icon is reachable.
    await tester.scrollUntilVisible(
      find.byIcon(Icons.delete_outline),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this image?'), findsOneWidget);
  });

  testWidgets('Create Blank Canvas card appears in main carousel',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Create Blank Canvas'), findsOneWidget);
  });

  testWidgets('My Templates section hidden when no custom templates',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('My Templates'), findsNothing);
  });

  testWidgets('My Templates section appears when custom template exists',
      (tester) async {
    final customDir =
        Directory('${tempDir.path}/custom_20260317_120000_042')
          ..createSync(recursive: true);
    File('${customDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('My Templates'), findsOneWidget);
  });

  testWidgets('long press on built-in template card shows bottom sheet',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    // Long-press the first PolaroidCardWidget (a built-in template)
    await tester.longPress(find.byType(PolaroidCardWidget).first);
    await tester.pumpAndSettle();
    expect(find.text('Color it!'), findsOneWidget);
    expect(find.text('Remix it'), findsOneWidget);
  });

  testWidgets('tapping Color it! in bottom sheet dismisses sheet',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TemplateLibScreen()));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(PolaroidCardWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Color it!'));
    await tester.pumpAndSettle();
    expect(find.text('Color it!'), findsNothing);
  });
}
