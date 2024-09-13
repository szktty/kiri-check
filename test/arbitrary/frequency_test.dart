import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('generation', () {
    property('check type', () {
      testForAll(
        frequency([
          (1, integer()),
          (1, float()),
        ]),
        (value) {
          expect(value, anyOf(isA<int>(), isA<double>()));
        },
      );
    });

    property('weight', () {
      testForAll(
        frequency([
          (50, integer()),
          (25, float()),
          (25, string()),
        ]),
        (value) {
          expect(value, anyOf(isA<int>(), isA<double>(), isA<String>()));
        },
        tearDownAll: (examples) {
          expect(examples.whereType<int>().length, greaterThan(450));
          expect(examples.whereType<double>().length, greaterThan(200));
          expect(examples.whereType<String>().length, greaterThan(200));
        },
        maxExamples: 1000,
      );
    });
  });

  group('shrink', () {
    property('first arbitrary', () {
      testForAll(
        frequency([
          (1, integer()),
          (2, float()),
        ]),
        (value) {
          expect(value, isA<double>());
        },
        onFalsify: (value) {
          expect(value, isA<int>());
        },
        seed: 123,
        ignoreFalsify: true,
      );
    });

    property('second arbitrary', () {
      testForAll(
        frequency([
          (1, integer()),
          (2, float()),
        ]),
        (value) {
          expect(value, isA<int>());
        },
        onFalsify: (value) {
          expect(value, isA<double>());
        },
        seed: 12305,
        ignoreFalsify: true,
      );
    });
  });
}
