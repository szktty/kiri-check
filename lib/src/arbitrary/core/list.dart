import 'dart:math' as math;

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';

abstract class ListArbitraries {
  static Arbitrary<List<T>> list<T>(
    Arbitrary<T> element, {
    int? minLength,
    int? maxLength,
    bool? unique,
    bool Function(T, T)? uniqueBy,
  }) =>
      ListArbitrary(
        element as ArbitraryInternal<T>,
        minLength: minLength,
        maxLength: maxLength,
        unique: unique,
        uniqueBy: uniqueBy,
      );
}

class ListArbitrary<T> extends ArbitraryBase<List<T>> {
  ListArbitrary(
    this.element, {
    int? minLength,
    int? maxLength,
    bool? unique,
    bool Function(T, T)? uniqueBy,
  }) {
    this.minLength = minLength ?? 0;
    this.maxLength = math.max(this.minLength, maxLength ?? 10);
    if (unique ?? false) {
      this.uniqueBy = (a, b) => a == b;
    } else {
      this.uniqueBy = uniqueBy ?? (a, b) => false;
    }
  }

  final ArbitraryInternal<T> element;

  late final int minLength;

  late final int maxLength;

  late final bool Function(T, T) uniqueBy;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => element.isExhaustive;

  @override
  List<List<T>>? get edgeCases => null;

  List<T> _filter(List<T> elements) {
    if (elements.length < 2) {
      return elements;
    }
    final shrunk = <T>[];
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (shrunk.any((e) => uniqueBy(e, element))) {
        continue;
      }
      shrunk.add(element);
    }
    return shrunk;
  }

  @override
  List<T> getFirst(RandomContext random) {
    final length = minLength;
    final elements = <T>[];
    for (var i = 0; i < length; i++) {
      elements.add(element.getFirst(random));
    }
    return _filter(elements);
  }

  @override
  List<T> generateRandom(RandomContext random) {
    final length = random.nextIntInRange(minLength, maxLength);
    final elements = <T>[];
    for (var i = 0; i < length; i++) {
      elements.add(element.generateRandom(random));
    }
    return _filter(elements);
  }

  @override
  List<T> generate(RandomContext random) {
    final length = random.nextIntInRange(minLength, maxLength);
    final elements = <T>[];
    for (var i = 0; i < length; i++) {
      elements.add(element.generate(random));
    }
    return _filter(elements);
  }

  @override
  ShrinkingDistance calculateDistance(List<T> value) {
    return ShrinkingDistance(value.length - minLength);
  }

  @override
  List<List<T>> shrink(List<T> value, ShrinkingDistance distance) {
    return ArbitraryUtils.shrinkLength(distance.baseSize, minLength: minLength)
        .map((e) => value.sublist(0, e))
        .toList();
  }
}
