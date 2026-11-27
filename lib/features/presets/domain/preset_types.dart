import '../../compression/domain/compression_result.dart';
import '../../target/domain/number_text.dart';
import '../../target/domain/target_input.dart';

/// Which upload a spec row is for (FEAT-011 FR-3).
enum SpecKind { photo, signature }

/// Form category; JSON values are `job`, `exam_admission`, `visa_passport`, `other` (FR-2).
enum FormCategory {
  job('job'),
  examAdmission('exam_admission'),
  visaPassport('visa_passport'),
  other('other');

  const FormCategory(this.json);

  /// Value in `presets.json` and the `presetCategory` select case.
  final String json;
}

/// A form rule the app does not change, shown as a note (FR-14).
sealed class NotCovered {
  const NotCovered();
}

final class DpiNote extends NotCovered {
  const DpiNote(this.dpi);
  final int dpi;
  @override
  bool operator ==(Object other) => other is DpiNote && other.dpi == dpi;
  @override
  int get hashCode => dpi.hashCode;
}

final class BackgroundNote extends NotCovered {
  const BackgroundNote();
  @override
  bool operator ==(Object other) => other is BackgroundNote;
  @override
  int get hashCode => (BackgroundNote).hashCode;
}

final class ContentNote extends NotCovered {
  const ContentNote();
  @override
  bool operator ==(Object other) => other is ContentNote;
  @override
  int get hashCode => (ContentNote).hashCode;
}

/// One upload rule of a form: pixels, KB range and format (FR-3).
final class PresetSpec {
  const PresetSpec({
    required this.kind,
    this.width,
    this.height,
    this.minKb,
    required this.maxKb,
    required this.format,
    this.notCovered = const [],
    this.engineReview,
  }) : assert((width == null) == (height == null), 'width and height: both or neither');

  final SpecKind kind;

  /// Null together with [height] for a KB-only spec: the form states no pixel size (FR-3, 2.0).
  final int? width;
  final int? height;
  final int? minKb;
  final int maxKb;
  final OutputFormat format;
  final List<NotCovered> notCovered;

  /// Product Owner reason for an FR-20 exception; never rendered (AC-5.5).
  final String? engineReview;

  /// The form states a KB range and format but no pixel size (FR-3, 2.0).
  bool get kbOnly => width == null;

  /// What `TargetFormController.fill` gets on a pick (FR-11). A full spec replaces all five values
  /// (no minimum gives ''); a KB-only spec keeps [current] width and height exactly as they are.
  TargetInput applyTo(TargetInput current) {
    final min = minKb == null ? '' : '$minKb';
    if (kbOnly) return current.copyWith(minKb: min, maxKb: '$maxKb', format: format);
    return TargetInput(width: '$width', height: '$height', minKb: min, maxKb: '$maxKb', format: format);
  }

  /// Whether [current] still holds this spec (FR-13): each field read with FEAT-005's own cleaning,
  /// so leading zeros and native digits match. A KB-only spec ignores width and height.
  bool matches(TargetInput current) {
    bool whole(String text, int value) => readNumber(cleanNumberText(text)) == Whole(value);
    final minOk = minKb == null ? readNumber(cleanNumberText(current.minKb)) is Empty : whole(current.minKb, minKb!);
    if (current.format != format || !whole(current.maxKb, maxKb) || !minOk) return false;
    return kbOnly || (whole(current.width, width!) && whole(current.height, height!));
  }
}

/// Where the form's rules were read (FR-4); shown by FEAT-014, not here.
final class PresetSource {
  const PresetSource({required this.title, this.url});
  final String title;

  /// Stored as text and never opened; FEAT-014 shows its host only (FR-4).
  final String? url;
}

/// One application form with 1–2 spec rows (FR-2).
final class PresetForm {
  const PresetForm({
    required this.id,
    required this.name,
    required this.issuer,
    required this.country,
    required this.category,
    this.aliases = const [],
    required this.source,
    this.lastChecked,
    required this.specs,
  });

  final String id;
  final String name;
  final String issuer;

  /// ISO 3166-1 alpha-2 code; the name comes from the `presetCountry` select.
  final String country;
  final FormCategory category;
  final List<String> aliases;
  final PresetSource source;

  /// Date only; required and checked by the CI rules (FR-19).
  final DateTime? lastChecked;
  final List<PresetSpec> specs;
}

/// The parsed library and how many entries were skipped at runtime (FR-16).
final class PresetLibrary {
  const PresetLibrary({required this.forms, this.skipped = 0});
  final List<PresetForm> forms;
  final int skipped;
}

/// The form and spec the user picked this session (FR-12). Session-only.
final class AppliedPreset {
  const AppliedPreset({required this.formId, required this.kind});
  final String formId;
  final SpecKind kind;

  @override
  bool operator ==(Object other) => other is AppliedPreset && other.formId == formId && other.kind == kind;

  @override
  int get hashCode => Object.hash(formId, kind);

  /// The choice reveals the user's application; keep it out of logs (FR-17).
  @override
  String toString() => 'AppliedPreset(<redacted>)';
}
