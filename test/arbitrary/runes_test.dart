import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/helpers/helpers_internal.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('runes', () {
    final alphanum = CharacterSet.alphanum(CharacterEncoding.ascii);
    final digit = CharacterSet.digit(CharacterEncoding.ascii);
    final letter = CharacterSet.letter(CharacterEncoding.ascii);
    final upper = CharacterSet.upper(CharacterEncoding.ascii);
    final lower = CharacterSet.lower(CharacterEncoding.ascii);
    final symbol = CharacterSet.symbol(CharacterEncoding.ascii);
    final whitespaces = CharacterSet.whitespace(CharacterEncoding.ascii);
    final newlines = CharacterSet.newline(CharacterEncoding.ascii);
    final whitespacesAndNewlines =
        CharacterSet.whitespaceAndNewline(CharacterEncoding.ascii);

    group('character set (ascii)', () {
      property('alphanum', () {
        testForAll(runes(characterSet: alphanum), (value) {
          expect(value.string, matches(RegExp(r'^[a-zA-Z0-9]*$')));
        });
      });

      property('decimal digit', () {
        testForAll(runes(characterSet: digit), (value) {
          expect(value.string, matches(RegExp(r'^[0-9]*$')));
        });
      });

      property('hex digit', () {
        testForAll(runes(characterSet: CharacterSet.hexDigit()), (value) {
          expect(value.string, matches(RegExp(r'^[0-9a-fA-F]*$')));
        });
      });

      property('octal digit', () {
        testForAll(runes(characterSet: CharacterSet.octalDigit()), (value) {
          expect(value.string, matches(RegExp(r'^[0-7]*$')));
        });
      });

      property('letter', () {
        testForAll(runes(characterSet: letter), (value) {
          expect(value.string, matches(RegExp(r'^[a-zA-Z]*$')));
        });
      });

      property('upper', () {
        testForAll(runes(characterSet: upper), (value) {
          expect(value.string, matches(RegExp(r'^[A-Z]*$')));
        });
      });

      property('lower', () {
        testForAll(runes(characterSet: lower), (value) {
          expect(value.string, matches(RegExp(r'^[a-z]*$')));
        });
      });

      property('symbol', () {
        testForAll(runes(characterSet: symbol), (value) {
          expect(value.string, matches(RegExp(r'^[!-/:-@[-`{-~]*$')));
        });
      });

      property('whitespaces', () {
        testForAll(runes(characterSet: whitespaces), (value) {
          expect(value.string, matches(RegExp(r'^[\s]*$')));
        });
      });

      property('newlines', () {
        testForAll(runes(characterSet: newlines), (value) {
          expect(value.string, matches(RegExp(r'^[\n\r]*$')));
        });
      });

      property('whitespacesAndNewlines', () {
        testForAll(runes(characterSet: whitespacesAndNewlines), (value) {
          expect(value.string, matches(RegExp(r'^[\s\n\r]*$')));
        });
      });
    });

    group('character set (utf8)', () {
      property('all', () {
        testGeneratingUnicode(
          target: CharacterSet.all(CharacterEncoding.utf8),
          categories: UnicodeCategory.values,
        );
      });

      property('alphanumerics', () {
        testGeneratingUnicode(
          target: CharacterSet.alphanum(CharacterEncoding.utf8),
          categories: [
            UnicodeCategory.lu,
            UnicodeCategory.ll,
            UnicodeCategory.lm,
            UnicodeCategory.lt,
            UnicodeCategory.lo,
            UnicodeCategory.mn,
            UnicodeCategory.mc,
            UnicodeCategory.me,
            UnicodeCategory.nd,
            UnicodeCategory.nl,
            UnicodeCategory.no,
          ],
        );
      });

      property('decimal digits', () {
        testGeneratingUnicode(
          target: CharacterSet.digit(CharacterEncoding.utf8),
          categories: [UnicodeCategory.nd],
        );
      });

      property('letters', () {
        testGeneratingUnicode(
          target: CharacterSet.letter(CharacterEncoding.utf8),
          categories: [
            UnicodeCategory.lu,
            UnicodeCategory.ll,
            UnicodeCategory.lt,
            UnicodeCategory.lo,
            UnicodeCategory.lm,
            UnicodeCategory.mn,
            UnicodeCategory.mc,
            UnicodeCategory.me,
          ],
        );
      });

      property('upper', () {
        testGeneratingUnicode(
          target: CharacterSet.upper(CharacterEncoding.utf8),
          categories: [UnicodeCategory.lu, UnicodeCategory.lt],
        );
      });

      property('lower', () {
        testGeneratingUnicode(
          target: CharacterSet.lower(CharacterEncoding.utf8),
          categories: [UnicodeCategory.ll],
        );
      });

      property('symbol', () {
        testGeneratingUnicode(
          target: CharacterSet.symbol(CharacterEncoding.utf8),
          categories: [
            UnicodeCategory.so,
            UnicodeCategory.sc,
            UnicodeCategory.sk,
            UnicodeCategory.sm,
          ],
        );
      });

      property('whitespaces', () {
        testGeneratingUnicode(
          target: CharacterSet.whitespace(CharacterEncoding.utf8),
          categories: [
            UnicodeCategory.zs,
            UnicodeCategory.zl,
            UnicodeCategory.zp,
          ],
          codePoints: [0x0009],
        );
      });

      property('newlines', () {
        testGeneratingUnicode(
          target: CharacterSet.newline(CharacterEncoding.utf8),
          categories: [UnicodeCategory.zl, UnicodeCategory.zp],
          codePoints: [
            0x000A,
            0x000B,
            0x000C,
            0x000D,
            0x0085,
            0x2028,
            0x2029,
          ],
        );
      });

      property('whitespaces and newlines', () {
        testGeneratingUnicode(
          target: CharacterSet.whitespaceAndNewline(CharacterEncoding.utf8),
          categories: [
            UnicodeCategory.zs,
            UnicodeCategory.zl,
            UnicodeCategory.zp,
          ],
          codePoints: [
            0x0009,
            0x000A,
            0x000B,
            0x000C,
            0x000D,
            0x0085,
            0x2028,
            0x2029,
          ],
        );
      });
    });

    group('generation', () {
      property('min', () {
        const min = 10;
        testForAll(runes(minLength: min, characterSet: alphanum), (value) {
          expect(value.length, greaterThanOrEqualTo(min));
        });
      });

      property('max', () {
        const max = 10;
        testForAll(runes(maxLength: max, characterSet: alphanum), (value) {
          expect(value.length, lessThanOrEqualTo(max));
        });
      });

      property('min, max', () {
        const min = 10;
        const max = 20;
        testForAll(
            runes(minLength: min, maxLength: max, characterSet: alphanum),
            (value) {
          expect(value.length, greaterThanOrEqualTo(min));
          expect(value.length, lessThanOrEqualTo(max));
        });
      });
    });
  });
}

void testGeneratingUnicode({
  required CharacterSet target,
  required List<UnicodeCategory> categories,
  List<int> codePoints = const [],
  int minLength = 100,
  int maxLength = 100,
}) {
  final testCharSets =
      categories.map((e) => CharacterSet.fromUnicodeCategories([e])).toList();
  final result = Map<CharacterSet, int>.fromIterables(
    testCharSets,
    List.filled(categories.length, 0),
  );
  if (codePoints.isNotEmpty) {
    final codePointSet = CharacterSet.fromCodePoints(codePoints);
    testCharSets.add(codePointSet);
    result[codePointSet] = 0;
  }

  testForAll(
    runes(minLength: 100, maxLength: 100, characterSet: target),
    (value) {
      for (final c in value) {
        for (final charSet in testCharSets) {
          if (charSet.contains(c)) {
            result[charSet] = result[charSet]! + 1;
            break;
          }
        }
      }
    },
    tearDownAll: (_) {
      for (final charSet in testCharSets) {
        expect(result[charSet], greaterThan(0), reason: charSet.toString());
      }
    },
  );
}
