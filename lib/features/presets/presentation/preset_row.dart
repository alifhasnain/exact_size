import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../../target/presentation/target_form_controller.dart';
import '../domain/preset_types.dart';
import 'preset_list_screen.dart';
import 'preset_providers.dart';
import 'preset_strings.dart';

/// FEAT-011 target-step row (FR-5, FR-11..FR-14, FR-16; G1 design, t09/preset_design.md), in the
/// slot FEAT-005 reserved below the photo line. It draws nothing while the library loads or holds
/// no form (OQ-T1), a notice when it failed to load, and otherwise the outlined "Choose a form"
/// key, which reads "form · kind" with the spec's notes while the five values equal the picked spec.
/// It brings its own top gap, so a hidden row leaves the screen exactly as FEAT-005 drew it.
class PresetRow extends ConsumerWidget {
  const PresetRow({super.key, required this.onFilled});

  /// Called after a pick filled the form, so the screen copies the values into its text fields.
  final VoidCallback onFilled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final library = ref.watch(presetLibraryProvider);
    if (library case AsyncError()) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: BoothNotice(icon: Icons.info_outline, text: l.presetLoadFailed),
      );
    }
    final forms = library.value?.forms ?? const <PresetForm>[];
    if (forms.isEmpty) return const SizedBox.shrink();

    final s = PresetStrings(l);
    final (form, spec) = _applied(ref, forms);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Semantics(
              button: true,
              child: Material(
                type: MaterialType.transparency,
                shape: presetKeyShape,
                child: InkWell(
                  customBorder: presetKeyShape,
                  onTap: () => _choose(context, ref, forms, s),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        spacing: 12,
                        children: [
                          const ExcludeSemantics(child: Icon(Icons.list_alt, size: 20, color: Booth.text)),
                          Expanded(
                            child: Text(
                              form == null ? l.presetChooseForm : s.applied(form, spec!.kind),
                              style: text.titleMedium?.copyWith(color: Booth.text),
                            ),
                          ),
                          // chevron_right mirrors in right-to-left layouts.
                          const ExcludeSemantics(child: Icon(Icons.chevron_right, color: Booth.text)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (form != null && spec != null) ...[
            const SizedBox(height: 12),
            // FR-26: a KB-only form states no pixel size; ask for one first. Never propose a size.
            if (spec.kbOnly) BoothNotice(icon: Icons.info_outline, text: l.presetKbOnlyNote),
            for (final note in spec.notCovered) BoothNotice(icon: Icons.info_outline, text: s.note(note)),
            // FEAT-014 FR-1: where the sizes come from, last, after the notes (t05/source_design.md).
            // Plain text: no tap, link or selection (FR-8). The clock is read on every build (FR-7).
            BoothNotice(icon: Icons.history, text: s.block(form, ref.watch(presetClockProvider)())),
          ],
        ],
      ),
    );
  }

  /// The picked form and spec while the five values still equal it (FR-13), else (null, null).
  (PresetForm?, PresetSpec?) _applied(WidgetRef ref, List<PresetForm> forms) {
    final picked = ref.watch(appliedPresetProvider);
    final input = ref.watch(targetFormProvider).input;
    if (picked == null) return (null, null);
    for (final f in forms) {
      if (f.id != picked.formId) continue;
      for (final spec in f.specs) {
        if (spec.kind == picked.kind && spec.matches(input)) return (f, spec);
      }
    }
    return (null, null);
  }

  Future<void> _choose(BuildContext context, WidgetRef ref, List<PresetForm> forms, PresetStrings s) async {
    final pick = await PresetListScreen.open(context, forms);
    if (pick == null || !context.mounted) return; // Back: values unchanged (AC-1.4)
    final form = forms.firstWhere((f) => f.id == pick.formId);
    final spec = form.specs.firstWhere((x) => x.kind == pick.kind);
    ref.read(targetFormProvider.notifier).fill(spec.applyTo(ref.read(targetFormProvider).input));
    ref.read(appliedPresetProvider.notifier).apply(AppliedPreset(formId: form.id, kind: spec.kind));
    onFilled();
    FocusManager.instance.primaryFocus?.unfocus(); // AC-4.1: keyboard closed
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        spec.kbOnly
            ? '${s.applied(form, spec.kind)}\n${AppLocalizations.of(context).presetKbOnlyNote}'
            : s.applied(form, spec.kind),
        Directionality.of(context),
      ),
    );
  }
}
