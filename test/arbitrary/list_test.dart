import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  property('check types', () {
    testForAll(list(integer(min: 0, max: 100), minLength: 50), (value) {
      expect(value, isA<List<int>>());
      for (final i in value) {
        expect(i, isA<int>());
      }
      expect(value.variousRatio, greaterThan(0));
    });
  });

  property('unique', () {
    testForAll(list(integer(min: 0, max: 100), minLength: 50, unique: true),
        (value) {
      expect(value.isUnique, isTrue);
    });
  });

  property('uniqueBy', () {
    testForAll(
      list(
        integer(min: 0, max: 10),
        uniqueBy: (a, b) => a % 2 == b % 2,
        minLength: 50,
      ),
      (value) {
        expect(value.isUnique, isTrue);
      },
    );
  });

  property('shrink', () {
    const min = 50;
    testForAll(
      list(integer(min: 0, max: 100), minLength: min),
      (value) {
        expect(value.length, lessThanOrEqualTo(10));
      },
      onFalsify: (value) {
        expect(value.length, lessThanOrEqualTo(min));
      },
      ignoreFalsify: true,
    );
  });
}

extension ListTestUtil<E> on List<E> {
  bool get isUnique {
    final ratio = variousRatio;
    return ratio == 1 || ratio == null;
  }

  double? get variousRatio {
    if (this.isEmpty) {
      return null;
    } else {
      final set = <E>{};
      for (final e in this) {
        set.add(e);
      }
      return set.length / length;
    }
  }
}
