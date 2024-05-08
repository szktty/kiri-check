import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/util/character/unicode.dart';
import 'package:kiri_check/src/util/character/unicode_data.dart';
import 'package:meta/meta.dart';

/// Character encoding types.
///
/// See [CharacterSet] for more information.
enum CharacterEncoding {
  /// ASCII encoding.
  ascii,

  /// UTF-8 encoding.
  utf8,

  /// UTF-16 encoding.
  utf16,
}

final class CharacterRange {
  const CharacterRange(this.start, this.end);

  final int start;
  final int end;
}

/// A set of characters that can be used to match against code points.
/// This is used to define constraints for generation of [string] and [runes].
final class CharacterSet {
  /// Creates an empty character set.
  CharacterSet();

  factory CharacterSet._fromRanges(List<CharacterRange> ranges) {
    final set = CharacterSet();
    set._ranges.addAll(ranges);
    return set;
  }

  /// Creates a character set from a string of characters.
  factory CharacterSet.fromCharacters(String characters) {
    return CharacterSet()..addCharacters(characters);
  }

  /// Creates a character set from a list of code points.
  factory CharacterSet.fromCodePoints(List<int> codePoints) {
    return CharacterSet()..addCodePoints(codePoints);
  }

  @internal
  factory CharacterSet.fromUnicodeCategories(List<UnicodeCategory> categories) {
    final set = CharacterSet();
    for (final category in categories) {
      final ranges = UnicodeData.getRanges(category)
          .map((e) => CharacterRange(e.start, e.end))
          .toList();
      set._ranges.addAll(ranges);
    }
    return set;
  }

  /// Creates a character set that contains characters of
  /// all Unicode categories.
  ///
  /// If the encoding is [CharacterEncoding.ascii],
  /// character range is from `0x0000` to `0x007F`.
  factory CharacterSet.all(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet._fromRanges([const CharacterRange(0x0000, 0x007F)]);
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories(UnicodeCategory.values);
    }
  }

  /// Creates a character set that contains alphanumeric characters of
  /// Unicode categories `L*`, `M*`, `N*`.
  factory CharacterSet.alphanum(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters(
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
        );
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.ll,
          UnicodeCategory.lm,
          UnicodeCategory.lo,
          UnicodeCategory.lt,
          UnicodeCategory.lu,
          UnicodeCategory.mc,
          UnicodeCategory.me,
          UnicodeCategory.mn,
          UnicodeCategory.nd,
          UnicodeCategory.nl,
          UnicodeCategory.no,
        ]);
    }
  }

  /// Creates a character set that contains uppercase characters of
  /// Unicode categories `Lu`, `Lt`.
  factory CharacterSet.upper(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.lu,
          UnicodeCategory.lt,
        ]);
    }
  }

  /// Creates a character set that contains lowercase characters of
  /// Unicode categories `Ll`.
  factory CharacterSet.lower(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters('abcdefghijklmnopqrstuvwxyz');
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.ll,
        ]);
    }
  }

  /// Creates a character set that contains letter characters of
  /// Unicode categories `L*`, `M*`.
  factory CharacterSet.letter(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters(
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
        );
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.ll,
          UnicodeCategory.lm,
          UnicodeCategory.lo,
          UnicodeCategory.lt,
          UnicodeCategory.lu,
          UnicodeCategory.mc,
          UnicodeCategory.me,
          UnicodeCategory.mn,
        ]);
    }
  }

  /// Creates a character set that contains numeric characters of
  /// Unicode category `Nd`.
  factory CharacterSet.digit(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters('0123456789');
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.nd,
        ]);
    }
  }

  /// Creates a character set that contains hexadecimal digit characters
  /// (`0-9a-fA-F`) of ASCII.
  factory CharacterSet.hexDigit() {
    return CharacterSet.fromCharacters('0123456789abcdefABCDEF');
  }

  /// Creates a character set that contains octal digit characters
  /// (`0-7`) of ASCII.
  factory CharacterSet.octalDigit() {
    return CharacterSet.fromCharacters('01234567');
  }

  /// Creates a character set that contains binary digit characters
  /// (`0`, `1`) of ASCII.
  factory CharacterSet.bitDigit() {
    return CharacterSet.fromCharacters('01');
  }

  /// Creates a character set that contains symbol characters of
  /// Unicode categories `S*`.
  ///
  /// If the encoding is [CharacterEncoding.ascii],
  /// characters are `!\'"#\$%&()*+,-./:;<=>?@[]^_`{|}~`.
  factory CharacterSet.symbol(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters('!\'"#\$%&()*+,-./:;<=>?@[]^_`{|}~');
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.sc,
          UnicodeCategory.sk,
          UnicodeCategory.sm,
          UnicodeCategory.so,
        ]);
    }
  }

  /// Creates a character set that contains whitespace characters of
  /// Unicode categories `Z*`.
  ///
  /// If the encoding is [CharacterEncoding.ascii],
  /// characters are whitespace (` `) and tab (`\t`).
  factory CharacterSet.whitespace(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters(' \t');
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.zs,
          UnicodeCategory.zl,
          UnicodeCategory.zp,
        ])
          ..addCodePoints([0x0009]);
    }
  }

  /// Creates a character set that contains newline characters of
  /// Unicode categories `Cc` and
  /// `0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029` code points.
  ///
  /// If the encoding is [CharacterEncoding.ascii],
  /// characters are newline (`\n`) and carriage return (`\r`).
  factory CharacterSet.newline(CharacterEncoding encoding) {
    switch (encoding) {
      case CharacterEncoding.ascii:
        return CharacterSet.fromCharacters('\n\r');
      case CharacterEncoding.utf8:
      case CharacterEncoding.utf16:
        return CharacterSet.fromUnicodeCategories([
          UnicodeCategory.cc,
        ])
          ..addCodePoints(
            [0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029],
          );
    }
  }

  /// Creates a character set that contains [CharacterSet.whitespace] and
  /// [CharacterSet.newline] characters.
  factory CharacterSet.whitespaceAndNewline(CharacterEncoding encoding) {
    final whitespaceSet = CharacterSet.whitespace(encoding);
    final newlinesSet = CharacterSet.newline(encoding);
    whitespaceSet.addCharacterSet(newlinesSet);
    return whitespaceSet;
  }

  final List<CharacterRange> _ranges = [];

  /// Adds code points to the character set.
  void addCodePoints(List<int> codePoints) {
    for (final codePoint in codePoints) {
      _ranges.add(CharacterRange(codePoint, codePoint));
    }
  }

  /// Adds characters to the character set.
  void addCharacters(String string) {
    for (final codeUnit in string.codeUnits) {
      _ranges.add(CharacterRange(codeUnit, codeUnit));
    }
  }

  /// Adds characters of the given character set to the character set.
  void addCharacterSet(CharacterSet other) {
    _ranges.addAll(other._ranges);
  }

  /// Returns whether the character set contains the given code point or not.
  bool contains(int codePoint) {
    for (final range in _ranges) {
      if (range.start <= codePoint && codePoint <= range.end) {
        return true;
      }
    }
    return false;
  }
}

extension CharacterSetPrivate on CharacterSet {
  List<CharacterRange> get ranges => _ranges;

  int? get firstCharacter {
    if (_ranges.isEmpty) {
      return null;
    }
    return _ranges.first.start;
  }
}
