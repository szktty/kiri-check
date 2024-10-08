import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('boolean()', () {
    group('generation', () {
      property('generates both true and false', () {
        testForAll(
          boolean(),
          (value) {},
          tearDownAll: (examples) {
            expect(examples.contains(true), isTrue);
            expect(examples.contains(false), isTrue);
          },
          variousRatio: 0,
        );
      });
    });

    group('edge case policy', () {
      property('none (true and false are always included)', () {
        testForAll(
          boolean(),
          (value) {},
          tearDownAll: (examples) {
            expect(examples.contains(true), isTrue);
            expect(examples.contains(false), isTrue);
          },
          variousRatio: 0,
        );
      });
    });

    group('shrinking policy', () {
      property('off (no shrinking occurs)', () {
        var failed = false;
        var falsify = false;
        var shrink = false;
        testForAll(
          boolean(),
          (value) {
            failed = true;
            fail('error');
          },
          onFalsify: (example) {
            falsify = true;
          },
          onShrink: (example) {
            shrink = true;
          },
          tearDownAll: (_) {
            expect(failed, isTrue);
            expect(falsify, isTrue);
            expect(shrink, isFalse);
          },
          ignoreFalsify: true,
          variousRatio: 0,
        );
      });
    });
  });
}
