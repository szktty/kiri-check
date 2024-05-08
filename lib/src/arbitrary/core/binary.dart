import 'dart:math' as math;
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';

abstract class BinaryArbitraries {
  static Arbitrary<List<int>> binary({
    int? minLength,
    int? maxLength,
  }) =>
      BinaryArbitrary(
        minLength: minLength,
        maxLength: maxLength,
      );
}

final class BinaryArbitrary extends ArbitraryBase<List<int>> {
  BinaryArbitrary({
    int? minLength,
    int? maxLength,
  }) {
    this.minLength = minLength ?? 0;
    this.maxLength = math.max(this.minLength, maxLength ?? 100);

    if (this.minLength < 0) {
      throw ArgumentError('minLength must not be negative');
    }
    if (this.maxLength < 0) {
      throw ArgumentError('maxLength must not be negative');
    }
    if (this.minLength > this.maxLength) {
      throw ArgumentError('minLength must not be greater than maxLength');
    }
  }

  late final int minLength;

  late final int maxLength;

  final int target = 0;

  int get bottom => minLength > target ? minLength : target;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<List<int>>? get edgeCases => null;

  @override
  List<int> getFirst(RandomContext random) {
    if (bottom == 0) {
      return [];
    } else {
      return List.filled(bottom, 0);
    }
  }

  @override
  List<int> generate(RandomContext random) {
    return generateRandom(random);
  }

  @override
  List<int> generateRandom(RandomContext random) {
    final length = random.nextIntInRange(minLength, maxLength);
    return List.generate(
      length,
      (_) => random.nextInt(256),
    );
  }

  @override
  ShrinkingDistance calculateDistance(List<int> value) {
    return ShrinkingDistance(value.length);
  }

  @override
  List<List<int>> shrink(
    List<int> value,
    ShrinkingDistance distance,
  ) {
    return ArbitraryUtils.shrinkList(value, minLength: minLength);
  }
}
