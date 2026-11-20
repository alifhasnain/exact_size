import 'package:es_codec/es_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-004-T07: the bundled native code's licences reach the licence page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(registerEsCodecLicenses);

  test('registry holds the libjpeg-turbo, libspng and zlib texts', () async {
    final entries = await LicenseRegistry.licenses.toList();
    String textOf(String pkg) => entries
        .where((e) => e.packages.contains(pkg))
        .expand((e) => e.paragraphs.map((p) => p.text))
        .join('\n');
    expect(textOf('libjpeg-turbo'), allOf(
      contains("Independent JPEG Group"), // IJG licence (README.ijg)
      contains('Redistribution and use in source and binary forms'), // Modified BSD
    ));
    expect(textOf('libspng (bundled with libjpeg-turbo)'), contains('BSD 2-Clause License'));
    expect(textOf('zlib (bundled with libjpeg-turbo)'), contains('Jean-loup Gailly and Mark Adler'));
  });

  testWidgets('licence page lists libjpeg-turbo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LicensePage()));
    // The page parses licences off the UI thread (real async), so let real
    // time pass instead of pumpAndSettle, which never settles on the spinner.
    final list = find.byType(Scrollable).last;
    for (var i = 0; i < 100 && find.byType(Scrollable).evaluate().length < 2; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.scrollUntilVisible(find.text('libjpeg-turbo'), 300, scrollable: list);
    expect(find.text('libjpeg-turbo'), findsOneWidget);
  });
}
