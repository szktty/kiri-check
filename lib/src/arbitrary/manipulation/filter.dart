import 'package:kiri_check/src/property/arbitrary.dart';
import 'package:kiri_check/src/property/random.dart';

final class FilterException implements Exception {}

final class FilterArbitraryTransformer<T> extends ArbitraryBase<T> {
  FilterArbitraryTransformer(this.original, this.predicate);

  final ArbitraryInternal<T> original;
  final bool Function(T) predicate;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<T>? get edgeCases => null;

  T _satisfy(T example) {
    if (predicate(example)) {
      return example;
    } else {
      throw FilterException();
    }
  }

  @override
  T getFirst(RandomContext random) => _satisfy(original.getFirst(random));

  @override
  T generate(RandomContext random) => _satisfy(original.generate(random));

  @override
  ValueWithState<T> generateWithState(RandomContext random) {
    final originalWithState = original.generateWithState(random);
    final satisfiedValue = _satisfy(originalWithState.value);
    return ValueWithState(
      satisfiedValue,
      originalWithState.state,
      sourceValues: originalWithState.sourceValues,
    );
  }

  @override
  T generateRandom(RandomContext random) =>
      _satisfy(original.generateRandom(random));

  @override
  List<T> generateExhaustive() =>
      original.generateExhaustive().where(predicate).toList();

  @override
  ShrinkingDistance calculateDistance(T value) =>
      original.calculateDistance(value);

  @override
  List<T> shrink(T value, ShrinkingDistance distance) =>
      original.shrink(value, distance).where(predicate).toList();

  // New method that works with ValueWithState for better shrinking
  List<ValueWithState<T>> shrinkWithState(
    ValueWithState<T> valueWithState, 
    ShrinkingDistance distance,
  ) {
    final shrunk = original.shrink(valueWithState.value, distance);
    final filteredShrunk = shrunk.where(predicate).toList();
    
    return filteredShrunk.map((shrunkValue) {
      return ValueWithState(
        shrunkValue,
        valueWithState.state,
        sourceValues: valueWithState.sourceValues,
      );
    }).toList();
  }
}
