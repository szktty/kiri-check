import 'dart:math' as math;

import 'package:date_kit/date_kit.dart';
import 'package:kiri_check/src/helpers/helpers_internal.dart';
import 'package:kiri_check/src/property/property_internal.dart';
import 'package:timezone/timezone.dart' as tz;

abstract class DateTimeArbitraries {
  static Arbitrary<tz.TZDateTime> dateTime({
    DateTime? min,
    DateTime? max,
    String? location,
  }) =>
      DateTimeArbitrary(
        min: min,
        max: max,
        location: location,
        imaginary: false,
      );

  static Arbitrary<NominalDateTime> nominalDateTime({
    DateTime? min,
    DateTime? max,
    String? location,
    bool? imaginary,
  }) =>
      NominalDateTimeArbitrary(
        min: min,
        max: max,
        location: location,
        imaginary: imaginary,
      );
}

abstract class DateTimeArbitraryBase<T> extends ArbitraryBase<T> {
  DateTimeArbitraryBase({
    DateTime? min,
    DateTime? max,
    String? location,
    bool? imaginary,
  }) {
    setUpDateTime();

    final baseMin = min ?? DateTime(0);
    final baseMax = max ?? DateTime(9999, 12, 31, 23, 59);
    this.location = location != null ? tz.getLocation(location) : tz.local;
    this.imaginary = imaginary ?? true;

    this.min = tz.TZDateTime.from(baseMin, this.location);
    this.max = tz.TZDateTime.from(
      baseMin.compareTo(baseMax) <= 0 ? baseMax : baseMin,
      this.location,
    );
    final baseTarget = tz.TZDateTime(tz.local, 2000);
    if (this.min.compareTo(baseTarget) < 0 &&
        baseTarget.compareTo(this.max) < 0) {
      target = baseTarget;
    } else {
      target = this.min;
    }

    printDebug('Base datetime: min ${this.min}, max ${this.max}, '
        'location ${this.location}, target $target, imaginary $imaginary');

    initWeightedRanges();
  }

  late final tz.TZDateTime min;
  late final tz.TZDateTime max;

  late final tz.Location location;

  late final bool imaginary;

  late final tz.TZDateTime target;

  tz.TZDateTime get bottom => min.compareTo(target) < 0 ? min : target;

  final mainWeight = Weight<NominalDateTime Function(RandomContext random)>();
  final randomWeight = Weight<NominalDateTime Function(RandomContext random)>();

  void initWeightedRanges() {
    // center range
    final now = tz.TZDateTime.now(location);
    final centerMin = now.tzCopyWith(year: now.year - 25);
    final centerMax = now.tzCopyWith(year: now.year + 25);
    if (min.compareTo(centerMin) <= 0 && centerMax.compareTo(max) <= 0) {
      mainWeight.add(60, (random) {
        return _createRandomDateTime(random, centerMin, centerMax);
      });
    }

    // wide range
    mainWeight.add(30, (random) => _createRandomDateTime(random, min, max));
    randomWeight.add(90, (random) => _createRandomDateTime(random, min, max));

    // imaginary range
    if (imaginary) {
      NominalDateTime createLeapYear(RandomContext random) {
        return _createImaginaryLeapYearDateTime(random, min, max) ??
            _createBasicImaginaryDateTime(random, min, max) ??
            _createRandomDateTime(random, min, max);
      }

      NominalDateTime createOtherYear(RandomContext random) {
        return _createBasicImaginaryDateTime(random, min, max) ??
            _createRandomDateTime(random, min, max);
      }

      mainWeight
        ..add(10, createLeapYear)
        ..add(10, createOtherYear);
      randomWeight.add(10, createOtherYear);
    }
  }

  NominalDateTime _createRandomDateTime(
    RandomContext random,
    tz.TZDateTime min,
    tz.TZDateTime max,
  ) {
    final offset = random.nextIntInRange(
      min.microsecondsSinceEpoch,
      max.microsecondsSinceEpoch,
    );
    return NominalDateTime.fromMicrosecondsSinceEpoch(location, offset);
  }

  NominalDateTime? _createBasicImaginaryDateTime(
    RandomContext random,
    tz.TZDateTime min,
    tz.TZDateTime max,
  ) {
    const monthsWithNo31 = [4, 6, 9, 11];
    final year = min.year + random.nextIntInclusive(max.year - min.year);

    final validMonths = <int>[];
    for (final m in monthsWithNo31) {
      final start = tz.TZDateTime(location, year, m);
      final end = tz.TZDateTime(location, year, m + 1);
      if (min.compareTo(start) <= 0 && end.compareTo(max) <= 0) {
        validMonths.add(m);
      }
    }

    if (validMonths.isEmpty) {
      return null;
    }

    final month = validMonths[random.nextInt(validMonths.length)];
    final date = NominalDateTime(
      location,
      year,
      month,
      31,
      random.nextInt(24),
      random.nextInt(60),
      random.nextInt(60),
      random.nextInt(1000),
      random.nextInt(1000),
    );
    return date;
  }

  NominalDateTime? _createImaginaryLeapYearDateTime(
    RandomContext random,
    tz.TZDateTime min,
    tz.TZDateTime max,
  ) {
    final leapYears = <int>[];
    for (var i = min.year; i <= max.year; i++) {
      if (isLeapYear(DateTime(i))) {
        leapYears.add(i);
      }
    }
    if (leapYears.isEmpty) {
      return null;
    }

    final year = leapYears[random.nextInt(leapYears.length)];
    final day = 29 + random.nextIntInclusive(2);
    return NominalDateTime(
      location,
      year,
      2,
      day,
      random.nextInt(24),
      random.nextInt(60),
      random.nextInt(60),
      random.nextInt(1000),
      random.nextInt(1000),
    );
  }

  NominalDateTime getFirstBase(RandomContext random) {
    if (min.compareTo(target) <= 0 && target.compareTo(max) <= 0) {
      return NominalDateTime.fromDateTime(location, target);
    } else {
      final now = tz.TZDateTime.now(location);
      if (min.compareTo(now) <= 0 && now.compareTo(max) <= 0) {
        return NominalDateTime.fromDateTime(location, now);
      } else if (now.compareTo(min) <= 0) {
        return NominalDateTime.fromDateTime(location, min);
      } else {
        return NominalDateTime.fromDateTime(location, max);
      }
    }
  }

  NominalDateTime generateBase(RandomContext random) {
    return mainWeight.next(random).call(random);
  }

  NominalDateTime generateRandomBase(RandomContext random) {
    return randomWeight.next(random).call(random);
  }
}

final class DateTimeArbitrary extends DateTimeArbitraryBase<tz.TZDateTime> {
  DateTimeArbitrary({
    super.min,
    super.max,
    super.location,
    super.imaginary,
  });

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<tz.TZDateTime>? get edgeCases => null;

  @override
  tz.TZDateTime get bottom => min.compareTo(target) < 0 ? min : target;

  @override
  ShrinkingDistance calculateDistance(tz.TZDateTime value) {
    final distance = math.max(value.distance - target.distance, min.distance);
    return ShrinkingDistance(distance);
  }

  @override
  tz.TZDateTime getFirst(RandomContext random) =>
      getFirstBase(random).toTZDateTime();

  @override
  tz.TZDateTime generate(RandomContext random) =>
      generateBase(random).toTZDateTime();

  @override
  tz.TZDateTime generateRandom(RandomContext random) =>
      generateRandomBase(random).toTZDateTime();

  @override
  List<tz.TZDateTime> shrink(tz.TZDateTime value, ShrinkingDistance distance) {
    final components = ArbitraryUtils.shrinkDistance(
      low: bottom.distance,
      high: value.distance,
      granularity: distance.granularity,
    );
    return components
        .map((e) => TZDateTimePrivate.fromDistance(location, e))
        .toList();
  }
}

final class NominalDateTimeArbitrary
    extends DateTimeArbitraryBase<NominalDateTime> {
  NominalDateTimeArbitrary({
    super.min,
    super.max,
    super.location,
    super.imaginary,
  });

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<NominalDateTime>? get edgeCases => null;

  @override
  ShrinkingDistance calculateDistance(NominalDateTime value) {
    final distance = value.distance - target.distance;
    return ShrinkingDistance(distance);
  }

  @override
  NominalDateTime getFirst(RandomContext random) => getFirstBase(random);

  @override
  NominalDateTime generate(RandomContext random) => generateBase(random);

  @override
  NominalDateTime generateRandom(RandomContext random) =>
      generateRandomBase(random);

  @override
  List<NominalDateTime> shrink(
    NominalDateTime value,
    ShrinkingDistance distance,
  ) {
    return ArbitraryUtils.shrinkDistance(
      low: bottom.distance,
      high: value.distance,
      granularity: distance.granularity,
    ).map((e) => NominalDateTime.fromDistance(location, e)).toList();
  }
}

extension TZDateTimePrivate on tz.TZDateTime {
  static tz.TZDateTime fromDistance(tz.Location location, int value) =>
      tz.TZDateTime.fromMicrosecondsSinceEpoch(location, value);

  int get distance => microsecondsSinceEpoch;

  tz.TZDateTime tzCopyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return tz.TZDateTime(
      location,
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
