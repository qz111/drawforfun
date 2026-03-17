import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/screens/main_menu_screen.dart';

void main() {
  testWidgets('MainMenuScreen shows app title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.text('🎨 Draw For Fun'), findsOneWidget);
  });

  testWidgets('MainMenuScreen shows Templates card', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.text('Templates'), findsOneWidget);
  });

  testWidgets('MainMenuScreen shows My Uploads card', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.text('My Uploads'), findsOneWidget);
  });

  testWidgets('MainMenuScreen has no AppBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    expect(find.byType(AppBar), findsNothing);
  });
}
