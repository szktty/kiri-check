import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';

abstract class OneOfArbitraries {
  static Arbitrary<dynamic> oneOf(List<Arbitrary<dynamic>> arbitraries) =>
      OneOfArbitrary(arbitraries);
}

final class OneOfArbitrary extends ArbitraryBase<dynamic> {
  OneOfArbitrary(this.arbitraries);

  final List<Arbitrary<dynamic>> arbitraries;

  @override
  bool get isExhaustive => false;

  @override
  List<dynamic>? get edgeCases => null;

  @override
  int get enumerableCount => 0;

  final Map<dynamic, ArbitraryInternal<dynamic>> _generated = {};

  dynamic _choose(
    RandomContext random,
    dynamic Function(RandomContext) Function(ArbitraryInternal<dynamic>) f,
  ) {
    final arbitrary = arbitraries[random.nextInt(arbitraries.length)];
    final value = f(arbitrary as ArbitraryInternal<dynamic>)(random);
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
