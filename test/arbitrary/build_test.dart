import 'dart:math';

import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

void main() {
  group('build', () {
    property('basic', () {
      const max = 10000;
      forAll(build(() => Random().nextInt(max)), (n) {
        expect(n, lessThan(max));
      });
    });

    property('shrinking', () {
      const max = 10000;
      var current = 0;
      forAll(
        build(() => Random().nextInt(max)),
        (n) {
          current = n;
          throw Exception('error');
        },
        onFalsify: (n) {
          expect(n, equals(current));
        },
        ignoreFalsify: true,
      );
    });
  });
}
