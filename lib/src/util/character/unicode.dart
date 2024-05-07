import 'package:kiri_check/src/util/character/unicode_data.dart';

final class UnicodeRange {
  const UnicodeRange(this.start, this.end);

  final int start;

  // included
  final int end;
}

abstract class UnicodeData {
  static List<UnicodeRange> getRanges(UnicodeCategory category) {
    return unicodeCategories[category]!;
  }
}
