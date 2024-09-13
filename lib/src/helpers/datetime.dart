import 'package:date_kit/date_kit.dart' as kit;
import 'package:meta/meta.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

bool _dateTimeInitialized = false;

void setUpDateTime() {
  if (!_dateTimeInitialized) {
    _dateTimeInitialized = true;
    tz.initializeTimeZones();
  }
}

const yearUnit = 31536000000000;
const monthUnit = 2592000000000;
const dayUnit = 86400000000;
const hourUnit = 3600000000;
const minuteUnit = 60000000;
const secondUnit = 1000000;
const millisecondUnit = 1000;

/// Datetime exactly as numerically represented.
/// Unlike `DateTime`, it does not validate for authenticity,
/// so it can hold imaginary dates as they are.
final class NominalDateTime implements Comparable<NominalDateTime> {
  /// Creates a nominal datetime.
  NominalDateTime(
    this.location,
    this.year, [
    this.month = 1,
    this.day = 1,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
    this.microsecond = 0,
  ]);

  /// @nodoc
  @internal
  factory NominalDateTime.fromDistance(tz.Location location, int value) {
    var temp = value;
    final year = value ~/ yearUnit;
    temp -= year * yearUnit;
    final month = temp ~/ monthUnit;
    temp -= month * monthUnit;
    final day = temp ~/ dayUnit;
    temp -= day * dayUnit;
    final hour = temp ~/ hourUnit;
    temp -= hour * hourUnit;
    final minute = temp ~/ minuteUnit;
    temp -= minute * minuteUnit;
    final second = temp ~/ secondUnit;
    temp -= second * secondUnit;
    final millisecond = temp ~/ millisecondUnit;
    temp -= millisecond * millisecondUnit;
    final microsecond = temp;
    return NominalDateTime(
      location,
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// Creates a nominal datetime from a `TZDateTime`.
  factory NominalDateTime.fromTZDateTime(tz.TZDateTime dateTime) =>
      NominalDateTime(
        dateTime.location,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );

  /// Creates a nominal datetime from a `DateTime`.
  factory NominalDateTime.fromDateTime(
    tz.Location location,
    DateTime dateTime,
  ) =>
      NominalDateTime.fromTZDateTime(tz.TZDateTime.from(dateTime, location));

  /// @nodoc
  @internal
  factory NominalDateTime.fromMicrosecondsSinceEpoch(
    tz.Location location,
    int microseconds,
  ) {
    final tzDateTime = tz.TZDateTime.fromMicrosecondsSinceEpoch(
      location,
      microseconds,
    );
    return NominalDateTime.fromTZDateTime(tzDateTime);
  }

  /// The time zone.
  final tz.Location location;

  /// The year.
  final int year;

  /// The month.
  final int month;

  /// The day.
  final int day;

  /// The hour.
  final int hour;

  /// The minute.
  final int minute;

  /// The second.
  final int second;

  /// The millisecond.
  final int millisecond;

  /// The microsecond.
  final int microsecond;

  /// `true` if the year is a leap year.
  bool get isLeapYear => kit.isLeapYear(DateTime(year));

  /// `true` if the date is not exist.
  bool get isImaginary {
    if (month == 2) {
      if (day == 30 || day == 31) {
        return true;
      }
      if (day == 29 && !isLeapYear) {
        return true;
      }
    }
    if (day == 31) {
      return [4, 6, 9, 11].contains(month);
    }
    return false;
  }

  /// @nodoc
  @internal
  int get distance =>
      year * yearUnit +
      month * monthUnit +
      day * dayUnit +
      hour * hourUnit +
      minute * minuteUnit +
      second * secondUnit +
      millisecond * millisecondUnit +
      microsecond;

  /// Converts to a `TZDateTime`.
  tz.TZDateTime toTZDateTime() => tz.TZDateTime(
        location,
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );

  /// Creates a new nominal datetime from this one by
  /// updating individual properties.
  NominalDateTime copyWith({
    tz.Location? location,
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) =>
      NominalDateTime(
        location ?? this.location,
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
      );

  @override
  String toString() {
    return 'NominalDateTime($year-$month-$day $hour:$minute:'
        '$second.$millisecond.$microsecond)';
  }

  @internal
  static List<NominalDateTime> specialDates(
    tz.Location location,
    DateTime start,
    DateTime end, {
    required bool imaginary,
  }) {
    final dates = <NominalDateTime>[];
    for (var i = start.year; i <= end.year; i++) {
      final base = NominalDateTime(location, i);
      dates.addAll([
        base,
        base.copyWith(month: 1, day: 31),
        base.copyWith(month: 2, day: 28),
        base.copyWith(month: 3, day: 31),
        base.copyWith(month: 4, day: 30),
        base.copyWith(month: 5, day: 31),
        base.copyWith(month: 6, day: 30),
        base.copyWith(month: 7, day: 31),
        base.copyWith(month: 8, day: 31),
        base.copyWith(month: 9, day: 30),
        base.copyWith(month: 10, day: 31),
        base.copyWith(month: 11, day: 30),
        base.copyWith(month: 12, day: 31),
      ]);

      if (kit.isLeapYear(DateTime(i))) {
        dates.add(base.copyWith(month: 2, day: 29));
      }

      if (imaginary) {
        dates.addAll([
          base.copyWith(month: 2, day: 30),
          base.copyWith(month: 2, day: 31),
          base.copyWith(month: 4, day: 31),
          base.copyWith(month: 6, day: 31),
          base.copyWith(month: 9, day: 31),
          base.copyWith(month: 11, day: 31),
        ]);

        if (!kit.isLeapYear(DateTime(i))) {
          dates.add(base.copyWith(month: 2, day: 29));
        }
      }
    }

    return dates;
  }

  @override
  int compareTo(NominalDateTime other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    if (day != other.day) {
      return day.compareTo(other.day);
    }
    if (hour != other.hour) {
      return hour.compareTo(other.hour);
    }
    if (minute != other.minute) {
      return minute.compareTo(other.minute);
    }
    if (second != other.second) {
      return second.compareTo(other.second);
    }
    if (millisecond != other.millisecond) {
      return millisecond.compareTo(other.millisecond);
    }
    return microsecond.compareTo(other.microsecond);
  }
}
