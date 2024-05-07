import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('generation', () {
    property('basic', () {
      testForAll(set(integer(min: 0, max: 10)), (value) {
        expect(value, isA<Set<int>>());
        for (final e in value) {
          expect(e, inInclusiveRange(0, 10));
        }
      });
    });
  });

  property('shrink', () {
    testForAll(
      set(integer(), minLength: 50),
      (value) {
        expect(value.length, lessThanOrEqualTo(10));
      },
      onFalsify: (value) {
        expect(value.length, 50);
      },
      ignoreFalsify: true,
    );
  });
}
