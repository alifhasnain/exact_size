import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../../compression/domain/compression_result.dart';
import '../../crop/domain/crop_types.dart';
import '../domain/number_text.dart';
import '../domain/target_hints.dart';
import '../domain/target_input.dart';
import '../domain/target_spec.dart';
import 'target_form_controller.dart';
import 'target_messages.dart';

/// The target step (FEAT-005; G1 design t09/target_screen_design.md, the
/// booth "order slip"): width, height, KB range and format for the photo
/// described by [info]. Continue hands a valid [TargetSpec] to [onContinue].
/// Values live in [targetFormProvider] for the session only (FR-10).
class TargetScreen extends ConsumerStatefulWidget {
  const TargetScreen({super.key, required this.info, required this.onContinue});

  /// Only the size and EXIF orientation are read: no pixels, no handle (tech section 7).
  final SourceInfo info;
  final void Function(TargetSpec spec) onContinue;

  /// Number fields in focus (and Next) order: W, H, Min, Max (FR-3, FR-8).
  static const fields = [TargetField.width, TargetField.height, TargetField.minKb, TargetField.maxKb];

  @override
  ConsumerState<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends ConsumerState<TargetScreen> {
  late final Map<TargetField, TextEditingController> _text;
  final _focus = {for (final f in TargetScreen.fields) f: FocusNode()};

  @override
  void initState() {
    super.initState();
    final input = ref.read(targetFormProvider).input;
    _text = {for (final f in TargetScreen.fields) f: TextEditingController(text: input.text(f))};
    for (final f in TargetScreen.fields) {
      _focus[f]!.addListener(() {
        if (!_focus[f]!.hasFocus) _leave(f);
      });
    }
    // A new photo keeps the values and hides old errors (FR-10). Providers may not change during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(targetFormProvider.notifier).startForPhoto();
    });
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final n in _focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  TargetFormController get _form => ref.read(targetFormProvider.notifier);

  /// Shows the cleaned text (FR-4, AC-5.1) and lets the field show its error (FR-7).
  void _clean(TargetField f) {
    final c = _text[f]!;
    final cleaned = cleanNumberText(c.text);
    if (cleaned != c.text) c.value = TextEditingValue(text: cleaned, selection: TextSelection.collapsed(offset: cleaned.length));
    _form.setText(f, cleaned);
  }

  void _leave(TargetField f) {
    if (!mounted) return;
    _clean(f);
    _form.reveal(f);
  }

  void _next(TargetField f) {
    final i = TargetScreen.fields.indexOf(f);
    if (i + 1 < TargetScreen.fields.length) {
      _focus[TargetScreen.fields[i + 1]]!.requestFocus();
    } else {
      _focus[f]!.unfocus();
    }
  }

  void _usePhotoSize() {
    _form.usePhotoSize(widget.info);
    final input = ref.read(targetFormProvider).input;
    _text[TargetField.width]!.text = input.width;
    _text[TargetField.height]!.text = input.height;
  }

  void _continue() {
    TargetScreen.fields.forEach(_clean);
    switch (ref.read(targetFormProvider).result) {
      case TargetInputValid(:final spec):
        widget.onContinue(spec);
      case TargetInputInvalid(:final firstField, :final errors):
        _form.revealAll();
        _focus[firstField]?.requestFocus();
        // Only the first message is announced (NFR-2); the others are read with their fields.
        final text = TargetMessages(AppLocalizations.of(context)).error(errors[firstField]!);
        unawaited(SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = TargetMessages(l);
    final state = ref.watch(targetFormProvider);
    final errors = state.visibleErrors;
    int? whole(String t) => switch (readNumber(cleanNumberText(t))) {
          Whole(:final value) => value,
          _ => null,
        };
    final w = whole(state.input.width), h = whole(state.input.height);
    final hints = targetHints(widget.info, width: w, height: h);
    final theme = Booth.theme(Theme.of(context));

    Widget field(TargetField f, String label, String unit, {String? helper}) => TextField(
          controller: _text[f],
          focusNode: _focus[f],
          keyboardType: TextInputType.number,
          textInputAction: f == TargetField.maxKb ? TextInputAction.done : TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          autofillHints: null,
          inputFormatters: [LengthLimitingTextInputFormatter(32)],
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontFamily: 'BarlowCondensed',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            labelText: label,
            suffixText: unit,
            helperText: helper,
            filled: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (t) => _form.setText(f, t),
          onEditingComplete: () {}, // focus moves in onSubmitted only
          onSubmitted: (_) => _next(f),
        );

    Widget error(TargetField f) => switch (errors[f]) {
          null => const SizedBox.shrink(),
          final e => _ErrorLine(m.error(e)),
        };

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                // Photo line (FR-12); a FEAT-011 preset row would go just below it (OQ-10).
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(m.photoSize(hints), style: theme.textTheme.bodyLarge),
                    if (hints.canUsePhotoSize) TextButton(onPressed: _usePhotoSize, child: Text(l.targetUsePhotoSize)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Booth.plate, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      LayoutBuilder(builder: (context, box) {
                        final w = field(TargetField.width, l.targetLabelWidth, l.targetUnitPx);
                        final h = field(TargetField.height, l.targetLabelHeight, l.targetUnitPx);
                        final narrow = box.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(1) >= 1.5;
                        if (narrow) return Column(spacing: 12, children: [w, h]);
                        return Row(spacing: 8, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: w),
                          const Padding(padding: EdgeInsets.only(top: 16), child: Text('×')),
                          Expanded(child: h),
                        ]);
                      }),
                      error(TargetField.width),
                      error(TargetField.height),
                      field(TargetField.minKb, l.targetLabelMin, l.targetUnitKb, helper: l.targetOptional),
                      error(TargetField.minKb),
                      field(TargetField.maxKb, l.targetLabelMax, l.targetUnitKb),
                      error(TargetField.maxKb),
                      Text(l.targetFormatLabel, style: theme.textTheme.labelLarge),
                      SegmentedButton<OutputFormat>(
                        segments: const [
                          ButtonSegment(value: OutputFormat.jpeg, label: Text('JPEG')),
                          ButtonSegment(value: OutputFormat.png, label: Text('PNG')),
                        ],
                        selected: {state.input.format},
                        emptySelectionAllowed: false,
                        multiSelectionEnabled: false,
                        onSelectionChanged: (s) => _form.setFormat(s.single),
                      ),
                      error(TargetField.format),
                    ],
                  ),
                ),
                // Non-blocking hints (FR-11, FR-13): never stop Continue.
                Semantics(
                  liveRegion: true,
                  container: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hints.enlarges && w != null && h != null)
                        BoothNotice(icon: Icons.info_outline, text: m.enlarged(Target(w, h))),
                      if (hints.verySmall) BoothNotice(icon: Icons.info_outline, text: m.verySmall),
                    ],
                  ),
                ),
                FilledButton(onPressed: _continue, child: Text(l.cropButtonContinue)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A field error: icon and text, never colour alone (G1 design).
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Booth.text),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Booth.text))),
        ],
      );
}
