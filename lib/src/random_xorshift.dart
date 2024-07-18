import 'dart:math';
import 'dart:typed_data';

import 'package:kiri_check/src/constants.dart';
import 'package:universal_platform/universal_platform.dart';

abstract class RandomState {
  static RandomState fromSeed([int? seed]) {
    return RandomStateXorshift(seed: seed);
  }

  static RandomState fromState(RandomState state) {
    return RandomStateXorshift.fromState(state as RandomStateXorshift);
  }

  int get seed;
}

final class RandomStateXorshift extends RandomState {
  RandomStateXorshift({int? seed, int? x}) {
    if (seed != null) {
      if (seed == 0) {
        throw ArgumentError('seed must be non-zero');
      }
      RangeError.checkValueInInterval(seed, 0, 0x7FFFFFFF);
    }
    this.seed = seed ?? defaultSeed;
    this.x = x ?? this.seed;
  }

  factory RandomStateXorshift.fromState(RandomStateXorshift state) {
    return RandomStateXorshift(seed: state.seed, x: state.x);
  }

  static const defaultSeed = 88675123;

  @override
  late int seed;

  late int x;

  @override
  String toString() {
    return 'RandomStateXorshift(seed: $seed, x: $x)';
  }
}

final class RandomXorshift implements Random {
  RandomXorshift([int? seed]) {
    state = RandomStateXorshift(seed: seed);
  }

  factory RandomXorshift.fromState(
    RandomStateXorshift state, {
    required bool copy,
  }) =>
      RandomXorshift()
        ..state = copy ? RandomStateXorshift.fromState(state) : state;

  late RandomStateXorshift state;

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
    if (UniversalPlatform.isWeb) {
      return _nextDoubleWeb();
    } else {
      return _nextDoubleNative();
    }
  }

  double _nextDoubleNative() {
    final lower26 = nextInt(1 << 26);
    final upper26 = nextInt(1 << 26);
    final combined = (upper26 << 26) | lower26;
    final bits = 0x3FF0000000000000 | combined;
    return _bitsToDoubleNative(bits) - 1.0;
  }

  double _bitsToDoubleNative(int value) {
    final uintList = Uint64List(1);
    uintList[0] = value;
    final floatList = Float64List.view(uintList.buffer);
    return floatList[0];
  }

  double _nextDoubleWeb() {
    final lower26 = nextInt(1 << 26);
    final upper26 = nextInt(1 << 26);
    var combined = BigInt.from(upper26);
    combined <<= 26;
    combined |= BigInt.from(lower26);
    final bits = BigInt.parse('3FF0000000000000', radix: 16) | combined;
    return _bitsToDoubleWeb(bits) - 1.0;
  }

  double _bitsToDoubleWeb(BigInt value) {
    final upper = (value >> 32).toInt();
    final lower = (value & BigInt.from(0xffffffff)).toInt();
    final data = ByteData(8)
      ..setInt32(4, lower)
      ..setInt32(0, upper);
    return data.getFloat64(0);
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
