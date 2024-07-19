import 'dart:math' as math;
import 'dart:math';

import 'package:kiri_check/src/random_xorshift.dart';

abstract class RandomContext implements Random {
  int? get seed;

  // Generates a non-negative random integer uniformly distributed in the range
  // from 0, inclusive, to max, exclusive.
  //
  // kiri-check's default implementation supports 64 bit integers
  // between 1 and (1<<64) inclusive.
  //
  // Example:
  //
  // ```dart
  // var intValue = Random().nextInt(10); // Value is >= 0 and < 10.
  // intValue = Random().nextInt(100) + 50; // Value is >= 50 and < 150.
  // ```
  @override
  int nextInt(int max);

  int nextIntInclusive(int max) => nextInt(max + 1);

  int nextIntInRange(int min, int max) => nextIntInclusive(max - min) + min;

  Element nextElement<Element>(List<Element> elements);
}

final class RandomContextImpl extends RandomContext {
  RandomContextImpl._();

  factory RandomContextImpl.fromSeed(int? seed) {
    return RandomContextImpl._()..xorshift = RandomXorshift(seed);
  }

  factory RandomContextImpl.fromState(RandomState state, {required bool copy}) {
    final state0 = state as RandomStateXorshift;
    return RandomContextImpl._()
      ..xorshift = RandomXorshift.fromState(state0, copy: copy);
  }

  @override
  int? get seed => xorshift.state.seed;

  late final RandomXorshift xorshift;

  @override
  int nextInt(int max) => xorshift.nextInt(max);

  @override
  double nextDouble() => xorshift.nextDouble();

  @override
  bool nextBool() => xorshift.nextBool();

  @override
  Element nextElement<Element>(List<Element> elements) {
    return elements[xorshift.nextInt(elements.length)];
  }

  @override
  String toString() {
    return 'RandomContext(seed: ${xorshift.state.seed}, state: ${xorshift.state.x})';
  }
}

final class Weight<T> {
  Weight();

  factory Weight.of(List<(int, T)> elements) {
    final weight = Weight<T>();
    for (final element in elements) {
      weight.add(element.$1, element.$2);
    }
    return weight;
  }

  List<(int, T)> get values => List.of(_values);

  final List<(int, T)> _values = [];

  int get total => _values.fold<int>(0, (sum, item) => sum + item.$1);

  void add(int weight, T value) {
    _values.add((weight, value));
  }

  T next(RandomContext random) {
    final total = this.total;
    var r = random.nextInt(total);
    for (final item in _values) {
      r -= item.$1;
      if (r < 0) {
        return item.$2;
      }
    }
    throw StateError('unreachable');
  }

  static T select<T>(List<(int, T)> elements, RandomContext random) =>
      Weight.of(elements).next(random);

  @override
  String toString() => 'Weight($_values)';
}

final class Range<T extends num> {
  Range(this.min, this.max) {
    if (min > max) {
      throw ArgumentError('min $min must be less than or equal to max $max');
    }
  }

  final T min;
  final T max;

  T get length {
    if (T == int) {
      return (max - min).abs() as T;
    } else if (T == double) {
      return (max - min).abs() as T;
    } else {
      throw StateError('unreachable');
    }
  }

  T round(T value) {
    return math.min(max, math.max(min, value));
  }

  bool contains(T value) => min <= value && value <= max;

  bool containsRange(Range<T> range) => min <= range.min && range.max <= max;

  @override
  String toString() => 'Range($min, $max)';
}
