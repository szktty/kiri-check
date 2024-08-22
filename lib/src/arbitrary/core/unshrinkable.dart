// bool, etc

import 'package:kiri_check/src/property/arbitrary.dart';

abstract mixin class UnshrinkableArbitrary<T> implements ArbitraryInternal<T> {
  @override
  ShrinkingDistance calculateDistance(T value) {
    return ShrinkingDistance(0);
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    return const [];
  }
}
