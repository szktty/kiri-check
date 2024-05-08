import 'dart:math' as math;

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';

abstract class MapArbitraries {
  static Arbitrary<Map<K, V>> map<K, V>(
    Arbitrary<K> key,
    Arbitrary<V> value, {
    int? minLength,
    int? maxLength,
  }) =>
      MapArbitrary(
        key as ArbitraryInternal<K>,
        value as ArbitraryInternal<V>,
        min: minLength,
        max: maxLength,
      );
}

final class MapArbitrary<K, V> extends ArbitraryBase<Map<K, V>> {
  MapArbitrary(
    this.key,
    this.value, {
    int? min,
    int? max,
  }) {
    this.minLength = min ?? 0;
    this.maxLength = math.max(this.minLength, max ?? 10);
  }

  final ArbitraryInternal<K> key;
  final ArbitraryInternal<V> value;
  late final int minLength;
  late final int maxLength;

  @override
  int get enumerableCount => 0;

  @override
  List<Map<K, V>>? get edgeCases => null;

  @override
  bool get isExhaustive => false;

  int get _maxGenerationTries => (maxLength * 1.5).toInt();

  @override
  Map<K, V> getFirst(RandomContext random) {
    final map = <K, V>{};
    if (minLength == 0) {
      return map;
    }
    map[key.getFirst(random)] = value.getFirst(random);
    for (var i = 1; i < _maxGenerationTries && map.length < minLength; i++) {
      map[key.generate(random)] = value.generate(random);
    }
    return map;
  }

  @override
  Map<K, V> generate(RandomContext random) {
    final map = <K, V>{};
    final n = random.nextIntInRange(minLength, maxLength);
    for (var i = 1; i < _maxGenerationTries && map.length < n; i++) {
      map[key.generate(random)] = value.generate(random);
    }
    return map;
  }

  @override
  Map<K, V> generateRandom(RandomContext random) {
    final map = <K, V>{};
    final n = random.nextIntInRange(minLength, maxLength);
    for (var i = 1; i < _maxGenerationTries && map.length < n; i++) {
      map[key.generateRandom(random)] = value.generateRandom(random);
    }
    return map;
  }

  @override
  ShrinkingDistance calculateDistance(Map<K, V> value) {
    return ShrinkingDistance(math.max(value.length - minLength, 0));
  }

  @override
  List<Map<K, V>> shrink(Map<K, V> value, ShrinkingDistance distance) {
    return ArbitraryUtils.shrinkLength(distance.baseSize, minLength: minLength)
        .map((e) => Map.fromEntries(value.entries.toList().sublist(0, e)))
        .toList();
  }
}
