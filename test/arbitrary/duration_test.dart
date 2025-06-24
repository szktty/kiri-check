import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('duration', () {
    property('generates durations within default range', () {
      forAll(duration(), (d) {
        expect(d.inMicroseconds, greaterThanOrEqualTo(0));
        expect(d.inDays, lessThanOrEqualTo(365));
      });
    });

    property('generates durations within custom range', () {
      forAll(
        duration(
          min: const Duration(seconds: 1),
          max: const Duration(hours: 1),
        ),
        (d) {
          expect(d.inSeconds, greaterThanOrEqualTo(1));
          expect(d.inHours, lessThanOrEqualTo(1));
        },
      );
    });

    property('generates zero duration when min is zero', () {
      forAll(
        duration(max: const Duration(seconds: 10)),
        (d) {
          expect(d.inMicroseconds, greaterThanOrEqualTo(0));
          expect(d.inSeconds, lessThanOrEqualTo(10));
        },
      );
    });

    property('generates negative durations when min is negative', () {
      forAll(
        duration(
          min: const Duration(seconds: -10),
          max: const Duration(seconds: 10),
        ),
        (d) {
          expect(d.inSeconds, greaterThanOrEqualTo(-10));
          expect(d.inSeconds, lessThanOrEqualTo(10));
        },
      );
    });

    test('edge cases include bounds and zero', () {
      final arb = duration(
        min: const Duration(milliseconds: 100),
        max: const Duration(seconds: 5),
      );

      final edgeCases = getEdgeCases(arb);
      expect(edgeCases, isNotNull);
      expect(edgeCases, isNotEmpty);

      final durations = edgeCases!.map((d) => d.inMilliseconds).toSet();
      expect(durations, contains(100)); // min
      expect(durations, contains(5000)); // max
    });

    test('edge cases include zero when in range', () {
      final arb = duration(
        min: const Duration(seconds: -1),
        max: const Duration(seconds: 1),
      );

      final edgeCases = getEdgeCases(arb);
      expect(edgeCases, isNotNull);
      final durations = edgeCases!.map((d) => d.inMicroseconds).toSet();
      expect(durations, contains(0)); // Duration.zero
    });

    test('shrinks towards smaller values', () {
      final arb = duration(
        max: const Duration(hours: 1),
      );

      const largeDuration = Duration(minutes: 30);
      final shrinks = getShrinks(arb, largeDuration);

      expect(shrinks, isNotEmpty);
      expect(shrinks, contains(Duration.zero));

      // Should contain some intermediate values
      final hasSmallerValues = shrinks.any(
        (d) => d.inMicroseconds > 0 && d < largeDuration,
      );
      expect(hasSmallerValues, isTrue);
    });

    test('shrinks include common duration units', () {
      final arb = duration(
        max: const Duration(days: 1),
      );

      const largeDuration = Duration(hours: 12);
      final shrinks = getShrinks(arb, largeDuration);

      final shrinkValues = shrinks.map((d) => d.inMicroseconds).toSet();

      // Should include common durations within range
      expect(
        shrinkValues,
        contains(const Duration(milliseconds: 1).inMicroseconds),
      );
      expect(shrinkValues, contains(const Duration(seconds: 1).inMicroseconds));
      expect(shrinkValues, contains(const Duration(minutes: 1).inMicroseconds));
      expect(shrinkValues, contains(const Duration(hours: 1).inMicroseconds));
    });

    property('handles same min and max', () {
      forAll(
        duration(
          min: const Duration(seconds: 5),
          max: const Duration(seconds: 5),
        ),
        (d) {
          expect(d, equals(const Duration(seconds: 5)));
        },
      );
    });

    test('validates range constraints', () {
      expect(
        () => duration(
          min: const Duration(seconds: 10),
          max: const Duration(seconds: 5),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    property('can be used with other combinators', () {
      forAll(
        frequency([
          (70, duration(max: const Duration(seconds: 1))),
          (
            30,
            duration(
              min: const Duration(hours: 1),
              max: const Duration(hours: 2),
            )
          ),
        ]),
        (d) {
          expect(d.inMicroseconds, greaterThanOrEqualTo(0));
        },
      );
    });

    property('works with list combinator', () {
      forAll(
        list(duration(max: const Duration(minutes: 1)), maxLength: 5),
        (durations) {
          for (final d in durations) {
            expect(d.inMinutes, lessThanOrEqualTo(1));
          }
        },
      );
    });

    property('microsecond precision is maintained', () {
      forAll(
        duration(
          min: const Duration(microseconds: 1),
          max: const Duration(microseconds: 1000),
        ),
        (d) {
          expect(d.inMicroseconds, greaterThanOrEqualTo(1));
          expect(d.inMicroseconds, lessThanOrEqualTo(1000));
        },
      );
    });
  });
}
