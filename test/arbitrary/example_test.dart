import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:test/test.dart';

class ArbitraryCheck<T> {
  ArbitraryCheck({
    required this.name,
    required this.generator,
    required this.typeChecker,
    double? expectedVariance,
    bool Function(T, T)? comparator,
  }) {
    this.expectedVariance = expectedVariance ?? 0.7;
    this.comparator = comparator ?? (a, b) => a == b;
  }

  final String name;
  final Arbitrary<T> Function() generator;
  final bool Function(dynamic) typeChecker;
  late final double expectedVariance;
  late final bool Function(T, T) comparator;

  void runTests() {
    group('example test for $name', () {
      property('generates value of correct type', () {
        forAll(constant(generator()), (a) {
          final value = a.example();
          expect(
            typeChecker(value),
            isTrue,
            reason: 'Type check failed for $name',
          );
        });
      });

      property('generates values with expected variance', () {
        forAll(constant(generator()), (a) {
          const sampleSize = 100;
          final samples = List.generate(sampleSize, (_) => a.example());
          final uniqueSamples = samples.toSet();
          final actualVariance = uniqueSamples.length / sampleSize;

          expect(
            actualVariance,
            greaterThanOrEqualTo(expectedVariance),
            reason:
                'Expected variance of at least $expectedVariance, but got $actualVariance for $name',
          );
        });
      });

      property('reproduces values with the same RandomState', () {
        forAll(constant(generator()), (a) {
          final state1 = RandomState.fromSeed(42);
          final state2 = RandomState.fromSeed(42);

          final value1 = a.example(state: state1);
          final value2 = a.example(state: state2);
          expect(
            comparator(value1, value2),
            isTrue,
            reason:
                'Failed to reproduce value with the same RandomState for $name',
          );

          if (T != Null && T != bool) {
            final state3 = RandomState.fromSeed(24);
            final value3 = a.example(state: state3);
            expect(
              comparator(value1, value3),
              isFalse,
              reason:
                  'Generated same value with different RandomState for $name',
            );
          }
        });
      });

      property('generates and validates edge cases', () {
        forAll(constant(generator()), (a) {
          final arb = a as ArbitraryInternal<T>;
          final edgeCases = arb.edgeCases;
          if (edgeCases != null && edgeCases.isNotEmpty) {
            for (var i = 0; i < 100; i++) {
              final value = arb.example(edgeCase: true);
              expect(typeChecker(value), isTrue, reason: 'Type check failed');
              expect(value, isIn(edgeCases), reason: 'Edge case not found');
            }
          }
        });
      });
    });
  }
}

void main() {
  KiriCheck.maxExamples = 100;

  final arbitraryChecks = [
    ArbitraryCheck<Null>(
      name: 'null',
      generator: null_,
      typeChecker: (v) => v == null,
      expectedVariance: 0,
    ),
    ArbitraryCheck<bool>(
      name: 'boolean',
      generator: boolean,
      typeChecker: (v) => v is bool,
      expectedVariance: 0.02,
    ),
    ArbitraryCheck<int>(
      name: 'integer',
      generator: integer,
      typeChecker: (v) => v is int,
    ),
    ArbitraryCheck<double>(
      name: 'float',
      generator: float,
      typeChecker: (v) => v is double,
    ),
    ArbitraryCheck<String>(
      name: 'string',
      generator: string,
      typeChecker: (v) => v is String,
    ),
    ArbitraryCheck<List<int>>(
      name: 'list<int>',
      generator: () => list(integer(), minLength: 1),
      typeChecker: (v) => v is List<int>,
      comparator: (a, b) => const ListEquality<int>().equals(a, b),
    ),
    ArbitraryCheck<Map<int, int>>(
      name: 'map<int,int>',
      generator: () => map(integer(), integer(), minLength: 1),
      typeChecker: (v) => v is Map<int, int>,
      comparator: (a, b) => const MapEquality<int, int>().equals(a, b),
    ),
  ];

  for (final check in arbitraryChecks) {
    check.runTests();
  }
}
