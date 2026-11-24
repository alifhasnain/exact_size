import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../../compression/domain/compression_result.dart';
import '../../compression/presentation/compression_providers.dart';
import '../../compression/presentation/outcome_messages.dart';
import '../../crop/domain/crop_types.dart';
import '../domain/export_types.dart';
import 'export_controller.dart';
import 'export_messages.dart';
import 'export_panel.dart';

/// Temporary result screen (FEAT-007 FR-29, tech 4.5; G1 design t17/export_design.md) until
/// FEAT-006 takes it over: progress with Cancel, the FEAT-004 failure with Back, or the ready line
/// and the [ExportPanel]. No preview and no "meets spec" claim. Leaving a success asks first when
/// nothing was saved or shared (FR-23), waits for a running save, drops the result (FR-22, FR-24)
/// and then calls [onStartOver] (release the photo, end crop, back to the pick screen).
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.size, required this.onStartOver});

  final Target size;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final run = ref.watch(compressionControllerProvider);
    final success = run is CompressionDone && run.result is CompressionSuccess ? run.result as CompressionSuccess : null;

    final Widget body;
    if (success != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Booth.plate, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Text(ExportMessages(l).ready(success, size), style: _spec),
                ExportPanel(success: success, size: size),
              ],
            ),
          ),
          TextButton(onPressed: () => _leave(context, ref, success), child: Text(l.exportDone)),
        ],
      );
    } else {
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
      canPop: success == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // Running: stop it. Failure: nothing to delete. Idle: leave() already dropped the result.
          if (ref.read(compressionControllerProvider) is! CompressionIdle) ref.read(compressionControllerProvider.notifier).cancel();
        } else if (success != null) {
          _leave(context, ref, success);
        }
      },
      child: Theme(
        data: Booth.theme(Theme.of(context)).copyWith(
          textTheme: Theme.of(context).textTheme.apply(bodyColor: Booth.text, displayColor: Booth.text),
        ),
        child: Scaffold(
          appBar: AppBar(),
          body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: body)),
        ),
      ),
    );
  }

  static const _spec = TextStyle(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w600,
    fontSize: 22,
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Booth.text,
  );

  Future<void> _leave(BuildContext context, WidgetRef ref, CompressionSuccess success) async {
    final ctl = ref.read(exportControllerProvider(ExportInput(success, size)).notifier);
    if (ctl.needsLeaveConfirm && !await _confirm(context)) return;
    await ctl.leave();
    onStartOver();
  }

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
