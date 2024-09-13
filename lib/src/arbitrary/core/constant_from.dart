import 'package:kiri_check/src/arbitrary/core/unshrinkable.dart';
import 'package:kiri_check/src/property/property_internal.dart';

final class ConstantFromArbitrary<T> extends ArbitraryBase<T>
    with UnshrinkableArbitrary<T> {
  ConstantFromArbitrary(
    this.values, {
    T? first,
    this.isExhaustive = false,
    this.edgeCases,
  }) : _first = first {
    if (values.isEmpty) {
      throw ArgumentError('values must not be empty');
    }
  }

  final List<T> values;

  @override
  final List<T>? edgeCases;

  @override
  int get enumerableCount => values.length;

  @override
  final bool isExhaustive;

  @override
  T getFirst(RandomContext random) => _first ?? values.first;

  final T? _first;

  @override
  T generate(RandomContext random) {
    return values[random.nextInt(values.length)];
  }

  @override
  List<T> generateExhaustive() => values;

  @override
  T generateRandom(RandomContext random) {
    return values[random.nextInt(values.length)];
  }
}
