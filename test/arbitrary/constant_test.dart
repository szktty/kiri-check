import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

enum TestEnum { a, b, c }

void main() {
  group('constant', () {
    property('simple', () {
      testForAll(constant(42), (value) {
        expect(value, equals(42));
      }, variousRatio: null,);
    });
  });

  group('constant from values', () {
    property('enum', () {
      testForAll(
        constantFrom(TestEnum.values),
        (value) {
          expect(value, isIn(TestEnum.values));
        },
        variousRatio: null,
      );
    });
  });
}
