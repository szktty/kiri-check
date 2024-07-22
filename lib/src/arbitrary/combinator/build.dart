import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/random.dart';

abstract class BuildArbitraries {
  static Arbitrary<T> build<T>(T Function() builder) => BuildArbitrary(builder);
}

final class BuildArbitrary<T> extends ArbitraryBase<T> {
  BuildArbitrary(this._builder);

  final T Function() _builder;

  @override
  int get enumerableCount => 0;

  @override
  List<T>? get edgeCases => null;

  @override
  bool get isExhaustive => false;

  @override
  T getFirst(RandomContext random) => _builder();

  @override
  T generate(RandomContext random) => _builder();

  @override
  T generateRandom(RandomContext random) => _builder();

  @override
  List<T> generateExhaustive() => throw PropertyException(
        'build arbitrary does not support exhaustive generation',
      );

  @override
  ShrinkingDistance calculateDistance(T value) => ShrinkingDistance(0);

  @override
  List<T> shrink(T value, ShrinkingDistance distance) => [];
}
