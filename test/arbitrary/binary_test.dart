import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('generation', () {
    property('basic', () {
      testForAll(binary(), (value) {
        expect(value, isA<List<int>>());
        for (final e in value) {
          expect(e, inInclusiveRange(0, 255));
        }
      });
    });

    property('min', () {
      testForAll(binary(minLength: 10), (value) {
        expect(value.length, greaterThanOrEqualTo(10));
      });
    });

    property('max', () {
      testForAll(binary(maxLength: 10), (value) {
        expect(value.length, lessThanOrEqualTo(10));
      });
    });

    property('shrink', () {
      testForAll(
        binary(minLength: 50),
        (value) {
          expect(value.length, lessThan(10));
        },
        onFalsify: (value) {
          expect(value.length, greaterThanOrEqualTo(50));
        },
        ignoreFalsify: true,
      );
    });
  });
}
