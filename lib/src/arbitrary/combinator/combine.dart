import 'package:collection/collection.dart';
import 'package:kiri_check/src/property/arbitrary.dart';
import 'package:kiri_check/src/property/property_internal.dart';

// ignore_for_file: null_check_on_nullable_type_parameter

final class CombinatorSet<R, E1, E2, E3, E4, E5, E6, E7, E8> {
  CombinatorSet(
    this.count,
    this.arbitrary1,
    this.arbitrary2,
    this.arbitrary3,
    this.arbitrary4,
    this.arbitrary5,
    this.arbitrary6,
    this.arbitrary7,
    this.arbitrary8,
  ) {
    arbitraries = [
      arbitrary1,
      arbitrary2,
      if (arbitrary3 != null) arbitrary3!,
      if (arbitrary4 != null) arbitrary4!,
      if (arbitrary5 != null) arbitrary5!,
      if (arbitrary6 != null) arbitrary6!,
      if (arbitrary7 != null) arbitrary7!,
      if (arbitrary8 != null) arbitrary8!,
    ];
  }

  final int count;

  late final List<ArbitraryInternal<dynamic>> arbitraries;

  final ArbitraryInternal<E1> arbitrary1;
  final ArbitraryInternal<E2> arbitrary2;
  final ArbitraryInternal<E3>? arbitrary3;
  final ArbitraryInternal<E4>? arbitrary4;
  final ArbitraryInternal<E5>? arbitrary5;
  final ArbitraryInternal<E6>? arbitrary6;
  final ArbitraryInternal<E7>? arbitrary7;
  final ArbitraryInternal<E8>? arbitrary8;

  R transform(List<dynamic> values) {
    switch (count) {
      case 2:
        return (values[0] as E1, values[1] as E2) as R;
      case 3:
        return (values[0] as E1, values[1] as E2, values[2] as E3) as R;
      case 4:
        return (
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
        ) as R;
      case 5:
        return (
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
        ) as R;
      case 6:
        return (
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
          values[5] as E6,
        ) as R;
      case 7:
        return (
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
          values[5] as E6,
          values[6] as E7,
        ) as R;
      case 8:
        return (
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
          values[5] as E6,
          values[6] as E7,
          values[7] as E8,
        ) as R;
      default:
        throw PropertyException('Invalid count: $count');
    }
  }
}

final class CombineArbitrary<R, E1, E2, E3, E4, E5, E6, E7, E8>
    extends ArbitraryBase<R> {
  CombineArbitrary(this._set);

  final CombinatorSet<R, E1, E2, E3, E4, E5, E6, E7, E8> _set;

  // Legacy method for backward compatibility
  R _transform(List<dynamic> values) => _set.transform(values);

  // Get source values from ValueWithState, fall back if needed
  List<dynamic> _getSourceValues(R combinedValue, ValueWithState<R>? valueWithState) {
    // First try to get from ValueWithState sourceValues
    if (valueWithState?.sourceValues != null && 
        valueWithState!.sourceValues!.isNotEmpty) {
      return valueWithState.sourceValues!;
    }
    
    // Fallback: try to regenerate using the stored state
    if (valueWithState?.state != null) {
      final random = RandomContextImpl.fromState(valueWithState!.state, copy: true);
      final regeneratedValues = <dynamic>[];
      for (final arbitrary in _set.arbitraries) {
        regeneratedValues.add(arbitrary.generate(random));
      }
      return regeneratedValues;
    }
    
    // Last resort: throw error
    throw PropertyException('Cannot find source values for $combinedValue');
  }

  @override
  int get enumerableCount => 0;

  @override
  List<R>? get edgeCases => null;

  @override
  bool get isExhaustive => false;

  @override
  String describeExample(R example) {
    try {
      final sourceValues = _getSourceValues(example, null);
      final buffer = StringBuffer('$example combined from (')
        ..write(
          _set.arbitraries
              .mapIndexed((i, g) => g.describeExample(sourceValues[i]))
              .join(', '),
        )
        ..write(')');
      return buffer.toString();
    } catch (_) {
      return '$example (combined)';
    }
  }

  @override
  R getFirst(RandomContext random) =>
      _transform(_set.arbitraries.map((g) => g.getFirst(random)).toList());

  @override
  R generate(RandomContext random) =>
      _transform(_set.arbitraries.map((g) => g.generate(random)).toList());

  @override
  ValueWithState<R> generateWithState(RandomContext random) {
    final values = <dynamic>[];
    
    // Capture state before generating any values
    final randomImpl = random as RandomContextImpl;
    final stateBeforeGeneration = RandomState.fromState(randomImpl.xorshift.state);
    
    for (final arbitrary in _set.arbitraries) {
      final withState = arbitrary.generateWithState(random);
      values.add(withState.value);
    }
    
    final result = _set.transform(values);
    
    return ValueWithState(
      result, 
      stateBeforeGeneration,
      sourceValues: values,
    );
  }

  @override
  R generateRandom(RandomContext random) => _transform(
        _set.arbitraries.map((g) => g.generateRandom(random)).toList(),
      );

  @override
  ShrinkingDistance calculateDistance(R value) {
    try {
      final sourceValues = _getSourceValues(value, null);
      final distance = ShrinkingDistance(0);
      _set.arbitraries.forEachIndexed((i, g) {
        if (i < sourceValues.length) {
          distance.addDimension(g.calculateDistance(sourceValues[i]));
        }
      });
      return distance;
    } catch (_) {
      // Fallback: Try to extract values from the combined result
      final fallbackValues = _extractValuesFromCombined(value);
      if (fallbackValues != null) {
        final distance = ShrinkingDistance(0);
        _set.arbitraries.forEachIndexed((i, g) {
          if (i < fallbackValues.length) {
            distance.addDimension(g.calculateDistance(fallbackValues[i]));
          }
        });
        return distance;
      }
      return ShrinkingDistance(0);
    }
  }

  @override
  List<R> shrink(R value, ShrinkingDistance distance) {
    try {
      final sourceValues = _getSourceValues(value, null);
      return _shrinkWithSourceValues(sourceValues, distance);
    } catch (_) {
      // Fallback: Try to extract values from the combined result
      final fallbackValues = _extractValuesFromCombined(value);
      if (fallbackValues != null) {
        return _shrinkWithSourceValues(fallbackValues, distance);
      }
      return [];
    }
  }
  
  // Try to extract source values from the combined result
  List<dynamic>? _extractValuesFromCombined(R value) {
    try {
      if (value is Record) {
        // Handle tuple types (Records)
        final values = <dynamic>[];
        switch (_set.count) {
          case 2:
            final v = value as (dynamic, dynamic);
            values.addAll([v.$1, v.$2]);
            break;
          case 3:
            final v = value as (dynamic, dynamic, dynamic);
            values.addAll([v.$1, v.$2, v.$3]);
            break;
          case 4:
            final v = value as (dynamic, dynamic, dynamic, dynamic);
            values.addAll([v.$1, v.$2, v.$3, v.$4]);
            break;
          case 5:
            final v = value as (dynamic, dynamic, dynamic, dynamic, dynamic);
            values.addAll([v.$1, v.$2, v.$3, v.$4, v.$5]);
            break;
          case 6:
            final v = value as (dynamic, dynamic, dynamic, dynamic, dynamic, dynamic);
            values.addAll([v.$1, v.$2, v.$3, v.$4, v.$5, v.$6]);
            break;
          case 7:
            final v = value as (dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic);
            values.addAll([v.$1, v.$2, v.$3, v.$4, v.$5, v.$6, v.$7]);
            break;
          case 8:
            final v = value as (dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic);
            values.addAll([v.$1, v.$2, v.$3, v.$4, v.$5, v.$6, v.$7, v.$8]);
            break;
          default:
            return null;
        }
        return values;
      }
    } catch (_) {}
    return null;
  }

  // Helper method for shrinking with known source values
  List<R> _shrinkWithSourceValues(List<dynamic> sourceValues, ShrinkingDistance distance) {
    if (_set.count == 0 || sourceValues.isEmpty || distance.dimensions.isEmpty) {
      return [];
    }
    
    final n = (distance.granularity - 1) % _set.count;
    final depth = (distance.granularity - 1) ~/ _set.count + 1;
    
    if (n >= _set.arbitraries.length || n >= sourceValues.length || n >= distance.dimensions.length) {
      return [];
    }
    
    final targetArbitrary = _set.arbitraries[n];
    final targetDistance = ShrinkingDistance(distance.dimensions[n].baseSize)
      ..granularity = depth;
    
    final targetShrunk = targetArbitrary.shrink(sourceValues[n], targetDistance);
    final shrunk = targetShrunk.map((e) {
      final nextValues = List.of(sourceValues);
      nextValues[n] = e;
      return _transform(nextValues);
    }).toList();
    
    return shrunk;
  }

  // New method that works with ValueWithState for better shrinking
  List<ValueWithState<R>> shrinkWithState(
    ValueWithState<R> valueWithState, 
    ShrinkingDistance distance,
  ) {
    try {
      final sourceValues = _getSourceValues(valueWithState.value, valueWithState);
      final shrunk = _shrinkWithSourceValues(sourceValues, distance);
      
      return shrunk.map((shrunkValue) {
        return ValueWithState(
          shrunkValue,
          valueWithState.state, // Keep original state for reproducibility
          sourceValues: sourceValues, // Keep source values reference
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

abstract class CombineArbitraries {
  static Arbitrary<(E1, E2)> combine2<E1, E2>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
  ) =>
      CombineArbitrary<(E1, E2), E1, E2, dynamic, dynamic, dynamic, dynamic,
          dynamic, dynamic>(
        CombinatorSet(
          2,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          null,
          null,
          null,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<(E1, E2, E3)> combine3<E1, E2, E3>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
  ) =>
      CombineArbitrary<(E1, E2, E3), E1, E2, E3, dynamic, dynamic, dynamic,
          dynamic, dynamic>(
        CombinatorSet(
          3,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          null,
          null,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<(E1, E2, E3, E4)> combine4<E1, E2, E3, E4>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
  ) =>
      CombineArbitrary<(E1, E2, E3, E4), E1, E2, E3, E4, dynamic, dynamic,
          dynamic, dynamic>(
        CombinatorSet(
          4,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          null,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<(E1, E2, E3, E4, E5)> combine5<E1, E2, E3, E4, E5>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
  ) =>
      CombineArbitrary<(E1, E2, E3, E4, E5), E1, E2, E3, E4, E5, dynamic,
          dynamic, dynamic>(
        CombinatorSet(
          5,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          a5 as ArbitraryInternal<E5>,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<(E1, E2, E3, E4, E5, E6)> combine6<E1, E2, E3, E4, E5, E6>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    Arbitrary<E6> a6,
  ) =>
      CombineArbitrary<(E1, E2, E3, E4, E5, E6), E1, E2, E3, E4, E5, E6,
          dynamic, dynamic>(
        CombinatorSet(
          6,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          a5 as ArbitraryInternal<E5>,
          a6 as ArbitraryInternal<E6>,
          null,
          null,
        ),
      );

  static Arbitrary<(E1, E2, E3, E4, E5, E6, E7)>
      combine7<E1, E2, E3, E4, E5, E6, E7>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    Arbitrary<E6> a6,
    Arbitrary<E7> a7,
  ) =>
          CombineArbitrary<(E1, E2, E3, E4, E5, E6, E7), E1, E2, E3, E4, E5, E6,
              E7, dynamic>(
            CombinatorSet(
              7,
              a1 as ArbitraryInternal<E1>,
              a2 as ArbitraryInternal<E2>,
              a3 as ArbitraryInternal<E3>,
              a4 as ArbitraryInternal<E4>,
              a5 as ArbitraryInternal<E5>,
              a6 as ArbitraryInternal<E6>,
              a7 as ArbitraryInternal<E7>,
              null,
            ),
          );

  static Arbitrary<(E1, E2, E3, E4, E5, E6, E7, E8)>
      combine8<E1, E2, E3, E4, E5, E6, E7, E8>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    Arbitrary<E6> a6,
    Arbitrary<E7> a7,
    Arbitrary<E8> a8,
  ) =>
          CombineArbitrary<(E1, E2, E3, E4, E5, E6, E7, E8), E1, E2, E3, E4, E5,
              E6, E7, E8>(
            CombinatorSet(
              8,
              a1 as ArbitraryInternal<E1>,
              a2 as ArbitraryInternal<E2>,
              a3 as ArbitraryInternal<E3>,
              a4 as ArbitraryInternal<E4>,
              a5 as ArbitraryInternal<E5>,
              a6 as ArbitraryInternal<E6>,
              a7 as ArbitraryInternal<E7>,
              a8 as ArbitraryInternal<E8>,
            ),
          );
}
