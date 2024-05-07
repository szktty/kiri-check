import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/arbitrary/core/string.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/util/character/character_set.dart';

abstract class RunesArbitraries {
  static Arbitrary<Runes> runes({
    int? minLength,
    int? maxLength,
    CharacterSet? characterSet,
  }) =>
      RunesArbitrary(
        minLength: minLength,
        maxLength: maxLength,
        characterSet: characterSet,
      );
}

final class RunesArbitrary extends ArbitraryBase<Runes> {
  RunesArbitrary({
    int? minLength,
    int? maxLength,
    CharacterSet? characterSet,
  }) {
    _stringArbitrary = StringArbitraries.string(
      minLength: minLength,
      maxLength: maxLength,
      characterSet: characterSet,
    ) as ArbitraryInternal<String>;
  }

  late final ArbitraryInternal<String> _stringArbitrary;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<Runes>? get edgeCases => null;

  @override
  Runes generate(RandomContext random) =>
      _stringArbitrary.generate(random).runes;

  @override
  Runes generateRandom(RandomContext random) =>
      _stringArbitrary.generateRandom(random).runes;

  @override
  Runes getFirst(RandomContext random) =>
      _stringArbitrary.getFirst(random).runes;

  @override
  ShrinkingDistance calculateDistance(Runes value) =>
      _stringArbitrary.calculateDistance(String.fromCharCodes(value));

  @override
  List<Runes> shrink(Runes value, ShrinkingDistance distance) =>
      _stringArbitrary
          .shrink(String.fromCharCodes(value), distance)
          .map((s) => s.runes)
          .toList();
}
