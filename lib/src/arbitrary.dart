import 'dart:math' as math;

import 'package:kiri_check/src/arbitrary/manipulation/filter.dart';
import 'package:kiri_check/src/arbitrary/manipulation/flat_map.dart';
import 'package:kiri_check/src/arbitrary/manipulation/map.dart';
import 'package:kiri_check/src/home.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/random_xorshift.dart';

/// Components that generate data and perform shrinking,
/// which are especially crucial elements in property-based testing.
abstract class Arbitrary<T> {
  /// Returns an arbitrary that transforms examples.
  Arbitrary<U> map<U>(U Function(T) f);

  /// Returns an arbitrary from examples.
  Arbitrary<U> flatMap<U>(Arbitrary<U> Function(T) f);

  /// Returns an arbitrary that filters examples.
  ///
  /// `predicate` returns true if each example is valid.
  /// If `predicate` returns false, the example is discarded.
  Arbitrary<T> filter(bool Function(T) predicate);

  /// Generates an example of the data.
  ///
  /// Parameters:
  ///
  /// - `state`: The random state to use when generating data.
  /// - `edgeCase`: If set to true, the edge cases is generated.
  T example({RandomState? state, bool edgeCase = false});
}

abstract class ArbitraryInternal<T> extends Arbitrary<T> {
  /// The number of enumerable values.
  int get enumerableCount => 0;

  /// Whether the data is exhaustive.
  bool get isExhaustive;

  /// The edge cases.
  List<T>? get edgeCases => null;

  /// Returns the first data to pass to the test block when generating data.
  T getFirst(RandomContext random);

  /// Generates all possible data.
  List<T> generateExhaustive();

  /// Generates a random data.
  T generateRandom(RandomContext random);

  /// Generates a data.
  T generate(RandomContext random);

  /// Calculates the distance to the target value.
  ShrinkingDistance calculateDistance(T value);

  /// Returns a list of shrink values.
  /// The number of shrink values should be increased according to
  /// the granularity of the distance.
  List<T> shrink(T value, ShrinkingDistance distance);

  // Returns a string representation of the example.
  String describeExample(T example);
}

abstract class ArbitraryUtils {
  static List<int> shrinkDistance({
    required int low,
    required int high,
    required int granularity,
  }) {
    final division = granularity * 10;
    final shrinks = <int>[];
    final unit = math.max((high - low) ~/ division, 1);

    int? previous;
    for (var i = 1; i < division; i++) {
      final value = high - unit * i;
      if (value == previous || value < low) {
        break;
      }
      shrinks.add(value);
      previous = value;
    }

    if (!shrinks.contains(low)) {
      shrinks.add(low);
    }

    return shrinks;
  }

  static List<int> shrinkLength(
    int length, {
    required int minLength,
    int granularity = 1,
  }) =>
      shrinkDistance(
        low: math.max(minLength, 0),
        high: length,
        granularity: granularity,
      );

  static List<List<T>> shrinkList<T>(List<T> list, {required int minLength}) =>
      shrinkLength(list.length, minLength: minLength)
          .map((e) => list.sublist(0, e))
          .toList();
}

abstract class ArbitraryBase<T> implements ArbitraryInternal<T> {
  @override
  String describeExample(T example) => example.toString();

  @override
  List<T> generateExhaustive() {
    throw UnsupportedError(
      '$runtimeType does not support exhaustive generation',
    );
  }

  @override
  Arbitrary<U> map<U>(U Function(T) f) =>
      MapArbitraryTransformer<T, U>(this, f);

  @override
  Arbitrary<T> filter(bool Function(T) predicate) =>
      FilterArbitraryTransformer(this, predicate);

  @override
  Arbitrary<U> flatMap<U>(Arbitrary<U> Function(T) f) =>
      FlatMapArbitraryTransformer<T, U>(this, f);

  @override
  T example({RandomState? state, bool edgeCase = false}) {
    final random = RandomContextImpl.fromState(
      state ?? Settings.shared.randomStateForExample,
      copy: false,
    );

    if (edgeCase && edgeCases != null) {
      return edgeCases![random.nextInt(edgeCases!.length)];
    } else {
      return generate(random);
    }
  }
}

// Distance to the target value.
// If the shrink target is a collection, the distance is nested (dimension).
// Nested distances have a maximum distance and a total distance,
// but which one to use depends on the shrinker.
final class ShrinkingDistance {
  ShrinkingDistance(this.baseSize);

  // Distance without dimensions.
  int baseSize;

  int get maxSize =>
      baseSize +
      _dimensions.fold(
        0,
        (previous, distance) => math.max(previous, distance.maxSize),
      );

  // Distance with dimensions.
  int get totalSize =>
      baseSize +
      _dimensions.fold(
        0,
        (previous, distance) => previous + distance.totalSize,
      );

  bool get isEmpty => totalSize == 0;

  List<ShrinkingDistance> get dimensions => List.of(_dimensions);

  final List<ShrinkingDistance> _dimensions = [];

  ShrinkingDistance getDimension(int index) {
    if (index < 0 || index >= _dimensions.length) {
      throw RangeError.index(
        index,
        _dimensions,
        'index',
        null,
        _dimensions.length,
      );
    }
    return _dimensions[index];
  }

  // Granularity of the shrink.
  // The minimum value is 1, and it increases each time the shrink is repeated.
  int get granularity => _granularity;

  int _granularity = 1;

  set granularity(int value) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'granularity',
        'must be greater than or equal to 1',
      );
    }
    _granularity = value;
  }

  ShrinkingDistance union(ShrinkingDistance other) {
    final distance = ShrinkingDistance(baseSize + other.baseSize)
      ..granularity = math.max(granularity, other.granularity)
      .._dimensions.addAll(_dimensions)
      .._dimensions.addAll(other._dimensions);
    return distance;
  }

  // add dimension
  void addDimension(ShrinkingDistance other) {
    _dimensions.add(other);
  }

  @override
  String toString() {
    return 'ShrinkingDistance(baseSize: $baseSize, granularity: $granularity, dimensions: $_dimensions)';
  }
}
