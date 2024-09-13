import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('generation', () {
    property('basic', () {
      testForAll(
        oneOf([integer(), float()]),
        (value) {
          expect(value, anyOf(isA<int>(), isA<double>()));
        },
        tearDownAll: (examples) {
          expect(examples.whereType<int>().length, greaterThan(0));
          expect(examples.whereType<double>().length, greaterThan(0));
        },
      );
    });
  });

  group('shrink', () {
    property('first arbitrary', () {
      testForAll(
        oneOf([integer(), float()]),
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
        oneOf([integer(), float()]),
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
