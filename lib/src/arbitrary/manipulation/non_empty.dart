import 'package:kiri_check/src/property/property_internal.dart';

/// An arbitrary that ensures collections have at least one element.
final class NonEmptyArbitrary<T> extends ArbitraryBase<T> {
  NonEmptyArbitrary(this._base);

  final ArbitraryInternal<T> _base;

  @override
  int get enumerableCount => _base.enumerableCount;

  @override
  bool get isExhaustive => _base.isExhaustive;

  @override
  List<T>? get edgeCases {
    final baseEdgeCases = _base.edgeCases;
    if (baseEdgeCases == null) return null;
    return baseEdgeCases.where((T value) => !_isEmpty(value)).toList();
  }

  @override
  T getFirst(RandomContext random) {
    // Try the base's getFirst first
    final baseFirst = _base.getFirst(random);
    if (!_isEmpty(baseFirst)) {
      return baseFirst;
    }

    // If the base's first value is empty, try generating random values
    var attempts = 0;
    while (true) {
      final value = _base.generateRandom(random);
      if (!_isEmpty(value)) {
        return value;
      }
      attempts++;
      if (attempts > 100) {
        throw PropertyException(
          'Could not generate non-empty value after 100 attempts. '
          'The base arbitrary might only generate empty values.',
        );
      }
    }
  }

  @override
  T generate(RandomContext random) {
    return generateRandom(random);
  }

  @override
  T generateRandom(RandomContext random) {
    var attempts = 0;
    while (true) {
      final value = _base.generateRandom(random);
      if (!_isEmpty(value)) {
        return value;
      }
      attempts++;
      if (attempts > 1000) {
        throw PropertyException(
          'Could not generate non-empty value after 1000 attempts. '
          'The base arbitrary might only generate empty values.',
        );
      }
    }
  }

  @override
  ShrinkingDistance calculateDistance(T value) {
    return _base.calculateDistance(value);
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    final baseShrinks = _base.shrink(value, distance);
    return baseShrinks.where((T shrink) => !_isEmpty(shrink)).toList();
  }

  bool _isEmpty(T value) {
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Set) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }
}
