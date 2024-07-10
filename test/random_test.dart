// nextInt, 32/64bit
// nextBool
// nextDouble
// seed

import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/random_xorshift.dart';
import 'package:test/test.dart';

void main() {
  group('xorshift', () {
    test('basic', () {
      const seed = 1234567;
      final random = RandomXorshift(seed);
      expect(random.state.seed, seed, reason: 'seed');

      final expected = [
        42034982,
        3805524628,
        78537300,
        3564389094,
        3644666546,
        2449665511,
        947072312,
        3881073042,
        1688713601,
        3782072586,
      ];
      for (var i = 0; i < expected.length; i++) {
        expect(random.nextInt32(), expected[i], reason: 'count $i');
      }
    });

    group('seed', () {
      test('seed 0', () {
        expect(() => RandomXorshift(0), throwsArgumentError);
      });

      test('fix seed', () {
        const seed = 1234567;
        final r1 = RandomXorshift(seed);
        final r2 = RandomXorshift(seed);
        for (var i = 0; i < 100; i++) {
          expect(r1.nextInt32(), r2.nextInt32());
        }
      });

      test('different seed', () {
        const seed1 = 1234567;
        const seed2 = 7654321;
        final r1 = RandomXorshift(seed1);
        final r2 = RandomXorshift(seed2);
        var same = 0;
        for (var i = 0; i < 1000; i++) {
          if (r1.nextInt32() == r2.nextInt32()) {
            same++;
          }
        }
        expect(same, lessThan(10));
      });
    });

    group('random state', () {
      test('copy state', () {
        final r1 = RandomXorshift()..nextInt32();
        final r2 = RandomXorshift.fromState(r1.state);
        expect(r2.state.seed, r1.state.seed, reason: 'seed');
        expect(r2.state.x, r1.state.x, reason: 'x');

        for (var i = 0; i < 100; i++) {
          expect(r2.nextInt32(), r1.nextInt32());
          expect(r2.state.x, r1.state.x);
        }
      });

      test('rollback state', () {
        final r1 = RandomXorshift();
        final s1 = RandomState.fromState(r1.state);
        final values = <int>[];
        for (var i = 0; i < 100; i++) {
          values.add(r1.nextInt32());
        }

        r1.state = s1;
        for (var i = 0; i < 100; i++) {
          expect(r1.nextInt32(), values[i]);
        }
      });
    });

    // TODO: bool, int, double
  });

  group('default random', () {
    test('bool', () {
      final random =
          RandomContextImpl(DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF);
      const n = 1000;
      var trues = 0;
      for (var i = 0; i < n; i++) {
        if (random.nextBool()) {
          trues++;
        }
      }
      expect(n - trues, lessThan(600));
    });

    group('int', () {
      test('equality', () {
        final random = RandomContextImpl(
          DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF,
        );
        var lt100 = 0;
        var lt200 = 0;
        var lt300 = 0;
        var lt400 = 0;
        var lt500 = 0;
        var lt600 = 0;
        var lt700 = 0;
        var lt800 = 0;
        var lt900 = 0;
        var lt1000 = 0;
        for (var i = 0; i < 1000; i++) {
          final value = random.nextInt(1000);
          expect(value, lessThan(1000));
          if (value < 100) {
            lt100++;
          } else if (value < 200) {
            lt200++;
          } else if (value < 300) {
            lt300++;
          } else if (value < 400) {
            lt400++;
          } else if (value < 500) {
            lt500++;
          } else if (value < 600) {
            lt600++;
          } else if (value < 700) {
            lt700++;
          } else if (value < 800) {
            lt800++;
          } else if (value < 900) {
            lt900++;
          } else if (value < 1000) {
            lt1000++;
          }
        }
        expect(lt100, greaterThan(50));
        expect(lt200, greaterThan(50));
        expect(lt300, greaterThan(50));
        expect(lt400, greaterThan(50));
        expect(lt500, greaterThan(50));
        expect(lt600, greaterThan(50));
        expect(lt700, greaterThan(50));
        expect(lt800, greaterThan(50));
        expect(lt900, greaterThan(50));
        expect(lt1000, greaterThan(50));
      });

      test('edge cases (0, max)', () {
        final random = RandomContextImpl(
          DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF,
        );
        const max = 100;
        var hasZero = false;
        var hasMax = false;
        for (var i = 0; i < 100000; i++) {
          final value = random.nextInt(max + 1);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThanOrEqualTo(max));
          if (value == 0) {
            hasZero = true;
          } else if (value == max) {
            hasMax = true;
          }
        }
        expect(hasZero, isTrue);
        expect(hasMax, isTrue);
      });
    });
  });
}
