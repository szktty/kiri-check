import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  group('float() arbitrary tests', () {
    property('Default parameters', () {
      testForAll(float(), (value) {
        expect(value, isA<double>());
      });
    });

    property('Minimum value specified', () {
      const min = -100.0;
      testForAll(float(min: min), (value) {
        expect(value, greaterThanOrEqualTo(min));
      });
    });

    property('Maximum value specified', () {
      const max = 100.0;
      testForAll(float(max: max), (value) {
        expect(value, lessThanOrEqualTo(max));
      });
    });

    property('Minimum and maximum values specified', () {
      const min = -50.0;
      const max = 50.0;
      testForAll(float(min: min, max: max), (value) {
        expect(value, allOf(greaterThanOrEqualTo(min), lessThanOrEqualTo(max)));
      });
    });

    property('Excluding minimum and maximum values', () {
      const min = 0.0;
      const max = 10.0;
      testForAll(
          float(min: min, max: max, minExcluded: true, maxExcluded: true),
          (value) {
        expect(value, allOf(greaterThan(min), lessThan(max)));
      });
    });

    property('NaN can be generated', () {
      testForAll(
        float(nan: true),
        (value) {},
        tearDown: (examples) {
          expect(examples, contains(isNaN));
        },
        maxExamples: 10000,
      );
    });

    property('Allowing infinity', () {
      testForAll(
        float(infinity: true),
        (value) {},
        tearDown: (examples) {
          expect(examples, contains(double.infinity));
          expect(examples, contains(double.negativeInfinity));
        },
        maxExamples: 10000,
      );
    });

    property('Seed consistency', () {
      const seed = 123;
      final examples1 = <double>[];
      final examples2 = <double>[];

      forAll(float(), examples1.add, seed: seed);
      forAll(
        float(),
        examples2.add,
        seed: seed,
        tearDown: () {
          expect(
            const DeepCollectionEquality().equals(examples1, examples2),
            isTrue,
          );
        },
      );
    });

    group('shrinking', () {
      property('positive', () {
        const point = 100.0;
        double? falsify;
        testForAll(
          float(min: 0, max: 200),
          (value) {
            expect(value, lessThanOrEqualTo(point));
          },
          onFalsify: (example) {
            falsify = example;
          },
          tearDown: (examples) {
            expect(falsify, greaterThan(point));
          },
          ignoreFalsify: true,
        );
      });

      property('negative', () {
        const point = -100.0;
        double? falsify;
        testForAll(
          float(min: -200, max: 0),
          (value) {
            expect(value, greaterThanOrEqualTo(point));
          },
          onFalsify: (example) {
            falsify = example;
          },
          tearDown: (examples) {
            expect(falsify, lessThan(point));
          },
          ignoreFalsify: true,
        );
      });

      property('range', () {
        const min = 10.0;
        const max = 100.0;
        double? falsify;
        testForAll(
          float(min: min, max: max),
          (value) {
            expect(value, lessThan(min));
          },
          onFalsify: (example) {
            falsify = example;
          },
          tearDown: (examples) {
            expect(falsify, greaterThanOrEqualTo(min));
          },
          ignoreFalsify: true,
        );
      });
    });
  });
}
