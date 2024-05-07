import 'package:kiri_check/src/util/datetime.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpDateTime();

  group('nominal datetime', () {
    group('imaginary', () {
      test('no 31', () {});
    });

    test('convert to datetime', () {
      final from = NominalDateTime(tz.local, 2021, 2, 3);
      final to = from.toTZDateTime();
      expect(
        from.location == to.location &&
            from.year == to.year &&
            from.month == to.month &&
            from.day == to.day,
        isTrue,
      );
    });

    test('convert from datetime', () {
      final from = DateTime(2021, 2, 3);
      final to = NominalDateTime.fromDateTime(tz.local, from);
      expect(
        from.year == to.year && from.month == to.month && from.day == to.day,
        isTrue,
      );
    });

    test('convert to distance', () {
      final date1 = NominalDateTime(tz.local, 2021, 2, 29);
      final seconds = date1.distance;
      final date2 = NominalDateTime.fromDistance(tz.local, seconds);
      expect(
        date1.compareTo(date2) == 0,
        isTrue,
        reason: 'date1: $date1, date2: $date2',
      );
    });
  });
}
