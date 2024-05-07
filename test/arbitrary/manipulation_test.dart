import 'dart:math' as math;

import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  group('map', () {
    property('generation', () {
      testForAll(
        integer(min: 50, max: 100).map((e) => math.pow(e, 2)),
        (value) {
          expect(value, greaterThanOrEqualTo(2500));
          expect(value, lessThanOrEqualTo(10000));
        },
        variousRatio: 0.1,
      );
    });

    property('shrink', () {
      testForAll(
        integer(min: 50, max: 100).map((e) => math.pow(e, 2)),
        (value) {
          expect(value, value % 15 == 0);
        },
        onFalsify: (value) {
          expect(value, lessThanOrEqualTo(2505));
        },
        variousRatio: 0.1,
        ignoreFalsify: true,
      );
    });
  });

  group('flatMap', () {
    property('generation', () {
      testForAll(
        integer(min: 50, max: 100).flatMap((e) => integer(min: 0, max: e * 10)),
        (value) {
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThanOrEqualTo(1000));
        },
        variousRatio: 0.1,
      );
    });

    property('shrink', () {
      testForAll(
        integer(min: 50, max: 100).flatMap((e) => integer(min: 0, max: e)),
        (value) {
          expect(value, value % 5 == 0);
        },
        onFalsify: (value) {
          expect(value, lessThanOrEqualTo(5));
        },
        variousRatio: 0.1,
        ignoreFalsify: true,
      );
    });
  });

  group('filter', () {
    property('generation', () {
      testForAll(
        integer(min: 50, max: 100).filter((e) => e.isEven),
        (value) {
          expect(value.isEven, isTrue);
        },
        variousRatio: 0.1,
      );
    });

    property('shrink', () {
      testForAll(
        integer(min: 45, max: 100).filter((e) => e.isEven),
        (value) {
          expect(value, value % 10 == 0);
        },
        onFalsify: (value) {
          expect(value, lessThanOrEqualTo(50));
        },
        variousRatio: 0.1,
        ignoreFalsify: true,
      );
    });
  });
}
