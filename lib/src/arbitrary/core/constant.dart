import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';

final class ConstantArbitrary<T> extends ArbitraryBase<T> {
  ConstantArbitrary(this.value);

  final T value;

  @override
  bool get isExhaustive => true;

  @override
  List<T>? get edgeCases => [value];

  @override
  int get enumerableCount => 1;

  @override
  T getFirst(RandomContext random) => value;

  @override
  T generate(RandomContext random) => value;

  @override
  List<T> generateExhaustive() {
    return [value];
  }

  @override
  T generateRandom(RandomContext random) {
    return getFirst(random);
  }

  @override
  ShrinkingDistance calculateDistance(T value) {
    return ShrinkingDistance(0);
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    return const [];
  }
}
