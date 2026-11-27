import '../../compression/domain/compression_result.dart';
import '../../target/domain/target_input.dart';
import '../../target/domain/target_spec.dart';

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
    required this.width,
    required this.height,
    this.minKb,
    required this.maxKb,
    required this.format,
    this.notCovered = const [],
    this.engineReview,
  });

  final SpecKind kind;
  final int width;
  final int height;
  final int? minKb;
  final int maxKb;
  final OutputFormat format;
  final List<NotCovered> notCovered;

  /// Product Owner reason for an FR-20 exception; never rendered (AC-5.5).
  final String? engineReview;

  /// The same target manual entry of these values gives (FEAT-005).
  TargetSpec get target => TargetSpec(width: width, height: height, minKb: minKb, maxKb: maxKb, format: format);

  /// Field texts for `TargetFormController.fill`; no minimum gives ''.
  TargetInput get input => TargetInput(
    width: '$width',
    height: '$height',
    minKb: minKb == null ? '' : '$minKb',
    maxKb: '$maxKb',
    format: format,
  );
}

/// Where the form's rules were read (FR-4); shown by FEAT-014, not here.
final class PresetSource {
  const PresetSource({required this.title, this.url});
  final String title;

  /// Stored as text, never opened or shown (OQ-13).
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
