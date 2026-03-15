import 'package:flutter_test/flutter_test.dart';

import 'package:drawforfun/app.dart';

void main() {
  testWidgets('App launches and shows Draw For Fun title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DrawForFunApp());

    // Verify the app title is displayed in the app bar.
    expect(find.text('Draw For Fun'), findsOneWidget);
  });
}
