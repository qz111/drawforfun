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
    // One frame to render the splash (video init is async; static icon shows first).
    await tester.pump();

    // Title and tagline are always visible regardless of video state.
    expect(find.text('Magical Coloring\nWorld'), findsOneWidget);
    expect(find.text('Draw  \u2022  Color  \u2022  Dream'), findsOneWidget);

    // Drain the 8-second safety-timeout timer so no pending timers remain
    // when the test ends (leaving pending timers is a test framework error).
    await tester.pump(const Duration(seconds: 9));
    await tester.pump(); // settle the cross-fade frame
  });

  testWidgets('SplashScreen navigates to MainMenuScreen after safety timeout',
      (tester) async {
    await tester.pumpWidget(const DrawForFunApp());
    await tester.pump(); // initial frame

    // In tests the video asset is unavailable, so the 8 s safety timeout fires.
    // Advance past timeout + 500 ms cross-fade.
    await tester.pump(const Duration(milliseconds: 8600));

    // MagicalSkyBackground has a repeating AnimationController that never
    // settles, so use pump() rather than pumpAndSettle().
    await tester.pump();

    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('My Uploads'), findsOneWidget);
  });
}
