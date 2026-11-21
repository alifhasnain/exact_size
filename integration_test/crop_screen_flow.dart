import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/compression/data/native_pixel_buffer.dart';
import 'package:exact_size/features/compression/domain/pixel_buffer.dart';
import 'package:exact_size/features/crop/data/preview_decoder.dart';
import 'package:exact_size/features/crop/data/source_handle.dart';
import 'package:exact_size/features/crop/data/source_probe.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/crop/presentation/crop_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-002-T25: the crop screen's Continue runs the real CropRenderer on a
/// fixture and hands off exactly W×H. Run through crop_data_matrix.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Continue renders the fixture and hands off W×H', (tester) async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/fixtures');
    final h = SourceHandle(File('${dir.path}/orient_6_exif.jpg').uri.toString());
    final info = ((await const SourceProbe().probe(h)) as ProbeOk).info;
    final preview = (await const PreviewDecoder().decode(h, info) as PreviewOk).image;
    PixelBuffer? got;
    await tester.pumpWidget(ProviderScope(
      child: ExactSizeApp(
        locale: const Locale('en'),
        home: CropScreen(src: h, preview: preview, info: info, target: const Target(97, 61), onContinue: (p) => got = p, onChooseAnother: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    for (var i = 0; i < 100 && got == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect((got?.width, got?.height), (97, 61));
    (got! as NativePixelBuffer).free();
    preview.dispose();
  });
}
