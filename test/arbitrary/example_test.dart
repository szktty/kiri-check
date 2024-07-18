import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

class ArbitraryCheck<T> {
  ArbitraryCheck({
    required this.name,
    required this.generator,
    required this.typeChecker,
    required this.expectedVariance,
  });

  final String name;
  final Arbitrary<T> Function() generator;
  final bool Function(dynamic) typeChecker;
  final double expectedVariance;

  void runTests() {
    group('example test for $name', () {
      property('generates value of correct type', () {
        forAll(constant(generator()), (a) {
          final value = a.example();
          expect(typeChecker(value), isTrue,
              reason: 'Type check failed for $name');
        });
      });

      property('generates values with expected variance', () {
        forAll(constant(generator()), (a) {
          const sampleSize = 100;
          final samples = List.generate(sampleSize, (_) => a.example());
          final uniqueSamples = samples.toSet();
          final actualVariance = uniqueSamples.length / sampleSize;

          expect(actualVariance, greaterThanOrEqualTo(expectedVariance),
              reason:
                  'Expected variance of at least $expectedVariance, but got $actualVariance for $name');
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
      expectedVariance: 0.7,
    ),
    ArbitraryCheck<double>(
      name: 'float',
      generator: float,
      typeChecker: (v) => v is double,
      expectedVariance: 0.7,
    ),
    ArbitraryCheck<String>(
      name: 'string',
      generator: string,
      typeChecker: (v) => v is String,
      expectedVariance: 0.7,
    ),
    ArbitraryCheck<List<int>>(
      name: 'list<int>',
      generator: () => list(integer()),
      typeChecker: (v) => v is List<int>,
      expectedVariance: 0.7,
    ),
  ];

  for (final check in arbitraryChecks) {
    check.runTests();
  }
}
