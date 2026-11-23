import '../../compression/domain/compression_result.dart';
import '../../compression/domain/target_validator.dart';
import '../../crop/domain/target_check.dart';
import 'target_spec.dart';

/// Fields of the target step, in the order errors are reported and focused
/// (FR-8: W, H, Min, Max).
enum TargetField { width, height, minKb, maxKb, format }

/// The raw texts the user typed, and the chosen format (FR-2: JPEG by default).
final class TargetInput {
  const TargetInput({this.width = '', this.height = '', this.minKb = '', this.maxKb = '', this.format = OutputFormat.jpeg});

  final String width;
  final String height;
  final String minKb;
  final String maxKb;
  final OutputFormat format;

  TargetInput copyWith({String? width, String? height, String? minKb, String? maxKb, OutputFormat? format}) => TargetInput(
        width: width ?? this.width,
        height: height ?? this.height,
        minKb: minKb ?? this.minKb,
        maxKb: maxKb ?? this.maxKb,
        format: format ?? this.format,
      );

  /// Text of [field]; empty for [TargetField.format].
  String text(TargetField field) => switch (field) {
        TargetField.width => width,
        TargetField.height => height,
        TargetField.minKb => minKb,
        TargetField.maxKb => maxKb,
        TargetField.format => '',
      };

  /// Returns a copy with [field] set to [text]; [TargetField.format] is ignored.
  TargetInput withText(TargetField field, String text) => switch (field) {
        TargetField.width => copyWith(width: text),
        TargetField.height => copyWith(height: text),
        TargetField.minKb => copyWith(minKb: text),
        TargetField.maxKb => copyWith(maxKb: text),
        TargetField.format => this,
      };

  @override
  bool operator ==(Object other) =>
      other is TargetInput &&
      other.width == width &&
      other.height == height &&
      other.minKb == minKb &&
      other.maxKb == maxKb &&
      other.format == format;

  @override
  int get hashCode => Object.hash(width, height, minKb, maxKb, format);

  /// The user's numbers stay out of logs and crash reports (FR-14).
  @override
  String toString() => 'TargetInput(<redacted>)';
}

/// Why a field is refused. Pixel and KB messages are FEAT-002's and
/// FEAT-004's own; only [PixelsNotWhole] is new (FR-5).
sealed class TargetError {
  const TargetError();
}

final class PixelRangeError extends TargetError {
  const PixelRangeError(this.message);
  final TargetDimensionsMessage message;
  @override
  bool operator ==(Object other) => other is PixelRangeError && other.message == message;
  @override
  int get hashCode => message.hashCode;
  @override
  String toString() => 'PixelRangeError(${message.name})';
}

final class PixelsNotWhole extends TargetError {
  const PixelsNotWhole();
  @override
  bool operator ==(Object other) => other is PixelsNotWhole;
  @override
  int get hashCode => (PixelsNotWhole).hashCode;
  @override
  String toString() => 'PixelsNotWhole()';
}

final class KbError extends TargetError {
  const KbError(this.message);
  final TargetMessage message;
  @override
  bool operator ==(Object other) => other is KbError && other.message == message;
  @override
  int get hashCode => message.hashCode;
  @override
  String toString() => 'KbError(${message.name})';
}

/// Result of `validateTargetInput`.
sealed class TargetInputResult {
  const TargetInputResult();
}

final class TargetInputValid extends TargetInputResult {
  const TargetInputValid(this.spec);
  final TargetSpec spec;
}

/// Every refused field at once (AC-3.5).
final class TargetInputInvalid extends TargetInputResult {
  TargetInputInvalid(Map<TargetField, TargetError> errors) : errors = Map.unmodifiable(errors) {
    assert(errors.isNotEmpty, 'an invalid input has at least one error');
  }

  final Map<TargetField, TargetError> errors;

  /// The field to focus first (FR-8): W, H, Min, Max, then format.
  TargetField get firstField => TargetField.values.firstWhere(errors.containsKey);
}
