import 'dart:math' as math;

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/constants.dart';
import 'package:kiri_check/src/random.dart';

final class FloatStrategy {
  FloatStrategy({
    double? min,
    double? max,
    bool? minExcluded,
    bool? maxExcluded,
    bool? nan,
    bool? infinity,
    double? target,
  }) {
    this.min = min ?? Constants.doubleMin;
    this.max = math.max(this.min, max ?? Constants.doubleMax);
    this.minExcluded = minExcluded ?? false;
    this.maxExcluded = maxExcluded ?? false;
    this.nan = nan ?? false;
    this.infinity = infinity ?? false;
    this.target = target ?? (min ?? 0);
  }

  static const epsilon = 1e-10;

  late final double min;
  late final double max;
  late final bool minExcluded;
  late final bool maxExcluded;
  late final bool nan;
  late final bool infinity;
  late final double target;

  double get adjustedMin => minExcluded ? min + epsilon : min;

  double get adjustedMax => maxExcluded ? max - epsilon : max;

  double adjust(double value) {
    if (value.isNaN) {
      return double.nan;
    } else if (value.isInfinite) {
      return value;
    } else if (value <= adjustedMin) {
      return adjustedMin;
    } else if (value >= adjustedMax) {
      return adjustedMax;
    } else {
      return value;
    }
  }
}

final class FloatArbitrary extends ArbitraryBase<double> {
  FloatArbitrary(this.strategy) {
    _initWeightedRanges();
  }

  final FloatStrategy strategy;

  @override
  int get enumerableCount => 0;

  @override
  List<double>? get edgeCases {
    final cases = <double>[];
    if (strategy.min < 0 && 0 < strategy.max) {
      cases.add(0);
    }
    if (!strategy.minExcluded) {
      cases.add(strategy.min);
    }
    if (!strategy.maxExcluded) {
      cases.add(strategy.max);
    }
    if (strategy.nan) {
      cases.add(double.nan);
    }
    if (strategy.infinity) {
      cases
        ..add(double.infinity)
        ..add(double.negativeInfinity);
    }
    return cases;
  }

  @override
  bool get isExhaustive => false;

  static const epsilon = 1e-10;

  @override
  double getFirst(RandomContext random) {
    if (strategy.min < 0 && 0 < strategy.max) {
      return 0;
    } else {
      return strategy.adjustedMin +
          (strategy.adjustedMax - strategy.adjustedMin) / 2;
    }
  }

  final _weight = Weight<Range<double>>();

  void _initWeightedRanges() {
    final adjustedMin = strategy.adjustedMin;
    final adjustedMax = strategy.adjustedMax;
    final basic = Range(adjustedMin, adjustedMax);

    _weight
      ..add(60, basic)
      ..add(1, Range(adjustedMin, adjustedMin))
      ..add(
        1,
        Range(adjustedMax, adjustedMax),
      );

    if (adjustedMin < 0 && adjustedMax > 0) {
      _weight.add(1, Range(0, 0));
    }

    final middle = basic.round((adjustedMin + adjustedMax) / 2);
    _weight.add(1, Range(middle, middle));

    if (strategy.nan) {
      _weight.add(1, Range(double.nan, double.nan));
    }

    if (strategy.infinity) {
      _weight
        ..add(1, Range(double.infinity, double.infinity))
        ..add(
          1,
          Range(double.negativeInfinity, double.negativeInfinity),
        );
    }

    if (adjustedMin <= -10000 && 10000 <= adjustedMax) {
      _weight
        ..add(10, Range(-10, 10))
        ..add(20, Range(-100, 100))
        ..add(
          20,
          Range(-1000, 1000),
        )
        ..add(20, Range(-10000, 10000));
    }
  }

  @override
  double generate(RandomContext random) {
    final range = _weight.next(random);
    if (range.min.isNaN || range.min.isInfinite) {
      return range.min;
    } else {
      return strategy
          .adjust(random.nextDouble() * (range.max - range.min) + range.min);
    }
  }

  @override
  double generateRandom(RandomContext random) {
    if (strategy.nan || strategy.infinity) {
      final n = random.nextInt(100);
      if (n == 0 && strategy.nan) {
        return double.nan;
      } else if (n == 1 && strategy.infinity) {
        return double.infinity;
      } else if (n == 2 && strategy.infinity) {
        return double.negativeInfinity;
      }
    }

    return strategy.adjust(
      random.nextDouble() * (strategy.adjustedMax - strategy.adjustedMin) +
          strategy.adjustedMin,
    );
  }

  @override
  List<double> generateExhaustive() {
    final list = <double>[];
    for (var i = strategy.adjustedMin; i <= strategy.adjustedMax; i++) {
      list.add(i);
    }
    return list;
  }

  @override
  ShrinkingDistance calculateDistance(double value) {
    double size;
    if (strategy.adjustedMin <= strategy.target) {
      size = value - strategy.target;
    } else {
      size = value - strategy.adjustedMin;
    }
    return ShrinkingDistance(size.toInt());
  }

  @override
  List<double> shrink(double value, ShrinkingDistance distance) {
    final division = distance.granularity * 10;
    final shrinks = <double>[];
    final low = math.max(strategy.adjustedMin, strategy.target);
    final high = value;
    final unit = math.max((high - low) ~/ division, 1);
    double? previous;
    for (var i = 1; i < division; i++) {
      final value = high - unit * i;
      if (value == previous || value < strategy.target || value < low) {
        break;
      }
      shrinks.add(value);
      previous = value;
    }
    return shrinks;
  }
}
