import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// FEAT-005-T15 gate G2 review (manual, not in CI): the target screen in each
/// state, for one emulator screenshot each. Build with
/// `-t integration_test/target_screen_demo.dart`; pick the state by writing its
/// name to `files/demo_state` with `adb shell run-as`, then restart the
/// activity. States: empty, valid, error, arabic (error state in ar), font200.
/// Synthetic photo size only (4000×3000); no image is opened.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final f = File('${(await getApplicationSupportDirectory()).path}/demo_state');
  final name = f.existsSync() ? f.readAsStringSync().trim() : 'empty';
  final texts = switch (name) {
    'valid' => ['300', '300', '', '100'],
    'error' || 'arabic' => ['1.5', '0', 'x', '1'],
    'font200' => ['300', '', '', ''],
    _ => null,
  };
  runApp(ProviderScope(
    child: ExactSizeApp(
      locale: name == 'arabic' ? const Locale('ar') : const Locale('en'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(name == 'font200' ? 2 : 1)),
          child: _Demo(texts: texts, pressContinue: name == 'error' || name == 'arabic', keyboard: name == 'font200'),
        ),
      ),
    ),
  ));
}

/// Types [texts] into the four fields and optionally presses Continue, as a
/// user would, by walking the element tree after the first frame (demo only).
class _Demo extends StatefulWidget {
  const _Demo({required this.texts, required this.pressContinue, required this.keyboard});
  final List<String>? texts;
  final bool pressContinue;
  final bool keyboard;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Future<void>.delayed(const Duration(milliseconds: 300), _fill));
  }

  void _fill() {
    final texts = widget.texts;
    if (texts == null || !mounted) return;
    final fields = <TextField>[];
    FilledButton? button;
    void visit(Element e) {
      final w = e.widget;
      if (w is TextField) fields.add(w);
      if (w is FilledButton) button = w;
      e.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    for (final (i, field) in fields.indexed) {
      field.controller!.text = texts[i];
      field.onChanged!(texts[i]);
    }
    if (widget.pressContinue) button?.onPressed?.call();
    if (widget.keyboard) fields.first.focusNode!.requestFocus(); // keyboard open
  }

  @override
  Widget build(BuildContext context) => TargetScreen(
        info: const SourceInfo(
            rawWidth: 4000, rawHeight: 3000, mime: 'image/jpeg', exifOrientation: 1, isAnimated: false, hasAlpha: false, decodePath: DecodePath.region),
        onContinue: (_) {},
      );
}
