import 'dart:math' as math;

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/constants.dart';
import 'package:kiri_check/src/random.dart';

final class IntArbitrary extends ArbitraryBase<int> {
  IntArbitrary({int? min, int? max}) {
    this.min = min ?? Constants.intMin;
    this.max = math.max(this.min, max ?? Constants.intMax);
    _initWeightedRanges();
  }

  late final int min;
  late final int max;

  @override
  int get enumerableCount => max - min + 1;

  @override
  List<int>? get edgeCases {
    final cases = <int>[min, max];
    if (min < 0 && 0 < max) {
      cases.add(0);
    }
    return cases;
  }

  @override
  bool get isExhaustive => false;

  @override
  int getFirst(RandomContext random) {
    if (min < 0 && 0 < max) {
      return 0;
    } else {
      return min;
    }
  }

  final _weight = Weight<Range<int>>();

  void _initWeightedRanges() {
    _weight
      ..add(10, Range(min, max))
      ..add(1, Range(min, min))
      ..add(1, Range(max, max));

    if (min <= 0 && 0 <= max) {
      for (var n = 10; n <= 100000; n *= 10) {
        if (min <= 0 - n) {
          _weight.add(10, Range(0 - n, 0));
        }
        if (0 + n <= max) {
          _weight.add(10, Range(0 + n ~/ 10, 0 + n));
        }
      }
      _weight.add(1, Range(0, 0));
    }
  }

  @override
  int generate(RandomContext random) {
    final range = _weight.next(random);
    return _generate(random, range);
  }

  @override
  int generateRandom(RandomContext random) {
    final range = Range(min, max);
    return _generate(random, range);
  }

  int _generate(RandomContext random, Range<int> range) {
    if (range.min < Constants.int32Min || Constants.int32Max < range.max) {
      final bigMin = BigInt.from(range.min);
      final bigMax = BigInt.from(range.max);
      final diff = (bigMax - bigMin).toInt().abs();
      if (diff == 0) {
        return range.min;
      } else {
        return range.min + random.nextInt(diff);
      }
    } else {
      final diff = range.length;
      if (diff == 0) {
        return range.min;
      } else {
        return range.min + random.nextInt(diff);
      }
    }
  }

  @override
  List<int> generateExhaustive() {
    final list = <int>[];
    for (var i = min; i <= max; i++) {
      list.add(i);
    }
    return list;
  }

  @override
  ShrinkingDistance calculateDistance(int value) {
    int size;
    if (min <= 0) {
      size = value;
    } else {
      size = value - min;
    }
    return ShrinkingDistance(size);
  }

  @override
  List<int> shrink(int value, ShrinkingDistance distance) {
    return ArbitraryUtils.shrinkDistance(
      low: math.max(value - distance.baseSize, min),
      high: value,
      granularity: distance.granularity,
    );
  }
}
