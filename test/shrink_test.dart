import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/property/exception.dart';
import 'package:test/test.dart';

const _seed = 20261008;

void main() {
  group('shrinking a failing property', () {
    property('awaits an async block', () {
      int? falsified;
      forAll(
        integer(min: 0, max: 1000),
        (n) async {
          await Future<void>.delayed(Duration.zero);
          expect(n, lessThan(10));
        },
        seed: _seed,
        onFalsify: (n) => falsified = n,
        ignoreFalsify: true,
      );
      addTearDown(() => expect(falsified, 10));
    });

    property('calls setUp and tearDown for each shrunk example', () {
      var fixtureReady = false;
      var setUpCalls = 0;
      var tearDownCalls = 0;
      var shrinkCalls = 0;
      var examples = 0;
      int? falsified;
      forAll(
        integer(min: 0, max: 1000),
        (n) {
          // The fixture is consumed by each run of the block.
          expect(fixtureReady, isTrue);
          fixtureReady = false;
          expect(n, lessThan(10));
        },
        seed: _seed,
        setUp: () {
          fixtureReady = true;
          setUpCalls++;
        },
        tearDown: () => tearDownCalls++,
        onGenerate: (_) => examples++,
        onShrink: (_) => shrinkCalls++,
        onFalsify: (n) => falsified = n,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, 10);
        expect(shrinkCalls, greaterThan(0));
        expect(setUpCalls, examples + shrinkCalls);
        expect(tearDownCalls, examples + shrinkCalls);
      });
    });

    property('shrinks a block throwing an Error', () {
      var setUpCalls = 0;
      var tearDownCalls = 0;
      var tearDownAllCalls = 0;
      int? falsified;
      forAll(
        integer(min: 0, max: 1000),
        (n) {
          if (n >= 10) {
            throw RangeError.range(n, 0, 9, 'n');
          }
        },
        seed: _seed,
        setUp: () => setUpCalls++,
        tearDown: () => tearDownCalls++,
        tearDownAll: () => tearDownAllCalls++,
        onFalsify: (n) => falsified = n,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, 10);
        expect(tearDownCalls, setUpCalls);
        expect(tearDownAllCalls, 1);
      });
    });

    property('awaits async onGenerate and onShrink', () {
      var pending = 0;
      var overlapped = false;
      Future<void> callback(int _) async {
        pending++;
        await Future<void>.delayed(Duration.zero);
        pending--;
      }

      forAll(
        integer(min: 0, max: 1000),
        (n) {
          if (pending > 0) {
            overlapped = true;
          }
          if (n >= 10) {
            throw Exception('n >= 10');
          }
        },
        seed: _seed,
        onGenerate: callback,
        onShrink: callback,
        ignoreFalsify: true,
      );
      addTearDown(() => expect(overlapped, isFalse));
    });
  });

  group('FalsifiedException', () {
    test('shows the original example when shrunk', () {
      final e = FalsifiedException<int>(
        example: 10,
        description: '10',
        originalExample: 736,
        originalDescription: '736',
        seed: _seed,
      );
      expect(
        e.toString(),
        startsWith(
          'Falsifying example: 10 (seed $_seed)\nOriginal example: 736\n',
        ),
      );
    });

    test('omits the original example when not shrunk', () {
      final e = FalsifiedException<int>(
        example: 736,
        description: '736',
        originalExample: 736,
        originalDescription: '736',
      );
      expect(e.toString(), isNot(contains('Original example')));
    });
  });
}
