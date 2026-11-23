import '../../compression/domain/target_validator.dart';
import '../../crop/domain/crop_types.dart';
import '../../crop/domain/target_check.dart';
import 'number_text.dart';
import 'target_input.dart';
import 'target_spec.dart';

/// Validates every field of the target step (FEAT-005 tech section 3, OQ-8
/// option A). Limits and messages stay FEAT-002's (`checkTarget`) and
/// FEAT-004's (`validateTarget`); only text classes are decided here.
/// Pure: the FEAT-011 data test calls it too (AC-9.3).
TargetInputResult validateTargetInput(TargetInput input) {
  final errors = <TargetField, TargetError>{};

  int? side(TargetField field) {
    switch (readNumber(cleanNumberText(input.text(field)))) {
      case Whole(:final value):
        final m = checkTarget(Target(value, 1));
        if (m == null) return value;
        errors[field] = PixelRangeError(m);
      case NotWhole():
        errors[field] = const PixelsNotWhole();
      case Empty() || NotNumber():
        errors[field] = const PixelRangeError(TargetDimensionsMessage.sideOutOfRange);
    }
    return null;
  }

  final w = side(TargetField.width);
  final h = side(TargetField.height);
  if (w != null && h != null) {
    final m = checkTarget(Target(w, h));
    if (m != null) errors[TargetField.width] = PixelRangeError(m);
  }

  final format = input.format.name;

  /// Canonical digits for validateTarget, or null after recording a text error.
  String? kbText(TargetField field) => switch (readNumber(cleanNumberText(input.text(field)))) {
        Empty() => '',
        Whole(:final value) => '$value',
        NotWhole() => _fail(errors, field, TargetMessage.wholeNumbersOnly),
        NotNumber() => _fail(errors, field, TargetMessage.invalidNumber),
      };

  int? maxKb;
  if (kbText(TargetField.maxKb) case final text?) {
    switch (validateTarget(maxText: text, format: format)) {
      case ValidTarget(maxKb: final v):
        maxKb = v;
      case InvalidTarget(:final message):
        errors[TargetField.maxKb] = KbError(message);
    }
  }

  int? minKb;
  if (kbText(TargetField.minKb) case final text? when text.isNotEmpty) {
    // validateTarget checks Max (already valid here, or the largest allowed)
    // before the Min/Max pair, so any problem now is Min's (R3).
    switch (validateTarget(maxText: '${maxKb ?? maxKbLimit}', minText: text, format: format)) {
      case ValidTarget(minKb: final v):
        minKb = v;
      case InvalidTarget(message: TargetMessage.minNotBelowMax) when maxKb == null:
        break; // Min alone is not an error while Max is invalid (PRD section 9)
      case InvalidTarget(:final message):
        errors[TargetField.minKb] = KbError(message);
    }
  }

  if (errors.isNotEmpty) return TargetInputInvalid(errors);
  return TargetInputValid(TargetSpec(width: w!, height: h!, minKb: minKb, maxKb: maxKb!, format: input.format));
}

String? _fail(Map<TargetField, TargetError> errors, TargetField field, TargetMessage m) {
  errors[field] = KbError(m);
  return null;
}
