import 'dart:math';

import 'package:kiri_check/src/constants.dart';

// xorshift32
final class RandomState {
  RandomState([this.seed]) {
    if (seed != null) {
      if (seed == 0) {
        throw ArgumentError('seed must be non-zero');
      }
      RangeError.checkValueInInterval(seed!, 0, 0x7FFFFFFF);
      x = seed!;
    }
  }

  factory RandomState.fromState(RandomState state) {
    return RandomState(state.seed)..x = state.x;
  }

  // TODO: 他にいい値はある？
  static const int defaultSeed = 88675123;

  int? seed;
  int x = 123456789;
}

final class RandomXorshift implements Random {
  RandomXorshift([int? seed]) {
    state = RandomState(seed);
  }

  factory RandomXorshift.fromState(RandomState state) =>
      RandomXorshift()..state = RandomState.fromState(state);

  late RandomState state;

  int nextInt32() {
    var x = state.x;
    x ^= x << 13;
    x &= 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= x << 5;
    x &= 0xFFFFFFFF;
    state.x = x;
    return x;
  }

  @override
  bool nextBool() {
    return nextInt32() & 1 == 1;
  }

  @override
  double nextDouble() {
    // TODO
    return nextInt32() / 0x7FFFFFFF;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError('max must be greater than or equal to 0: $max');
    }
    var value = nextInt32();
    if (value > Constants.safeIntMax) {
      value = value << 32 | nextInt32();
    }
    return value % max;
  }
}
