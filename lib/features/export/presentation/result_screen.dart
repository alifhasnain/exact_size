import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../../compression/domain/compression_result.dart';
import '../../compression/presentation/compression_providers.dart';
import '../../compression/presentation/outcome_messages.dart';
import '../../crop/presentation/recents_guard.dart';
import '../../preview/presentation/spec_check_controller.dart';
import '../../preview/presentation/spec_check_view.dart';
import '../../target/domain/target_spec.dart';
import '../domain/export_outcome.dart';
import '../domain/export_types.dart';
import 'export_controller.dart';
import 'export_messages.dart';
import 'export_panel.dart';

/// The result screen (FEAT-007 FR-29; FEAT-006 tech 4.4, G1 design t10/check_design.md).
/// Running and failure: FEAT-007's progress with Cancel or the FEAT-004 failure with Back.
/// Success: the FEAT-006 check (spinner while checking; matches with preview, rows and the
/// [ExportPanel]; mismatch with rows and Back to crop; unreadable with one way out).
/// Leaving a match asks first when nothing was saved or shared (FEAT-007 FR-23), waits for a
/// running save, drops the result and then calls [onStartOver].
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.spec, required this.onStartOver, this.recentsBinding = const AndroidRecentsBinding()});

  /// The target as entered (FEAT-006 FR-3); the check compares against it and
  /// [ExportPanel] gets its dimensions.
  final TargetSpec spec;
  final VoidCallback onStartOver;

  /// Platform side of the recents protection (FR-19), swappable in tests.
  final RecentsBinding recentsBinding;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  var _leaving = false; // one leave() per exit, however often Done or Back is pressed (AC-7.2)

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final run = ref.watch(compressionControllerProvider);
    final check = ref.watch(specCheckControllerProvider(widget.spec));
    final success = run is CompressionDone && run.result is CompressionSuccess ? run.result as CompressionSuccess : null;

    final Widget body;
    // Back that is not a plain pop runs this instead; null means the route may pop.
    final VoidCallback? onBack;
    switch (check) {
      case CheckMeets():
        onBack = () => _leave(check.success);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SpecCheckView(spec: widget.spec, state: check),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Booth.plate, borderRadius: BorderRadius.circular(16)),
              child: ExportPanel(success: check.success, size: widget.spec.dimensions),
            ),
            TextButton(onPressed: onBack, child: Text(l.exportDone)),
          ],
        );
      case CheckMismatch():
        // FR-10: the file is already deleted; Back returns to the crop step with photo and spec.
        onBack = null;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Semantics(container: true, liveRegion: true, child: BoothNotice(icon: Icons.error_outline, text: l.checkMismatch)),
            SpecSlip(spec: widget.spec, measured: check.measured, check: check.check, showAlsoFits: false),
            FilledButton.tonal(onPressed: () => Navigator.of(context).maybePop(), child: Text(material.backButtonTooltip)),
          ],
        );
      case CheckUnreadable():
        // FR-11, OQ-T4: nothing left to save, so no confirm.
        onBack = () => _drop(check.success);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Semantics(
              container: true,
              liveRegion: true,
              child: BoothNotice(icon: Icons.error_outline, text: ExportMessages(l).message(ExportOutcome.fileMissing, null)!),
            ),
            FilledButton.tonal(onPressed: onBack, child: Text(l.cropButtonChooseAnother)),
          ],
        );
      case Checking():
      case CheckIdle() when success != null:
        // FR-1: progress and no verdict until the file is measured. Leaving asks as a match does (OQ-T7).
        onBack = success == null ? () {} : () => _leave(success);
        body = const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: CircularProgressIndicator()));
      case CheckIdle():
        // FEAT-007's running and failure branches, unchanged.
        onBack = null;
        final text = announcementFor(run, OutcomeMessages(l)) ?? '';
        final failed = run is CompressionDone;
        body = Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              if (failed)
                BoothNotice(icon: Icons.error_outline, text: text)
              else ...[
                const Center(child: CircularProgressIndicator()),
                Text(text, textAlign: TextAlign.center),
              ],
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(failed ? material.backButtonTooltip : material.cancelButtonLabel),
              ),
            ],
          ),
        );
    }

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // Running: stop it. Failure: nothing to delete. Idle (after a mismatch or leave()): nothing left.
          if (ref.read(compressionControllerProvider) is! CompressionIdle) ref.read(compressionControllerProvider.notifier).cancel();
        } else {
          onBack?.call();
        }
      },
      child: RecentsGuard(
        binding: widget.recentsBinding,
        child: Theme(
          data: Booth.theme(Theme.of(context)).copyWith(
            textTheme: Theme.of(context).textTheme.apply(bodyColor: Booth.text, displayColor: Booth.text),
          ),
          child: Scaffold(
            appBar: AppBar(),
            body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: body)),
          ),
        ),
      ),
    );
  }

  /// Runs [leave] with the export controller held for the whole exit: while checking, or when the
  /// file is unreadable, no panel watches it, and an auto-dispose controller would go at the first
  /// await.
  Future<void> _exit(CompressionSuccess success, {required bool confirm}) async {
    if (_leaving) return;
    _leaving = true;
    final provider = exportControllerProvider(ExportInput(success, widget.spec.dimensions));
    final hold = ref.listenManual(provider, (_, _) {});
    try {
      final ctl = ref.read(provider.notifier);
      if (confirm && ctl.needsLeaveConfirm && !await _confirm(context)) {
        _leaving = false; // Stay
        return;
      }
      await ctl.leave();
    } finally {
      hold.close();
    }
    widget.onStartOver();
  }

  Future<void> _leave(CompressionSuccess success) => _exit(success, confirm: true);

  Future<void> _drop(CompressionSuccess success) => _exit(success, confirm: false);

  static Future<bool> _confirm(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Booth.plate,
        title: Text(l.exportLeaveTitle, style: const TextStyle(color: Booth.text)),
        content: Text(l.exportLeaveBody, style: const TextStyle(color: Booth.text)),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.of(context).pop(false), child: Text(l.exportStay)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.exportLeave)),
        ],
      ),
    );
    return leave ?? false;
  }
}
