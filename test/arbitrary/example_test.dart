import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  property('example generates value of correct type', () {
    final arbitraryTypes =
        <(Arbitrary<dynamic> Function(), bool Function(dynamic))>[
      (null_, (v) => v == null),
      (boolean, (v) => v is bool),
      (integer, (v) => v is int),
      (float, (v) => v is double),
      (string, (v) => v is String),
      (runes, (v) => v is Runes),
      (dateTime, (v) => v is DateTime),
      (binary, (v) => v is List<int>),
      (() => list(integer()), (v) => v is List<int>),
      (() => map(integer(), integer()), (v) => v is Map<int, int>),
      (() => set(integer()), (v) => v is Set<int>),
    ];

    forAll(constantFrom(arbitraryTypes), (arg) {
      final arb = arg.$1();
      final checker = arg.$2;
      final value = arb.example();
      expect(checker(value), isTrue);
    });
  });

  property('example generates values with expected variance', () {
    final arbitrariesWithVariance = <(Arbitrary<dynamic> Function(), double)>[
      /*
      (null_, 0.0),
      (boolean, 0.0),
       */
      (integer, 0.7),

      /*
      (float, 0.7),
      (string, 0.7),

       */
    ];

    forAll(constantFrom(arbitrariesWithVariance), (arg) {
      final arb = arg.$1();
      final expectedVariance = arg.$2;
      const sampleSize = 100;
      final samples = List.generate(sampleSize, (_) => arb.example());

      final uniqueSamples = samples.toSet();
      final actualVariance = uniqueSamples.length / sampleSize;
      print('samples: $samples');

      if (expectedVariance > 0) {
        expect(actualVariance, greaterThanOrEqualTo(expectedVariance),
            reason:
                'Expected variance of at least $expectedVariance, but got $actualVariance for ${arb.runtimeType}');
      } else {
        expect(uniqueSamples.length, equals(1),
            reason:
                'Expected a single unique value for ${arb.runtimeType}, but got ${uniqueSamples.length}');
      }
    });
  });
}
