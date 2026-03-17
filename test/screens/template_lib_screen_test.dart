import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/template_lib_screen.dart';

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
    expect(find.byType(ListView), findsOneWidget);
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
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this image?'), findsOneWidget);
  });
}
