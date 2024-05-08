import 'dart:math' as math;

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/random.dart';

import 'package:kiri_check/src/util/character/character_set.dart';

abstract class StringArbitraries {
  static Arbitrary<String> string({
    int? minLength,
    int? maxLength,
    CharacterSet? characterSet,
  }) =>
      StringArbitrary(
        minLength: minLength,
        maxLength: maxLength,
        characterSet: characterSet,
      );
}

final class StringArbitrary extends ArbitraryBase<String> {
  StringArbitrary({
    int? minLength,
    int? maxLength,
    CharacterSet? characterSet,
  }) {
    this.minLength = minLength ?? 0;
    this.maxLength = math.max(this.minLength, maxLength ?? 100);
    this.characterSet =
        characterSet ?? CharacterSet.all(CharacterEncoding.utf8);

    if (this.minLength < 0) {
      throw ArgumentError('min must not be negative');
    }
    if (this.maxLength < 0) {
      throw ArgumentError('max must not be negative');
    }
    if (this.minLength > this.maxLength) {
      throw ArgumentError('min must not be greater than max');
    }
  }

  late final int minLength;

  late final int maxLength;

  late final CharacterSet characterSet;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<String>? get edgeCases => null;

  @override
  String getFirst(RandomContext random) {
    if (minLength == 0) {
      return '';
    } else {
      final first = characterSet.firstCharacter;
      if (first != null) {
        final codeUnits = List<int>.filled(minLength, first);
        return String.fromCharCodes(codeUnits);
      } else {
        throw PropertyException('character set must not be empty');
      }
    }
  }

  @override
  String generate(RandomContext random) {
    return generateRandom(random);
  }

  @override
  String generateRandom(RandomContext random) {
    final length = (maxLength - minLength > 0
            ? random.nextInt(maxLength - minLength)
            : 0) +
        minLength;
    return _generateRandom(random, length);
  }

  String _generateRandom(RandomContext random, int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      final n = random.nextInt(characterSet.ranges.length);
      final range = characterSet.ranges[n];
      final code = random.nextInt(range.end + 1 - range.start) + range.start;
      buffer.writeCharCode(code);
    }
    return buffer.toString();
  }

  @override
  ShrinkingDistance calculateDistance(String value) {
    return ShrinkingDistance(value.length);
  }

  @override
  List<String> shrink(String value, ShrinkingDistance distance) {
    return ArbitraryUtils.shrinkDistance(
      low: math.max(value.length - distance.baseSize, minLength),
      high: value.length,
      granularity: distance.granularity,
    ).map((n) => value.substring(0, n)).toList();
  }

  @override
  String describeExample(String example) {
    return "'$example' ${example.codeUnits}";
  }
}
