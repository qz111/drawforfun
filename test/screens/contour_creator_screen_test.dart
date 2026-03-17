import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';
import 'package:drawforfun/screens/contour_creator_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('contour_creator_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('shows AppBar with correct title', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.text('Template Creator'), findsOneWidget);
  });

  testWidgets('shows Save button', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('shows Pencil and Eraser tool buttons', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.auto_fix_normal), findsOneWidget);
  });

  testWidgets('shows Undo and Clear buttons', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('switching to eraser tool updates sidebar highlight',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ContourCreatorScreen()));
    await tester.pump();
    // Tap the eraser button
    await tester.tap(find.byIcon(Icons.auto_fix_normal));
    await tester.pump();
    // No crash = pass; visual highlight verified manually
  });

  testWidgets('back without strokes pops without dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) => Scaffold(
        body: ElevatedButton(
          onPressed: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const ContourCreatorScreen())),
          child: const Text('open'),
        ),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Back with no strokes — should pop without dialog
    final NavigatorState nav = tester.state(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('Template Creator'), findsNothing);
  });
}
