import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/app.dart';
import 'package:drawforfun/persistence/drawing_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('widget_test_');
    DrawingRepository.setTestDirectory(tempDir);
  });

  tearDown(() {
    DrawingRepository.setTestDirectory(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('App shows SplashScreen on launch', (tester) async {
    await tester.pumpWidget(const DrawForFunApp());
    // One frame to kick off the fade-in animation and render the splash.
    await tester.pump();

    // Title is split across two lines in the Text widget.
    expect(find.text('Magical Coloring\nWorld'), findsOneWidget);
    expect(find.text('Draw  \u2022  Color  \u2022  Dream'), findsOneWidget);

    // Drain the 3-second navigator timer so no pending timers remain when the
    // test ends (leaving pending timers is a test framework error).
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(); // settle the cross-fade frame
  });

  testWidgets('SplashScreen navigates to MainMenuScreen after 3 s', (tester) async {
    await tester.pumpWidget(const DrawForFunApp());
    await tester.pump(); // initial frame

    // Advance past the 3-second delay + the 500 ms cross-fade.
    await tester.pump(const Duration(milliseconds: 3600));

    // MagicalSkyBackground has a repeating AnimationController that never
    // settles, so use pump() rather than pumpAndSettle().
    await tester.pump();

    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('My Uploads'), findsOneWidget);
  });
}
