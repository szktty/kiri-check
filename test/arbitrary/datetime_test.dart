import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'utils.dart';

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  group('datetime', () {
    property('check type of value', () {
      testForAll(dateTime(), (value) {
        expect(value, isA<tz.TZDateTime>());
      });
    });

    property('min', () {
      final min = DateTime(3000);
      final tzMin = tz.TZDateTime.from(min, tz.local);
      testForAll(dateTime(min: min), (value) {
        expect(value.compareTo(tzMin) >= 0, isTrue);
      });
    });

    property('max', () {
      final max = DateTime(1000);
      testForAll(dateTime(max: max), (value) {
        expect(value.compareTo(max) <= 0, isTrue);
      });
    });

    property('min, max', () {
      final min = DateTime(2500);
      final max = DateTime(3000);
      testForAll(
        dateTime(min: min, max: max),
        (value) {
          expect(value.compareTo(min) >= 0, isTrue);
          expect(value.compareTo(max) <= 0, isTrue);
        },
      );
    });

    group('timezone', () {
      property('basic', () {
        String name;
        if (tz.local.name == 'Asia/Tokyo') {
          name = 'Europe/London';
        } else {
          name = 'Asia/Tokyo';
        }
        testForAll(dateTime(location: name), (value) {
          expect(value.location.name, name);
        });
      });
    });

    property('shrinking', () {
      final target = DateTime(2001, 2);
      final falsify = DateTime(2001, 3);
      testForAll(
        dateTime(min: DateTime(2000)),
        (value) {
          expect(value.isAfter(target), isFalse);
        },
        onFalsify: (value) {
          expect(value.isBefore(falsify), isTrue);
        },
        ignoreFalsify: true,
      );
    });
  });
}
