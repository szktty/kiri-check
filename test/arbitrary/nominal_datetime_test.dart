import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'utils.dart';

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  property('check type of value', () {
    testForAll(nominalDateTime(), (value) {
      expect(value, isA<NominalDateTime>());
    });
  });

  property('min', () {
    final min = DateTime(3000);
    final nominalMin = NominalDateTime.fromDateTime(tz.local, min);
    testForAll(nominalDateTime(min: min), (value) {
      expect(value.compareTo(nominalMin) >= 0, isTrue);
    });
  });

  property('max', () {
    final max = DateTime(1000);
    final nominalMax = NominalDateTime.fromDateTime(tz.local, max);
    testForAll(nominalDateTime(max: max), (value) {
      expect(value.compareTo(nominalMax) <= 0, isTrue);
    });
  });

  property('min, max', () {
    final min = DateTime(2500);
    final max = DateTime(3000);
    final nominalMin = NominalDateTime.fromDateTime(tz.local, min);
    final nominalMax = NominalDateTime.fromDateTime(tz.local, max);
    testForAll(
      nominalDateTime(min: min, max: max),
      (value) {
        expect(value.compareTo(nominalMin) >= 0, isTrue);
        expect(value.compareTo(nominalMax) <= 0, isTrue);
      },
    );
  });

  group('imaginary', () {
    const imaginaryEndsOfMonth = [
      (2, 30),
      (2, 31),
      (4, 31),
      (6, 31),
      (9, 31),
      (11, 31),
    ];

    property('basic', () {
      var count = 0;
      testForAll(
        nominalDateTime(imaginary: true),
        (value) {
          for (final end in imaginaryEndsOfMonth) {
            if (value.month == end.$1 && value.day == end.$2) {
              count++;
            }
          }
        },
        tearDownAll: (_) {
          expect(count, greaterThan(0));
        },
      );
    });
  });
}
