import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('combine2', () {
    property('check type', () {
      testForAll(
        combine2(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine2(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
        },
        ignoreFalsify: true,
      );
    });
  });

  group('combine3', () {
    property('check type', () {
      testForAll(
        combine3(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
          expect(value.$3, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine3(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
          expect(value.$3, 0);
        },
        ignoreFalsify: true,
      );
    });
  });

  group('combine4', () {
    property('check type', () {
      testForAll(
        combine4(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
          expect(value.$3, isA<int>());
          expect(value.$4, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine4(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
          expect(value.$3, 0);
          expect(value.$4, 0);
        },
        ignoreFalsify: true,
      );
    });
  });

  group('combine5', () {
    property('check type', () {
      testForAll(
        combine5(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
          expect(value.$3, isA<int>());
          expect(value.$4, isA<int>());
          expect(value.$5, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine5(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
          expect(value.$3, 0);
          expect(value.$4, 0);
          expect(value.$5, 0);
        },
        ignoreFalsify: true,
      );
    });
  });

  group('combine6', () {
    property('check type', () {
      testForAll(
        combine6(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
          expect(value.$3, isA<int>());
          expect(value.$4, isA<int>());
          expect(value.$5, isA<int>());
          expect(value.$6, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine6(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
          expect(value.$3, 0);
          expect(value.$4, 0);
          expect(value.$5, 0);
          expect(value.$6, 0);
        },
        ignoreFalsify: true,
      );
    });
  });

  group('combine7', () {
    property('check type', () {
      testForAll(
        combine7(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
          expect(value.$3, isA<int>());
          expect(value.$4, isA<int>());
          expect(value.$5, isA<int>());
          expect(value.$6, isA<int>());
          expect(value.$7, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine7(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
          expect(value.$3, 0);
          expect(value.$4, 0);
          expect(value.$5, 0);
          expect(value.$6, 0);
          expect(value.$7, 0);
        },
        ignoreFalsify: true,
      );
    });
  });

  group('combine8', () {
    property('check type', () {
      testForAll(
        combine8(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, isA<int>());
          expect(value.$2, isA<int>());
          expect(value.$3, isA<int>());
          expect(value.$4, isA<int>());
          expect(value.$5, isA<int>());
          expect(value.$6, isA<int>());
          expect(value.$7, isA<int>());
          expect(value.$8, isA<int>());
        },
      );
    });

    property('shrink', () {
      testForAll(
        combine8(
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
          integer(min: 0, max: 10000),
        ),
        (value) {
          expect(value.$1, lessThanOrEqualTo(1000));
        },
        onFalsify: (value) {
          expect(value.$1, lessThanOrEqualTo(1500));
          expect(value.$2, 0);
          expect(value.$3, 0);
          expect(value.$4, 0);
          expect(value.$5, 0);
          expect(value.$6, 0);
          expect(value.$7, 0);
          expect(value.$8, 0);
        },
        ignoreFalsify: true,
      );
    });
  });
}
