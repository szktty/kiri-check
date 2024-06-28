// xorshift32

import 'dart:math';

import 'package:universal_platform/universal_platform.dart';

final class RandomState {
  RandomState([this.seed]) {
    if (seed != null) {
      if (seed == 0) {
        throw ArgumentError('seed must be non-zero');
      }
      RangeError.checkValueInInterval(seed!, 0, 0x7FFFFFFF);
    }
  }

  factory RandomState.fromState(RandomState state) {
    return RandomState(state.seed);
  }

  // TODO: 他にいい値はある？
  static const int defaultSeed = 88675123;

  int? seed;
  int x = 123456789;
}

final class NewRandom implements Random {
  NewRandom([int? seed]) {
    state = RandomState(seed);
    if (seed != null) {
      state.x = seed;
    }
  }

  factory NewRandom.fromState(RandomState state) => NewRandom()..state = state;

  RandomState state = RandomState();

  int nextInt32() {
    var x = state.x;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
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
    var value = nextInt32();
    if (UniversalPlatform.isWeb) {
      return nextInt32() % max;
    } else {
      value = value << 32 | nextInt32();
      return value % max;
    }
  }
}
