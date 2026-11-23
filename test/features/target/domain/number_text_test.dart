import 'package:exact_size/features/target/domain/number_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// FEAT-005-T03: FR-4 cleaning and reading (table from tasks.md).
void main() {
  NumberRead read(String raw) => readNumber(cleanNumberText(raw));

  test('native digits read as 0-9 (FR-4 b)', () {
    for (final s in ['٣٠٠', '۳۰۰', '३००', '৩০০']) {
      expect(read(s), const Whole(300), reason: s);
      expect(cleanNumberText(s), '300');
    }
  });

  test('leading zeros are stripped for reading but kept in the cleaned text (OQ-T2)', () {
    expect(read('0300'), const Whole(300));
    expect(read('0000000000300'), const Whole(300));
    expect(cleanNumberText('0300'), '0300');
    expect(read('0'), const Whole(0));
    expect(read('000'), const Whole(0));
  });

  test('whitespace and bidi controls are removed (FR-4 a)', () {
    for (final s in [
      '\u2066300\u2069',
      '\u200F300\u200E',
      '\u061C3\u202A0\u202E0',
      '\u00A0300\u202F',
      ' 3 0 0 ',
      '\t300\n',
      '\uFEFF300',
    ]) {
      expect(read(s), const Whole(300), reason: s.runes.toList().toString());
      expect(cleanNumberText(s), '300');
    }
  });

  test('separators make a number not whole (FR-4 c)', () {
    for (final s in ['7.5', '7,5', '1,000', '1.000', '1.000.000', '٧٫٥', '١٬٠٠٠', '.5', '5.']) {
      expect(read(s), isA<NotWhole>(), reason: s);
    }
    expect(cleanNumberText('٧٫٥'), '7.5');
    expect(cleanNumberText('1,000'), '1.000');
  });

  test('anything else is not a number', () {
    for (final s in ['-5', '+5', '0x10', '1e3', '300x300', '३०० px', 'KB', '.', '..', '٣a']) {
      expect(read(s), isA<NotNumber>(), reason: s);
    }
  });

  test('more than 9 significant digits read as 999,999,999 (FR-4 d)', () {
    for (final n in [10, 20, 40]) {
      expect(read('9' * n), const Whole(999999999), reason: '$n digits');
      expect(cleanNumberText('1' * n), '1' * n, reason: 'the text is not rewritten');
    }
    expect(read('123456789'), const Whole(123456789));
  });

  test('empty and whitespace-only are Empty', () {
    expect(read(''), isA<Empty>());
    expect(read('   '), isA<Empty>());
    expect(read('\u2066\u00A0\u2069'), isA<Empty>());
  });
}
