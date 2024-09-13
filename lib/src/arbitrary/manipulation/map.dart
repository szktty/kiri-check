import 'package:kiri_check/src/property/property_internal.dart';

final class MapArbitraryTransformer<S, T> extends ArbitraryBase<T> {
  MapArbitraryTransformer(this.original, this.transformer);

  final ArbitraryInternal<S> original;
  final Map<T, S> transformed = {};

  final T Function(S) transformer;

  T _transform(S value) {
    final t = transformer(value);
    transformed[t] = value;
    return t;
  }

  S _getFormer(T value) {
    final former = transformed[value];
    if (former == null) {
      throw PropertyException('former value of $value is not found');
    }
    return former;
  }

  @override
  int get enumerableCount => original.enumerableCount;

  @override
  List<T>? get edgeCases => original.edgeCases?.map(transformer).toList();

  @override
  bool get isExhaustive => original.isExhaustive;

  @override
  String describeExample(T example) =>
      '$example transformed from ${original.describeExample(
        transformed[example] as S,
      )}';

  @override
  T getFirst(RandomContext random) => _transform(original.getFirst(random));

  @override
  T generateRandom(RandomContext random) =>
      _transform(original.generateRandom(random));

  @override
  T generate(RandomContext random) => _transform(original.generate(random));

  @override
  List<T> generateExhaustive() =>
      original.generateExhaustive().map(_transform).toList();

  @override
  ShrinkingDistance calculateDistance(T value) {
    return original.calculateDistance(_getFormer(value));
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    return original
        .shrink(_getFormer(value), distance)
        .map(transformer)
        .toList();
  }
}
