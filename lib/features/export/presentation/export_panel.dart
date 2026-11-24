import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/booth.dart';
import '../../compression/domain/compression_result.dart';
import '../../crop/domain/crop_types.dart';
import '../domain/export_outcome.dart';
import '../domain/export_types.dart';
import 'export_controller.dart';
import 'export_messages.dart';

/// The export area for one FEAT-004 result (FEAT-007; G1 design t17/export_design.md, the booth
/// "pickup slot"): Save, Share, the message, Open, "Choose where to save" after a refusal, the chat
/// hint and the privacy line. Self-contained so FEAT-006 can embed it unchanged (FR-29).
/// Shows no image (FEAT-006 owns the preview).
class ExportPanel extends ConsumerWidget {
  const ExportPanel({super.key, required this.success, required this.size});

  final CompressionSuccess success;
  final Target size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final provider = exportControllerProvider(ExportInput(success, size));
    final s = ref.watch(provider);
    final ctl = ref.read(provider.notifier);
    final text = s.message == null ? null : ExportMessages(l).message(s.message!, s.saved);
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: Booth.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FilledButton.icon(
          onPressed: s.busy ? null : ctl.save,
          icon: s.showProgress
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Booth.onFlash))
              : const Icon(Icons.download),
          label: Text(s.showProgress ? l.exportSaving : l.exportSave),
          style: FilledButton.styleFrom(disabledBackgroundColor: Booth.flash.withValues(alpha: 0.5), disabledForegroundColor: Booth.onFlash),
        ),
        FilledButton.tonalIcon(onPressed: ctl.share, icon: const Icon(Icons.share), label: Text(l.exportShare)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const ExcludeSemantics(child: Icon(Icons.info_outline, size: 18, color: Booth.text)),
            Expanded(child: Text(l.exportShareHint, style: small)),
          ],
        ),
        // One polite live region; the next action replaces the text, which announces it once (NFR-2).
        Semantics(
          container: true,
          liveRegion: true,
          child: text == null
              ? const SizedBox.shrink()
              : Column(
                  key: ValueKey(text),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BoothNotice(icon: _icon(s.message!), text: text),
                    if (s.message == ExportOutcome.permissionDenied)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(onPressed: ctl.saveAs, icon: const Icon(Icons.folder_open), label: Text(l.exportSaveAs)),
                      ),
                  ],
                ),
        ),
        if (s.saved != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(onPressed: ctl.open, icon: const Icon(Icons.open_in_new), label: Text(l.exportOpen)),
          ),
        Text(l.exportPrivacy, style: small),
      ],
    );
  }

  static IconData _icon(ExportOutcome o) => switch (o) {
        ExportOutcome.saved => Icons.check_circle_outline,
        ExportOutcome.alreadySaved || ExportOutcome.openNoViewer => Icons.info_outline,
        _ => Icons.error_outline,
      };
}
