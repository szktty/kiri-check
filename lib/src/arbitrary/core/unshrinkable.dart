// bool, etc

import 'package:kiri_check/src/arbitrary.dart';

abstract mixin class UnshrinkableArbitrary<T> implements Arbitrary<T> {
  @override
  ShrinkingDistance calculateDistance(T value) {
    return ShrinkingDistance(0);
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    return const [];
  }
}
