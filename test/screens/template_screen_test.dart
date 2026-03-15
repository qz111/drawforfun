import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawforfun/templates/animal_template.dart';
import 'package:drawforfun/templates/animal_templates.dart';
import 'package:drawforfun/screens/template_screen.dart';

/// Fake asset bundle that returns minimal valid SVG bytes for every key.
/// SvgPicture.asset calls DefaultAssetBundle.of(context).load(path) at runtime.
/// In widget tests the default bundle is empty, so without this fake every
/// SvgPicture.asset call would throw "Unable to load asset", crashing the test.
class _FakeAssetBundle extends AssetBundle {
  static const _minimalSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400"></svg>';

  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(utf8.encode(_minimalSvg)).buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _minimalSvg;
}

void main() {
  group('TemplateScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: const MaterialApp(home: TemplateScreen()),
        ),
      );
      expect(find.text('Choose an Animal'), findsOneWidget);
    });

    testWidgets('renders a card for every template', (tester) async {
      expect(AnimalTemplates.all.length, 25); // guard: fails loudly if list is empty
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: const MaterialApp(home: TemplateScreen()),
        ),
      );
      await tester.pump(); // allow grid to lay out

      for (final t in AnimalTemplates.all) {
        expect(find.text(t.name), findsOneWidget);
      }
    });

    testWidgets('tapping a card pops with the selected template', (tester) async {
      AnimalTemplate? result;
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Builder(builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<AnimalTemplate>(
                  ctx,
                  MaterialPageRoute(builder: (_) => const TemplateScreen()),
                );
              },
              child: const Text('open'),
            )),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap the first card (Cat)
      await tester.tap(find.text('Cat'));
      await tester.pumpAndSettle();

      expect(result, equals(AnimalTemplates.all.first));
    });

    testWidgets('back button returns null', (tester) async {
      AnimalTemplate? result = const AnimalTemplate(
        id: 'sentinel', name: 'Sentinel', emoji: '?', assetPath: 'x',
      );
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FakeAssetBundle(),
          child: MaterialApp(
            home: Builder(builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<AnimalTemplate>(
                  ctx,
                  MaterialPageRoute(builder: (_) => const TemplateScreen()),
                );
              },
              child: const Text('open'),
            )),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
