import 'dart:math' as math;
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';

abstract class SetArbitraries {
  static Arbitrary<Set<T>> set<T>(
    Arbitrary<T> element, {
    int? minLength,
    int? maxLength,
  }) =>
      SetArbitrary(
        element as ArbitraryInternal<T>,
        minLength: minLength,
        maxLength: maxLength,
      );
}

final class SetArbitrary<T> extends ArbitraryBase<Set<T>> {
  SetArbitrary(
    this.element, {
    int? minLength,
    int? maxLength,
  }) {
    this.minLength = minLength ?? 0;
    this.maxLength = math.max(this.minLength, maxLength ?? 10);
  }

  final ArbitraryInternal<T> element;

  late final int minLength;

  late final int maxLength;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => element.isExhaustive;

  @override
  List<Set<T>>? get edgeCases => null;

  @override
  Set<T> getFirst(RandomContext random) {
    return generateRandom(random);
  }

  @override
  Set<T> generateRandom(RandomContext random) {
    final length = random.nextIntInRange(minLength, maxLength);
    final elements = <T>{};
    for (var i = 0; i < length; i++) {
      elements.add(element.generateRandom(random));
    }
    return elements;
  }

  @override
  Set<T> generate(RandomContext random) {
    final length = random.nextIntInRange(minLength, maxLength);
    final elements = <T>{};
    for (var i = 0; i < length; i++) {
      elements.add(element.generate(random));
    }
    return elements;
  }

  @override
  ShrinkingDistance calculateDistance(Set<T> value) {
    return ShrinkingDistance(value.length - minLength);
  }

  @override
  List<Set<T>> shrink(Set<T> value, ShrinkingDistance distance) {
    return ArbitraryUtils.shrinkLength(distance.baseSize, minLength: minLength)
        .map((e) => value.toList().sublist(0, e).toSet())
        .toList();
  }
}
