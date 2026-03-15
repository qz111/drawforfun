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

  testWidgets('App launches and shows HomeScreen', (tester) async {
    await tester.pumpWidget(const DrawForFunApp());
    await tester.pumpAndSettle();
    expect(find.text('🎨 Draw For Fun'), findsOneWidget);
    expect(find.text('🐾 Built-in Templates'), findsOneWidget);
    expect(find.text('📷 My Uploads'), findsOneWidget);
  });
}
