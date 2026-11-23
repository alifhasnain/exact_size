import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../compression/domain/compression_result.dart';
import '../../crop/domain/crop_types.dart';
import '../domain/target_hints.dart';
import '../domain/target_input.dart';
import '../domain/validate_target_input.dart';

/// The target step's texts and which fields may show their error (FR-7).
final class TargetFormState {
  const TargetFormState({this.input = const TargetInput(), this.revealed = const {}});

  final TargetInput input;

  /// Fields the user has left or tried to continue with; only these show errors.
  final Set<TargetField> revealed;

  TargetInputResult get result => validateTargetInput(input);

  /// Errors to show now: every current error of a revealed field.
  Map<TargetField, TargetError> get visibleErrors => switch (result) {
        TargetInputInvalid(:final errors) => {
            for (final e in errors.entries)
              if (revealed.contains(e.key)) e.key: e.value,
          },
        TargetInputValid() => const {},
      };
}

/// Session memory only (FR-10): not auto-disposed, so values survive Back from
/// crop and the next photo; nothing is persisted or restored, so process death
/// starts empty (AC-8.3). No restorationId.
final targetFormProvider = NotifierProvider<TargetFormController, TargetFormState>(TargetFormController.new);

class TargetFormController extends Notifier<TargetFormState> {
  @override
  TargetFormState build() => const TargetFormState();

  void setText(TargetField field, String text) =>
      state = TargetFormState(input: state.input.withText(field, text), revealed: state.revealed);

  void setFormat(OutputFormat format) =>
      state = TargetFormState(input: state.input.copyWith(format: format), revealed: state.revealed);

  void reveal(TargetField field) => state = TargetFormState(input: state.input, revealed: {...state.revealed, field});

  void revealAll() => state = TargetFormState(input: state.input, revealed: TargetField.values.toSet());

  /// Replaces every field (FR-9, a preset or a saved spec).
  void fill(TargetInput input) => state = TargetFormState(input: input, revealed: state.revealed);

  /// "Use photo size" (FR-12): the oriented size, only when it is a valid target.
  void usePhotoSize(SourceInfo info) {
    final h = targetHints(info);
    if (!h.canUsePhotoSize) return;
    state = TargetFormState(
      input: state.input.copyWith(width: '${h.photoWidth}', height: '${h.photoHeight}'),
      revealed: state.revealed,
    );
  }

  /// A new photo: keep the values (FR-10), hide errors until the user acts again.
  void startForPhoto() => state = TargetFormState(input: state.input);
}
