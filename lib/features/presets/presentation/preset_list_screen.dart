import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../domain/preset_search.dart';
import '../domain/preset_types.dart';
import 'preset_strings.dart';

/// What the list returns: the form and spec the user tapped.
final class PresetPick {
  const PresetPick({required this.formId, required this.kind});
  final String formId;
  final SpecKind kind;

  @override
  bool operator ==(Object other) => other is PresetPick && other.formId == formId && other.kind == kind;

  @override
  int get hashCode => Object.hash(formId, kind);

  /// The pick reveals the user's application (FR-17).
  @override
  String toString() => 'PresetPick(<redacted>)';
}

/// FEAT-011 form list (FR-6..FR-10, FR-14, FR-15; G1 design, t09/preset_design.md): the booth's
/// price board. Pinned search, country sections, one outlined key per spec, notes, empty state and
/// the not-affiliated footer. The search text lives only in this State (FR-17, AC-8.2).
class PresetListScreen extends StatefulWidget {
  const PresetListScreen({super.key, required this.forms});

  final List<PresetForm> forms;

  static const maxContentWidth = 560.0;

  /// Opens the list; null on Back or "Enter sizes yourself".
  static Future<PresetPick?> open(BuildContext context, List<PresetForm> forms) =>
      Navigator.of(context).push<PresetPick>(MaterialPageRoute(builder: (_) => PresetListScreen(forms: forms)));

  @override
  State<PresetListScreen> createState() => _PresetListScreenState();
}

class _PresetListScreenState extends State<PresetListScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = PresetStrings(l);
    final booth = Booth.theme(Theme.of(context));
    // On the booth every text is light (WCAG AA pairs), as on the target step.
    final theme = booth.copyWith(
      textTheme: booth.textTheme.apply(bodyColor: Booth.text, displayColor: Booth.text),
    );
    final sections = filterForms(widget.forms, _query.text, (f) => s.category(f.category), s.country);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: Text(l.presetListTitle)),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PresetListScreen.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _search(context, l)),
                  Expanded(
                    child: CustomScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        if (sections.isEmpty)
                          SliverToBoxAdapter(child: _Empty(l))
                        else
                          for (final (i, section) in sections.indexed) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, i == 0 ? 16 : 24, 16, 8),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    section.name,
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList.builder(
                                itemCount: section.forms.length,
                                itemBuilder: (context, i) => _FormCard(section.forms[i], s),
                              ),
                            ),
                          ],
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                            child: Text(l.presetNotAffiliated, style: theme.textTheme.bodyMedium),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _search(BuildContext context, AppLocalizations l) => TextField(
    controller: _query,
    // FR-9: nothing the user types is learned, suggested or autofilled.
    autocorrect: false,
    enableSuggestions: false,
    enableIMEPersonalizedLearning: false,
    autofillHints: null,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
    inputFormatters: [LengthLimitingTextInputFormatter(maxSearchLength)],
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      hintText: l.presetSearchHint,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _query.text.isEmpty
          ? null
          : IconButton(
              tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
              icon: const Icon(Icons.close),
              onPressed: () => setState(_query.clear),
            ),
      filled: true,
      border: const OutlineInputBorder(),
    ),
  );
}

/// One form: name, issuer and category, the source lines (FEAT-014), then one key per spec (the
/// card itself is not tappable).
class _FormCard extends StatelessWidget {
  const _FormCard(this.form, this.s);
  final PresetForm form;
  final PresetStrings s;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final source = s.cardSource(form);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Booth.plate, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(s.name(form), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
          Text(s.issuerLine(form), style: text.bodyMedium),
          // FEAT-014 FR-2: where the sizes come from; plain text, no prompt here (t05/source_design.md).
          if (source.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(source, style: text.bodySmall?.copyWith(color: Booth.text.withValues(alpha: 0.8))),
          ],
          for (final spec in form.specs) ...[const SizedBox(height: 12), _SpecKey(form, spec, s)],
        ],
      ),
    );
  }
}

/// The outlined key of the preset row and the spec rows (G1 design: the BoothSpecCell outline).
final presetKeyShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  side: BorderSide(color: Booth.text.withValues(alpha: 0.6), width: 1.5),
);

/// The tappable spec: kind, summary and notes, read by TalkBack as one button (AC-9.3).
class _SpecKey extends StatelessWidget {
  const _SpecKey(this.form, this.spec, this.s);
  final PresetForm form;
  final PresetSpec spec;
  final PresetStrings s;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // One node: form name, kind, size, KB range, format and notes (AC-9.3).
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: s.name(form),
        child: Material(
          type: MaterialType.transparency,
          shape: presetKeyShape,
          child: InkWell(
            customBorder: presetKeyShape,
            onTap: () => Navigator.of(context).pop(PresetPick(formId: form.id, kind: spec.kind)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    Text(s.kind(spec.kind), style: text.titleSmall),
                    Text(
                      s.summary(spec),
                      style: text.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    for (final note in spec.notCovered)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Booth.text),
                            Expanded(child: Text(s.note(note), style: text.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// No match: the message and a way back to the manual fields (AC-2.3).
class _Empty extends StatelessWidget {
  const _Empty(this.l);
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(l.presetNoMatch, style: Theme.of(context).textTheme.bodyLarge),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Booth.text,
            minimumSize: const Size(48, 48),
            side: BorderSide(color: Booth.text.withValues(alpha: 0.6), width: 1.5),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.presetEnterYourself),
        ),
      ],
    ),
  );
}
