import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary/combinator/deck.dart';
import 'package:kiri_check/src/arbitrary/core/integer.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  property('basic', () {
    testForAll(
      deck(),
      (d) {
        final x = d.draw(integer());
        final y = d.draw(integer());
        expect(x, isA<int>());
        expect(y, isA<int>());
      },
      variousRatio: null,
      ignoreFalsify: true,
    );
  });

  group('shrink', () {
    property('simple', () {
      testForAll(
        deck(),
        (d) {
          final x = d.draw(integer());
          expect(x, lessThanOrEqualTo(100));
        },
        onFalsify: (d) {
          final shrunk = d as ShrinkingDeck;
          expect(shrunk.falsifyingExamples, isNotNull);
          final examples = shrunk.falsifyingExamples!;
          expect(examples.length, 1);
          expect(examples.keys.first, isA<IntArbitrary>());
          expect(examples.values.first, lessThanOrEqualTo(200));
          expect(examples.values.first, greaterThanOrEqualTo(100));
        },
        ignoreFalsify: true,
      );
    });

    property('2 generators', () {
      testForAll(
        deck(),
        (d) {
          final x = d.draw(integer(min: 0));
          final y = d.draw(integer(min: 0));
          expect(y, lessThanOrEqualTo(100));
        },
        onFalsify: (d) {
          final shrunk = d as ShrinkingDeck;
          expect(shrunk.falsifyingExamples, isNotNull);
          final examples = shrunk.falsifyingExamples!;
          expect(examples.length, 2);
          expect(examples.keys.first, isA<IntArbitrary>());
          expect(examples.keys.last, isA<IntArbitrary>());
          expect(examples.values.last, greaterThanOrEqualTo(100));
        },
        ignoreFalsify: true,
      );
    });

    property('branch', () {
      final newDraws = <int>[];
      testForAll(
        deck(),
        (d) {
          final x = d.draw(integer(min: 0));
          expect(x, lessThanOrEqualTo(100));
          if (x <= 100) {
            final y = d.draw(integer(min: 0));
            expect(y, isA<int>());
            newDraws.add(y);
          }
        },
        tearDown: (d) {
          expect(newDraws, isNotEmpty);
        },
        ignoreFalsify: true,
      );
    });
  });
}
