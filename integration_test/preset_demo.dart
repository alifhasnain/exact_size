import 'dart:convert';
import 'dart:io';

import 'package:exact_size/app.dart';
import 'package:exact_size/features/crop/domain/crop_types.dart';
import 'package:exact_size/features/presets/data/preset_asset_source.dart';
import 'package:exact_size/features/presets/domain/parse_library.dart';
import 'package:exact_size/features/presets/domain/preset_types.dart';
import 'package:exact_size/features/presets/presentation/preset_list_screen.dart';
import 'package:exact_size/features/presets/presentation/preset_providers.dart';
import 'package:exact_size/features/target/domain/target_input.dart';
import 'package:exact_size/features/target/presentation/target_form_controller.dart';
import 'package:exact_size/features/target/presentation/target_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'preset_fixture_data.dart';

/// FEAT-011-T12 gate G2 review (manual, not in CI): the preset row and list in each state, for one
/// Realme 2 Pro screenshot each. Build with `-t integration_test/preset_demo.dart`; pick the state by
/// writing its name to `files/demo_state` with `adb shell run-as`, then restart the activity.
/// States: choose, applied, loadfail, list, nomatch, arabic (list in ar), font200 (list at 200%).
/// The synthetic Test Form A/B library is served in place of the shipped asset, which stays as it
/// is; no photo is opened (synthetic 4000×3000 size only).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final f = File('${(await getApplicationSupportDirectory()).path}/demo_state');
  final name = f.existsSync() ? f.readAsStringSync().trim() : 'choose';
  final library = jsonEncode(presetFixtureLibrary);
  final c = ProviderContainer(
    overrides: [
      presetSourceProvider.overrideWithValue(
        PresetAssetSource(bundle: _Bundle(name == 'loadfail' ? '{"schema": 1, "forms": [' : library)),
      ),
    ],
  );
  if (name == 'applied') {
    final spec = parseLibrary(presetFixtureLibrary).forms.first.specs.first;
    c.read(targetFormProvider.notifier).fill(spec.applyTo(const TargetInput()));
    c.read(appliedPresetProvider.notifier).apply(const AppliedPreset(formId: 'test-form-a', kind: SpecKind.photo));
  }
  final forms = parseLibrary(presetFixtureLibrary).forms;
  final onList = {'list', 'nomatch', 'arabic', 'font200'}.contains(name);
  runApp(
    UncontrolledProviderScope(
      container: c,
      child: ExactSizeApp(
        locale: name == 'arabic' ? const Locale('ar') : const Locale('en'),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(name == 'font200' ? 2 : 1)),
            child: onList
                ? _Typing(
                    query: name == 'nomatch' ? 'zzzz' : null,
                    child: PresetListScreen(forms: forms),
                  )
                : TargetScreen(
                    info: const SourceInfo(
                      rawWidth: 4000,
                      rawHeight: 3000,
                      mime: 'image/jpeg',
                      exifOrientation: 1,
                      isAnimated: false,
                      hasAlpha: false,
                      decodePath: DecodePath.region,
                    ),
                    onContinue: (_) {},
                  ),
          ),
        ),
      ),
    ),
  );
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(utf8.encode(text));
}

/// Types [query] into the search field after the first frame, as a user would (demo only).
class _Typing extends StatefulWidget {
  const _Typing({required this.query, required this.child});
  final String? query;
  final Widget child;

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Future<void>.delayed(const Duration(milliseconds: 300), _type));
  }

  void _type() {
    final q = widget.query;
    if (q == null || !mounted) return;
    void visit(Element e) {
      if (e.widget case final TextField field) {
        field.controller!.text = q;
        field.onChanged!(q);
        return;
      }
      e.visitChildElements(visit);
    }

    context.visitChildElements(visit);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
