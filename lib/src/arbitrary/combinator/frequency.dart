import 'package:kiri_check/src/property/property_internal.dart';

abstract class FrequencyArbitraries {
  static Arbitrary<dynamic> frequency(
    List<(int, Arbitrary<dynamic>)> arbitraries,
  ) =>
      FrequencyArbitrary(arbitraries);
}

final class FrequencyArbitrary extends ArbitraryBase<dynamic> {
  FrequencyArbitrary(List<(int, Arbitrary<dynamic>)> arbitraries) {
    weight = Weight.of(arbitraries);
  }

  late final Weight<Arbitrary<dynamic>> weight;

  @override
  int get enumerableCount => 0;

  @override
  List<dynamic>? get edgeCases => null;

  @override
  bool get isExhaustive => false;

  final Map<dynamic, ArbitraryInternal<dynamic>> _generated = {};

  dynamic _choose(
    RandomContext random,
    dynamic Function(RandomContext) Function(ArbitraryInternal<dynamic>) f,
  ) {
    final arbitrary = weight.next(random) as ArbitraryInternal<dynamic>;
    final value = f(arbitrary)(random);
    _generated[value] = arbitrary;
    return value;
  }

  @override
  dynamic getFirst(RandomContext random) {
    return _choose(random, (gen) => gen.getFirst);
  }

  @override
  dynamic generate(RandomContext random) {
    return _choose(random, (gen) => gen.generate);
  }

  @override
  dynamic generateRandom(RandomContext random) {
    return _choose(random, (gen) => gen.generateRandom);
  }

  @override
  ShrinkingDistance calculateDistance(dynamic value) {
    return _generated[value]!.calculateDistance(value);
  }

  @override
  List<dynamic> shrink(dynamic value, ShrinkingDistance distance) {
    final arbitrary = _generated[value]!;
    final shrunk = arbitrary.shrink(value, distance);
    for (final shrunkValue in shrunk) {
      _generated[shrunkValue] = arbitrary;
    }
    return shrunk;
  }
}
