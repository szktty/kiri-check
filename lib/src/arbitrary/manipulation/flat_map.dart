import 'package:kiri_check/src/property/arbitrary.dart';
import 'package:kiri_check/src/property/random.dart';

final class FlatMapArbitraryTransformer<S, T> extends ArbitraryBase<T> {
  FlatMapArbitraryTransformer(
    this.original,
    this.transformer,
  );

  final ArbitraryInternal<S> original;

  ArbitraryInternal<T>? transformed;

  final Arbitrary<T> Function(S) transformer;

  ArbitraryInternal<T> _transform(S value) =>
      transformer(value) as ArbitraryInternal<T>;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<T>? get edgeCases => null;

  @override
  T getFirst(RandomContext random) {
    transformed = _transform(original.getFirst(random));
    return transformed!.getFirst(random);
  }

  @override
  T generateRandom(RandomContext random) {
    transformed = _transform(original.generateRandom(random));
    return transformed!.generateRandom(random);
  }

  @override
  T generate(RandomContext random) {
    transformed = _transform(original.generate(random));
    return transformed!.generate(random);
  }

  @override
  ValueWithState<T> generateWithState(RandomContext random) {
    final originalWithState = original.generateWithState(random);
    transformed = _transform(originalWithState.value);
    final transformedWithState = transformed!.generateWithState(random);
    
    return ValueWithState(
      transformedWithState.value,
      originalWithState.state, // Use original state for reproducibility
      sourceValues: [originalWithState.value],
    );
  }

  @override
  List<T> generateExhaustive() {
    throw UnsupportedError('flatMap() does not support exhaustive generation');
  }

  @override
  ShrinkingDistance calculateDistance(T value) {
    return transformed?.calculateDistance(value) ?? ShrinkingDistance(0);
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    return transformed?.shrink(value, distance) ?? <T>[];
  }

  // New method that works with ValueWithState for better shrinking
  List<ValueWithState<T>> shrinkWithState(
    ValueWithState<T> valueWithState, 
    ShrinkingDistance distance,
  ) {
    if (transformed == null) {
      return [];
    }
    
    final shrunk = transformed!.shrink(valueWithState.value, distance);
    return shrunk.map((shrunkValue) {
      return ValueWithState(
        shrunkValue,
        valueWithState.state,
        sourceValues: valueWithState.sourceValues,
      );
    }).toList();
  }
}
