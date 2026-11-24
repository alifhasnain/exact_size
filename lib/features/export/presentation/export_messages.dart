import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../compression/domain/compression_result.dart';
import '../../compression/presentation/outcome_messages.dart' show achievedKb;
import '../../crop/domain/crop_types.dart';
import '../domain/export_outcome.dart';
import '../domain/export_types.dart';

/// FEAT-007 texts (PRD section 8). Folder and file names are wrapped in left-to-right isolates
/// here, never in the ARB (FR-30); numbers are formatted for the locale and isolated.
class ExportMessages {
  ExportMessages(this._l10n) : _number = NumberFormat.decimalPattern(_l10n.localeName);

  final AppLocalizations _l10n;
  final NumberFormat _number;

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

  /// FR-29 "Ready: W × H px, SIZE, FORMAT"; the size is FEAT-004's, not recomputed.
  String ready(CompressionSuccess s, Target size) => _l10n.exportReady(
        _iso(_number.format(size.width)),
        _iso(_number.format(size.height)),
        _iso(_l10n.kbAmount(_number.format(achievedKb(s.sizeBytes, null)))),
        _ltr(s.format == OutputFormat.jpeg ? 'JPEG' : 'PNG'),
      );

  static String _iso(String s) => '\u2068$s\u2069';
  static String _ltr(String s) => '\u2066$s\u2069';
}
