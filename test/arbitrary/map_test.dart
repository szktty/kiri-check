import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  property('generation', () {
    testForAll(map(integer(), integer()), (value) {
      expect(value, isA<Map<int, int>>());
    });
  });

  property('min, max', () {
    testForAll(
      map(integer(), integer(), minLength: 50, maxLength: 100),
      (value) {
        expect(value.length, greaterThanOrEqualTo(50));
        expect(value.length, lessThanOrEqualTo(100));
      },
    );
  });

  property('shrink', () {
    testForAll(
      map(integer(), integer(), minLength: 50),
      (value) {
        expect(value.length, lessThan(10));
      },
      onFalsify: (value) {
        expect(value.length, 50);
      },
      ignoreFalsify: true,
    );
  });
}
