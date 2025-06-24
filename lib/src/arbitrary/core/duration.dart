import 'dart:math' as math;

import 'package:kiri_check/src/property/property_internal.dart';

/// A generator for [Duration] values with controllable time ranges.
final class DurationArbitrary extends ArbitraryBase<Duration> {
  DurationArbitrary({
    this.minMicroseconds = 0,
    this.maxMicroseconds = _defaultMaxMicroseconds,
  }) : assert(
          minMicroseconds <= maxMicroseconds,
          'minMicroseconds must be less than or equal to maxMicroseconds',
        );

  /// Minimum microseconds for the duration (inclusive).
  final int minMicroseconds;

  /// Maximum microseconds for the duration (inclusive).
  final int maxMicroseconds;

  /// Default maximum: approximately 365 days in microseconds.
  static const int _defaultMaxMicroseconds = 365 * 24 * 60 * 60 * 1000 * 1000;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<Duration>? get edgeCases => [
        Duration(microseconds: minMicroseconds),
        Duration(microseconds: maxMicroseconds),
        if (minMicroseconds <= 0 && 0 <= maxMicroseconds) Duration.zero,
      ];

  @override
  Duration getFirst(RandomContext random) {
    return Duration(microseconds: minMicroseconds);
  }

  @override
  Duration generate(RandomContext random) {
    return generateRandom(random);
  }

  @override
  Duration generateRandom(RandomContext random) {
    final range = maxMicroseconds - minMicroseconds + 1;
    final microseconds = minMicroseconds + random.nextInt(range);
    return Duration(microseconds: microseconds);
  }

  @override
  ShrinkingDistance calculateDistance(Duration value) {
    final microseconds = value.inMicroseconds;
    int distance;
    if (minMicroseconds <= 0) {
      distance = microseconds.abs();
    } else {
      distance = (microseconds - minMicroseconds).abs();
    }
    return ShrinkingDistance(distance);
  }

  @override
  List<Duration> shrink(Duration value, ShrinkingDistance distance) {
    final microseconds = value.inMicroseconds;
    if (microseconds == minMicroseconds) {
      return [];
    }

    final shrinks = <Duration>[
      // Always try the minimum value first
      Duration(microseconds: minMicroseconds),
    ];

    // Try common durations if within range
    final commonDurations = [
      Duration.zero.inMicroseconds,
      const Duration(milliseconds: 1).inMicroseconds,
      const Duration(seconds: 1).inMicroseconds,
      const Duration(minutes: 1).inMicroseconds,
      const Duration(hours: 1).inMicroseconds,
      const Duration(days: 1).inMicroseconds,
    ];

    for (final common in commonDurations) {
      if (common >= minMicroseconds &&
          common < microseconds &&
          common <= maxMicroseconds) {
        shrinks.add(Duration(microseconds: common));
      }
    }

    // Use the shrinking utility for systematic shrinking
    final shrinkValues = ArbitraryUtils.shrinkDistance(
      low: math.max(microseconds - distance.baseSize, minMicroseconds),
      high: microseconds,
      granularity: distance.granularity,
    );

    for (final shrinkValue in shrinkValues) {
      if (shrinkValue >= minMicroseconds && shrinkValue != microseconds) {
        shrinks.add(Duration(microseconds: shrinkValue));
      }
    }

    return shrinks;
  }
}
