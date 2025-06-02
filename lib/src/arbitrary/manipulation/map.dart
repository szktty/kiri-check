import 'package:kiri_check/src/property/arbitrary.dart';
import 'package:kiri_check/src/property/property_internal.dart';

final class MapArbitraryTransformer<S, T> extends ArbitraryBase<T> {
  MapArbitraryTransformer(this.original, this.transformer);

  final ArbitraryInternal<S> original;
  final T Function(S) transformer;

  // Legacy method for backward compatibility
  T _transform(S value) => transformer(value);

  // Get source value from ValueWithState, fall back to cache if needed
  S _getSourceValue(T transformedValue, ValueWithState<T>? valueWithState) {
    // First try to get from ValueWithState sourceValues
    if (valueWithState?.sourceValues != null &&
        valueWithState!.sourceValues!.isNotEmpty) {
      return valueWithState.sourceValues!.first as S;
    }

    // Fallback: try to regenerate using the stored state
    if (valueWithState?.state != null) {
      final random =
          RandomContextImpl.fromState(valueWithState!.state, copy: true);
      return original.generate(random);
    }

    // Last resort: throw error
    throw PropertyException('Cannot find source value for $transformedValue');
  }

  @override
  int get enumerableCount => original.enumerableCount;

  @override
  List<T>? get edgeCases => original.edgeCases?.map(transformer).toList();

  @override
  bool get isExhaustive => original.isExhaustive;

  @override
  String describeExample(T example) {
    try {
      final sourceValue = _getSourceValue(example, null);
      return '$example transformed from ${original.describeExample(sourceValue)}';
    } catch (_) {
      return '$example (transformed)';
    }
  }

  @override
  T getFirst(RandomContext random) => _transform(original.getFirst(random));

  @override
  T generateRandom(RandomContext random) =>
      _transform(original.generateRandom(random));

  @override
  T generate(RandomContext random) => _transform(original.generate(random));

  @override
  ValueWithState<T> generateWithState(RandomContext random) {
    final originalWithState = original.generateWithState(random);
    final transformedValue = transformer(originalWithState.value);
    return ValueWithState(
      transformedValue,
      originalWithState.state,
      sourceValues: [originalWithState.value],
    );
  }

  @override
  List<T> generateExhaustive() =>
      original.generateExhaustive().map(_transform).toList();

  @override
  ShrinkingDistance calculateDistance(T value) {
    // Try multiple approaches to get the source value
    try {
      final sourceValue = _getSourceValue(value, null);
      return original.calculateDistance(sourceValue);
    } catch (_) {
      // If we can't find the source, return minimal distance
      return ShrinkingDistance(0);
    }
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    try {
      final sourceValue = _getSourceValue(value, null);
      return original.shrink(sourceValue, distance).map(transformer).toList();
    } catch (_) {
      // If we can't shrink, return empty list
      return [];
    }
  }

  // New method that works with ValueWithState for better shrinking
  List<ValueWithState<T>> shrinkWithState(
    ValueWithState<T> valueWithState,
    ShrinkingDistance distance,
  ) {
    try {
      final sourceValue = _getSourceValue(valueWithState.value, valueWithState);
      final shrunkSources = original.shrink(sourceValue, distance);

      return shrunkSources.map((shrunkSource) {
        final transformedShrunk = transformer(shrunkSource);
        return ValueWithState(
          transformedShrunk,
          valueWithState.state, // Keep original state
          sourceValues: [shrunkSource],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
