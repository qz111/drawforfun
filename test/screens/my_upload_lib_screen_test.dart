import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/my_upload_lib_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('my_upload_lib_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('MyUploadLibScreen shows AppBar title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('📷 My Uploads'), findsOneWidget);
  });

  testWidgets('MyUploadLibScreen shows Upload button in AppBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('+ Upload'), findsOneWidget);
  });

  testWidgets('empty state renders without error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing); // no ListView when empty
    expect(find.text('No uploads yet.\nTap + Upload to add a photo.'), findsOneWidget);
  });

  testWidgets('upload card appears with delete icon', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Photo 03/15'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('tapping delete icon opens confirmation dialog', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this image?'), findsOneWidget);
  });

  testWidgets('correct answer deletes entry and dismisses dialog', (tester) async {
    final uploadDir = Directory('${tempDir.path}/upload_20260315_120000')
      ..createSync(recursive: true);
    File('${uploadDir.path}/overlay.png')
        .writeAsBytesSync([137, 80, 78, 71, 13, 10, 26, 10]);

    await tester.pumpWidget(const MaterialApp(home: MyUploadLibScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    final questionWidget =
        texts.firstWhere((t) => (t.data ?? '').startsWith('What is'));
    final match =
        RegExp(r'What is (\d+) \+ (\d+)').firstMatch(questionWidget.data!);
    final a = int.parse(match!.group(1)!);
    final b = int.parse(match.group(2)!);

    await tester.enterText(find.byType(TextField), '${a + b}');
    await tester.tap(find.text('Delete'));
    // In test mode DrawingRepository.deleteEntry() is synchronous, so one
    // pump() is enough to process the tap, run _onDelete to completion, and
    // call Navigator.pop().
    await tester.pump();
    // pumpAndSettle is avoided because the autofocus TextField's cursor-blink
    // timer prevents settling indefinitely. Pump enough to complete the dialog
    // exit route animation (~300 ms for Material PopupRoute).
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Delete this image?'), findsNothing);
    expect(uploadDir.existsSync(), isFalse);
  });
}
