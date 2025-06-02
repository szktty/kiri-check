import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

void main() {
  group('nonEmpty', () {
    property('string.nonEmpty() generates non-empty strings', () {
      forAll(string().nonEmpty(), (s) {
        expect(s, isNotEmpty);
      });
    });

    property('list.nonEmpty() generates non-empty lists', () {
      forAll(list(integer()).nonEmpty(), (lst) {
        expect(lst, isNotEmpty);
        expect(lst.length, greaterThan(0));
      });
    });

    property('set.nonEmpty() generates non-empty sets', () {
      forAll(set(integer()).nonEmpty(), (s) {
        expect(s, isNotEmpty);
        expect(s.length, greaterThan(0));
      });
    });

    property('map.nonEmpty() generates non-empty maps', () {
      forAll(map(string(), integer()).nonEmpty(), (m) {
        expect(m, isNotEmpty);
        expect(m.length, greaterThan(0));
      });
    });

    property('nonEmpty can be chained with other combinators', () {
      forAll(
        list(string().nonEmpty(), minLength: 1, maxLength: 5).nonEmpty(),
        (strings) {
          expect(strings, isNotEmpty);
          for (final s in strings) {
            expect(s, isNotEmpty);
          }
        },
      );
    });

    property('nonEmpty works with custom types that have isEmpty', () {
      forAll(list(integer(), minLength: 0, maxLength: 10).nonEmpty(), (lst) {
        expect(lst, isNotEmpty);
        expect(lst, isA<List<int>>());
      });
    });

    property('nonEmpty with frequency combinator', () {
      forAll(
        frequency([
          (70, list(integer()).nonEmpty()),
          (30, string().nonEmpty()),
        ]),
        (value) {
          if (value is List) {
            expect(value, isNotEmpty);
          } else if (value is String) {
            expect(value, isNotEmpty);
          }
        },
      );
    });

    property('nonEmpty preserves type information', () {
      forAll(string().nonEmpty(), (s) {
        expect(s, isA<String>());
        expect(s, isNotEmpty);
      });
    });

    property('list type preservation', () {
      forAll(list(string()).nonEmpty(), (lst) {
        expect(lst, isA<List<String>>());
        expect(lst, isNotEmpty);
      });
    });

    property('nonEmpty with oneOf combinator', () {
      forAll(
        oneOf([
          string().nonEmpty(),
          list(integer()).nonEmpty(),
        ]).nonEmpty(),
        (value) {
          if (value is String) {
            expect(value, isNotEmpty);
          } else if (value is List) {
            expect(value, isNotEmpty);
          }
        },
      );
    });

    property('nonEmpty does not affect non-collection types', () {
      forAll(integer().nonEmpty(), (i) {
        expect(i, isA<int>());
        // Integer should be unchanged by nonEmpty
      });
    });

    property('nested nonEmpty collections', () {
      forAll(
        list(list(integer()).nonEmpty()).nonEmpty(),
        (nestedList) {
          expect(nestedList, isNotEmpty);
          for (final innerList in nestedList) {
            expect(innerList, isNotEmpty);
          }
        },
      );
    });

    property('nonEmpty with map of lists', () {
      forAll(
        map(string(), list(integer()).nonEmpty()).nonEmpty(),
        (m) {
          expect(m, isNotEmpty);
          for (final list in m.values) {
            expect(list, isNotEmpty);
          }
        },
      );
    });
  });
}
