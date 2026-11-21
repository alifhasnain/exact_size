import 'package:exact_size/features/pick/domain/pick_types.dart';
import 'package:exact_size/features/pick/presentation/pick_messages.dart';
import 'package:exact_size/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every PickMessage has a non-empty English string; buttons and progress exist', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final texts = {for (final m in PickMessage.values) m: m.text(l)};
    expect(texts.values.where((t) => t.trim().isEmpty), isEmpty);
    expect(texts.values.toSet(), hasLength(PickMessage.values.length), reason: 'one distinct message each');
    for (final t in [l.pickTakePhoto, l.pickChooseGallery, l.pickChooseFiles, l.pickPrivacyNote, l.pickOpening, l.pickNoCamera]) {
      expect(t.trim(), isNotEmpty);
    }
  });
}
