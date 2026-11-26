import '../../../l10n/app_localizations.dart';
import '../domain/export_outcome.dart';
import '../domain/export_types.dart';

/// FEAT-007 texts (PRD section 8). Folder and file names are wrapped in left-to-right isolates
/// here, never in the ARB (FR-30).
class ExportMessages {
  ExportMessages(this._l10n);

  final AppLocalizations _l10n;

  /// The gallery folder as the user finds it; never translated.
  static const folder = 'Pictures/ExactSize';

  /// The message for [o], or null when the outcome shows none (Share opened, save-as closed).
  String? message(ExportOutcome o, SavedItem? saved) {
    final name = _ltr(saved?.displayName ?? '');
    final viaSaveAs = saved?.viaSaveAs ?? false;
    return switch (o) {
      ExportOutcome.saved => viaSaveAs ? _l10n.exportSavedAs(name) : _l10n.exportSaved(_ltr(folder), name),
      ExportOutcome.alreadySaved => viaSaveAs ? _l10n.exportAlreadySavedAs(name) : _l10n.exportAlreadySaved(name, _ltr(folder)),
      ExportOutcome.noSpace => _l10n.exportNoSpace,
      ExportOutcome.saveFailed => _l10n.exportSaveFailed,
      ExportOutcome.permissionDenied => _l10n.exportPermissionDenied,
      ExportOutcome.fileMissing => _l10n.exportFileMissing,
      ExportOutcome.shareFailed => _l10n.exportShareFailed,
      ExportOutcome.openNoViewer => _l10n.exportNoViewer,
      ExportOutcome.shareOpened || ExportOutcome.saveCancelled => null,
    };
  }

  static String _ltr(String s) => '\u2066$s\u2069';
}
