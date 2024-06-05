import 'package:collection/collection.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/home.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class _BasicArbitrary extends ArbitraryBase<int> {
  @override
  List<int>? get edgeCases => null;

  @override
  int getFirst(RandomContext random) => 100;

  @override
  int generate(RandomContext random) => random.nextIntInRange(20, 29);

  @override
  int generateRandom(RandomContext random) => random.nextIntInRange(30, 39);

  @override
  bool get isExhaustive => false;

  @override
  ShrinkingDistance calculateDistance(int value) {
    return ShrinkingDistance(value);
  }

  @override
  List<int> shrink(int value, ShrinkingDistance distance) {
    final shrunk = <int>[];
    for (var i = 0; i < distance.baseSize; i++) {
      shrunk.add(value - i - 1);
    }
    return shrunk;
  }

  @override
  int get enumerableCount => 0;
}

final class _EnumerableArbitrary extends ArbitraryBase<int> {
  @override
  List<int>? get edgeCases => null;

  @override
  int getFirst(RandomContext random) => 100;

  @override
  int generate(RandomContext random) => random.nextIntInRange(20, 29);

  @override
  int generateRandom(RandomContext random) => random.nextIntInRange(30, 39);

  @override
  bool get isExhaustive => true;

  @override
  List<int> generateExhaustive() => [10, 11, 12, 13, 14, 15, 16, 17, 18, 19];

  @override
  ShrinkingDistance calculateDistance(int value) {
    return ShrinkingDistance(value);
  }

  @override
  List<int> shrink(int value, ShrinkingDistance distance) {
    final shrunk = <int>[];
    for (var i = 0; i < distance.baseSize; i++) {
      shrunk.add(value - i);
    }
    return shrunk;
  }

  @override
  int get enumerableCount => 10;
}

final class _EdgeCaseArbitrary extends ArbitraryBase<int> {
  static const _edgeCases = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  ShrinkingDistance calculateDistance(int value) {
    return ShrinkingDistance(0);
  }

  @override
  List<int>? get edgeCases => _edgeCases;

  @override
  int getFirst(RandomContext random) => 100;

  @override
  int generate(RandomContext random) => generateRandom(random);

  @override
  int generateRandom(RandomContext random) => random.nextIntInRange(0, 100000);

  @override
  bool get isExhaustive => false;

  @override
  List<int> shrink(int value, ShrinkingDistance distance) => [];

  @override
  int get enumerableCount => 0;
}

Arbitrary<int> basic() => _BasicArbitrary();

Arbitrary<int> enumerable() => _EnumerableArbitrary();

Arbitrary<int> edgeCase() => _EdgeCaseArbitrary();

void main() {
  // KiriCheck.verbosity = Verbosity.verbose;

  group('main block', () {
    var executed = false;

    tearDown(() {
      expect(executed, isTrue, reason: 'setUp is not called');
    });

    property('execute', () {
      forAll(
        basic(),
        (value) {
          executed = true;
        },
      );
    });
  });

  group('setUp() and tearDown() callbacks', () {
    var n = 0;
    int? mainExecuted;
    int? setUpCalled;
    int? tearDownCalled;

    tearDown(() {
      expect(setUpCalled, 1);
      expect(mainExecuted, 2);
      expect(tearDownCalled, 3);
    });

    property('execute', () {
      forAll(
        basic(),
        (value) {
          mainExecuted ??= ++n;
        },
        setUp: () {
          setUpCalled ??= ++n;
        },
        tearDown: () {
          tearDownCalled ??= ++n;
        },
      );
    });
  });

  group('number of examples', () {
    property('default examples', () {
      var i = 0;
      forAll(
        basic(),
        (value) {
          i++;
        },
        tearDown: () {
          expect(i, Settings.shared.maxExamples);
        },
      );
    });

    property('specify max examples', () {
      const maxExamples = 1000;
      var i = 0;
      forAll(
        basic(),
        (value) {
          i++;
        },
        maxExamples: maxExamples,
        tearDown: () {
          expect(i, maxExamples);
        },
      );
    });
  });

  group('generation', () {
    property('first value', () {
      int? first;
      forAll(
        basic(),
        (value) {
          first ??= value;
        },
        tearDown: () {
          expect(first, 100);
        },
      );
    });

    property('arbitrary-based', () {
      int? first;
      forAll(basic(), (value) {
        if (first != null) {
          expect(20 <= value && value <= 29, isTrue);
        }
        first ??= value;
      });
    });

    property("arbitrary-based ('auto' policy)", () {
      int? first;
      forAll(
        basic(),
        (value) {
          if (first != null) {
            expect(20 <= value && value <= 29, isTrue);
          }
          first ??= value;
        },
        generationPolicy: GenerationPolicy.auto,
      );
    });

    property('random-based', () {
      int? first;
      forAll(
        basic(),
        (value) {
          if (first != null) {
            expect(30 <= value && value <= 39, isTrue);
          }
          first ??= value;
        },
        generationPolicy: GenerationPolicy.random,
      );
    });

    property('exhaustive', () {
      final values = <int>[];
      forAll(
        enumerable(),
        values.add,
        tearDown: () {
          expect(
            const DeepCollectionEquality().equals(
              values,
              [100, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
            ),
            isTrue,
          );
        },
        generationPolicy: GenerationPolicy.exhaustive,
      );
    });

    property('edge cases first', () {
      final values = <int>[];
      forAll(
        edgeCase(),
        values.add,
        tearDown: () {
          for (final case_ in _EdgeCaseArbitrary._edgeCases) {
            expect(values.contains(case_), isTrue);
          }
        },
        edgeCasePolicy: EdgeCasePolicy.first,
      );
    });

    property('edge cases mixin', () {
      final values = <int>[];
      forAll(
        edgeCase(),
        values.add,
        tearDown: () {
          expect(
            _EdgeCaseArbitrary._edgeCases.any(values.contains),
            isTrue,
            reason: 'edge cases are not included',
          );
        },
        edgeCasePolicy: EdgeCasePolicy.mixin,
      );
    });

    property('edge cases none', () {
      final values = <int>[];
      forAll(
        edgeCase(),
        values.add,
        tearDown: () {
          for (final case_ in _EdgeCaseArbitrary._edgeCases) {
            expect(values.contains(case_), isFalse);
          }
        },
        edgeCasePolicy: EdgeCasePolicy.none,
      );
    });

    property('onGenerate callback', () {
      var called = false;
      forAll(
        basic(),
        (value) {},
        onGenerate: (value) {
          called = true;
        },
        tearDown: () {
          expect(called, isTrue);
        },
      );
    });
  });

  group('shrinking', () {
    property('shrink', () {
      const target = 20;
      const falsify = target + 1;
      forAll(
        basic(),
        (value) {
          expect(value, lessThanOrEqualTo(target));
        },
        onFalsify: (value) {
          expect(value, equals(falsify));
        },
        ignoreFalsify: true,
      );
    });

    property('max shrinking tries', () {
      var tries = 0;
      const max = 10;
      forAll(
        basic(),
        (value) {
          tries++;
          expect(value, lessThanOrEqualTo(0));
        },
        tearDown: () {
          expect(tries, max + 1);
        },
        maxShrinkingTries: max,
        ignoreFalsify: true,
      );
    });

    property('no shrinking', () {
      final values = <int>[];
      forAll(
        basic(),
        (value) {
          values.add(value);
          throw Exception('falsify');
        },
        tearDown: () {
          expect(values, [100]);
        },
        shrinkingPolicy: ShrinkingPolicy.off,
      );
    });

    property('full shrinking', () {
      const target = 0;
      const expectedFalsify = target + 1;
      int? falsify;
      forAll(
        basic(),
        (value) {
          expect(value, equals(target));
        },
        onFalsify: (value) {
          falsify = value;
        },
        tearDown: () {
          expect(falsify, equals(expectedFalsify));
        },
        ignoreFalsify: true,
        maxShrinkingTries: 0,
        shrinkingPolicy: ShrinkingPolicy.full,
      );
    });

    property('onShrink callback', () {
      var called = false;
      forAll(
        basic(),
        (value) {
          throw Exception('falsify');
        },
        onShrink: (value) {
          called = true;
        },
        tearDown: () {
          expect(called, isTrue);
        },
        ignoreFalsify: true,
      );
    });
  });
}
