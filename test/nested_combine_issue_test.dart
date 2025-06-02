import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/property/exception.dart';
import 'package:test/test.dart';

import 'arbitrary/utils.dart';

void main() {
  group('Issue #23 - Nested combine arbitraries shrinking', () {
    property('good pattern (addition only) - should work without error', () {
      testForAll(
        combine2(
          combine2(integer(), integer()),
          integer(),
        ).map((value) => (value.$1.$1 + value.$1.$2) + value.$2),
        (value) {
          fail('intentional failure for shrinking test');
        },
        ignoreFalsify: true,
      );
    });

    property(
        'bad pattern 1 (multiply inner, add outer) - should work with new implementation',
        () {
      testForAll(
        combine2(
          combine2(integer(), integer()),
          integer(),
        ).map((value) => (value.$1.$1 * value.$1.$2) + value.$2),
        (value) {
          fail('intentional failure for shrinking test');
        },
        ignoreFalsify: true,
      );
    });

    property(
        'bad pattern 2 (add inner, multiply outer) - should work with new implementation',
        () {
      testForAll(
        combine2(
          combine2(integer(), integer()),
          integer(),
        ).map((value) => (value.$1.$1 + value.$1.$2) * value.$2),
        (value) {
          fail('intentional failure for shrinking test');
        },
        ignoreFalsify: true,
      );
    });

    property('complex nesting - multiple levels should work', () {
      testForAll(
        combine3(
          combine2(integer(min: 1, max: 10), integer(min: 1, max: 10)),
          combine2(integer(min: 1, max: 5), integer(min: 1, max: 5)),
          integer(min: 1, max: 3),
        ).map((value) {
          final x = value.$1.$1 * value.$1.$2;
          final y = value.$2.$1 + value.$2.$2;
          final z = value.$3;
          return x + y * z;
        }),
        (value) {
          if (value > 50) {
            fail('value too large: $value');
          }
        },
        ignoreFalsify: true,
      );
    });

    property(
        'map with nested combine - should handle transformations correctly',
        () {
      testForAll(
        combine2(
          integer(min: 1, max: 100),
          integer(min: 1, max: 100),
        ).map((value) => (value.$1 * value.$2).toString()),
        (stringValue) {
          final intValue = int.parse(stringValue);
          if (intValue > 1000) {
            fail('transformed value too large: $stringValue');
          }
        },
        ignoreFalsify: true,
      );
    });

    property('filter with nested combine - should maintain state consistency',
        () {
      testForAll(
        combine2(
          integer(min: 1, max: 20),
          integer(min: 1, max: 20),
        )
            .map((value) => value.$1 * value.$2)
            .filter((value) => value.isEven), // only even products
        (value) {
          if (value > 100) {
            fail('even product too large: $value');
          }
        },
        ignoreFalsify: true,
      );
    });
  });
}
