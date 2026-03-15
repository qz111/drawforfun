import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/home_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('home_screen_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('HomeScreen shows app bar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🎨 Draw For Fun'), findsOneWidget);
  });

  testWidgets('HomeScreen shows Built-in Templates section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('🐾 Built-in Templates'), findsOneWidget);
  });

  testWidgets('HomeScreen shows My Uploads section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('📷 My Uploads'), findsOneWidget);
  });

  testWidgets('HomeScreen shows Upload button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('HomeScreen Templates header has + import button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
  });

  testWidgets('HomeScreen shows raw import card in Templates grid', (tester) async {
    // Pre-create a rawimport directory so it appears in the grid
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    // Write minimal valid PNG header bytes so Image.file doesn't crash
    File('${rawDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    // The raw import label 'Photo 03/15' should appear in the Templates grid
    expect(find.text('Photo 03/15'), findsOneWidget);
  });

  testWidgets('delete icon absent on built-in template cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    // Built-in template cards must never show a delete icon
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('delete icon present on rawImport card in Templates grid',
      (tester) async {
    final rawDir = Directory('${tempDir.path}/rawimport_20260315_143000')
      ..createSync(recursive: true);
    File('${rawDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('delete icon present on upload card in My Uploads', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping delete icon opens confirmation dialog', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    // Scroll to bring the delete icon into the viewport before tapping
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this image?'), findsOneWidget);
  });

  testWidgets('wrong answer in dialog shows error text', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    // Scroll to bring the delete icon into the viewport before tapping
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Enter a deliberately wrong answer (0 is always wrong: sums are 10–30)
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong answer, try again'), findsOneWidget);
    // Dialog stays open
    expect(find.text('Delete this image?'), findsOneWidget);
  });

  testWidgets('correct answer deletes entry and dismisses dialog', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    // Scroll to bring the delete icon into the viewport before tapping
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Parse the math question from the dialog to get the correct answer.
    // Scan all Text widgets and find the one whose data starts with 'What is'.
    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    final questionWidget = texts.firstWhere(
      (t) => (t.data ?? '').startsWith('What is'),
    );
    // Extract A and B from 'What is A + B?'
    final match = RegExp(r'What is (\d+) \+ (\d+)').firstMatch(questionWidget.data!);
    final a = int.parse(match!.group(1)!);
    final b = int.parse(match.group(2)!);

    await tester.enterText(find.byType(TextField), '${a + b}');
    // runAsync lets real file I/O (Directory.delete) complete while the widget
    // tree is live. We tap inside and poll until the directory is gone, which
    // guarantees _onDelete ran fully (deleteEntry + onConfirmed + Navigator.pop).
    await tester.runAsync(() async {
      await tester.tap(find.text('Delete'));
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (uploadDir.existsSync() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    // The dialog's close animation requires two pump() calls with sufficient
    // duration: the first starts the exit animation, the second completes it.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog dismissed
    expect(find.text('Delete this image?'), findsNothing);
    // Upload directory deleted
    expect(uploadDir.existsSync(), isFalse);
  });
}
