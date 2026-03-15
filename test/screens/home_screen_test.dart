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
}
