import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('integer', () {
    group('generation', () {
      property('first value', () {
        var i = 0;
        testForAll(integer(), (value) {
          if (i == 0) {
            expect(value, 0);
          }
          i++;
        });
      });

      property('min', () {
        const min = 10;
        testForAll(integer(min: min), (value) {
          expect(value, greaterThanOrEqualTo(min));
        });
      });

      property('max', () {
        const max = 10;
        testForAll(integer(max: max), (value) {
          expect(value, lessThanOrEqualTo(max));
        });
      });

      property('min, max', () {
        const min = 10;
        const max = 20;
        testForAll(
          integer(min: min, max: max),
          (value) {
            expect(value, greaterThanOrEqualTo(min));
            expect(value, lessThanOrEqualTo(max));
          },
          variousRatio: 0.08,
        );
      });

      property('seed', () {
        const seed = 123;
        final examples1 = <int>[];
        final examples2 = <int>[];
        forAll(integer(), examples1.add, seed: seed);
        forAll(
          integer(),
          examples2.add,
          seed: seed,
          tearDown: () {
            expect(
              const DeepCollectionEquality().equals(examples1, examples2),
              isTrue,
            );
          },
        );
      });
    });

    group('shrinking', () {
      property('positive', () {
        const point = 100;
        int? falsify;
        testForAll(
          integer(),
          (value) {
            expect(value, lessThanOrEqualTo(point));
          },
          onFalsify: (example) {
            falsify = example;
          },
          tearDown: (examples) {
            expect(falsify, lessThanOrEqualTo(point + 10));
          },
          ignoreFalsify: true,
        );
      });

      property('negative', () {
        const point = -100;
        int? falsify;
        testForAll(
          integer(),
          (value) {
            expect(value, greaterThanOrEqualTo(point));
          },
          onFalsify: (example) {
            falsify = example;
          },
          tearDown: (examples) {
            expect(falsify, lessThanOrEqualTo(point));
          },
          ignoreFalsify: true,
        );
      });

      property('range', () {
        const min = 10;
        const max = 100;
        int? falsify;
        testForAll(
          integer(min: min, max: max),
          (value) {
            expect(value, lessThanOrEqualTo(min));
          },
          onFalsify: (example) {
            falsify = example;
          },
          tearDown: (examples) {
            expect(falsify, isNotNull);
            expect(falsify, lessThanOrEqualTo(max));
            expect(falsify, greaterThanOrEqualTo(min));
          },
          variousRatio: null,
          ignoreFalsify: true,
        );
      });
    });

    group('edge case policy', () {
      property(
        'none (min, max are excluded)',
        () {
          const min = -10;
          const max = 100;
          testForAll(
            integer(min: min, max: max),
            (value) {
              expect(value != min, isTrue);
              expect(value != max, isTrue);
            },
            edgeCasePolicy: EdgeCasePolicy.none,
            variousRatio: 0.5,
          );
        },
      );

      property('mixin', () {
        const min = 1;
        const max = 10000000;
        var found = 0;
        testForAll(
          integer(min: min, max: max),
          (value) {
            if (value == min || value == max) {
              found++;
            }
          },
          edgeCasePolicy: EdgeCasePolicy.mixin,
          tearDown: (_) {
            expect(found, greaterThanOrEqualTo(0));
          },
        );
      });

      property('first', () {
        const min = -1000000;
        const max = 10000000;
        var found = 0;
        testForAll(
          integer(min: min, max: max),
          (value) {
            if (value == 0 || value == min || value == max) {
              found++;
            }
          },
          edgeCasePolicy: EdgeCasePolicy.first,
          maxExamples: 100,
          tearDown: (_) {
            expect(found, greaterThanOrEqualTo(3));
          },
        );
      });
    });

    group('generation policy', () {
      property('random', () {
        const min = -1000;
        const max = 1000;
        testForAll(
          integer(min: min, max: max),
          (value) {},
          generationPolicy: GenerationPolicy.random,
          variousRatio: 0.8,
        );
      });
    });

    group('shrinking policy', () {
      property('off', () {
        const point = 100;
        var shrunk = false;
        testForAll(
          integer(min: 10000),
          (value) {
            expect(value, lessThanOrEqualTo(point));
          },
          shrinkingPolicy: ShrinkingPolicy.off,
          onShrink: (_) {
            shrunk = true;
          },
          tearDown: (examples) {
            expect(shrunk, isFalse);
          },
          ignoreFalsify: true,
        );
      });

      property('bounded', () {
        const point = 100;
        const maxTries = 3;
        var tries = 0;
        testForAll(
          integer(),
          (value) {
            expect(value, lessThanOrEqualTo(point));
          },
          maxShrinkingTries: maxTries,
          shrinkingPolicy: ShrinkingPolicy.bounded,
          onShrink: (_) {
            tries++;
          },
          tearDown: (examples) {
            expect(tries, maxTries);
          },
          ignoreFalsify: true,
        );
      });
    });
  });
}
