import 'package:kiri_check/src/arbitrary/top.dart';
import 'package:kiri_check/src/statistics.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/expect.dart';

void main() {
  property('collect values', () {
    final examples = <int>[];
    forAll(
      integer(),
      (n) {
        examples.add(n);
        collect(n);
      },
      tearDown: () {
        final result = Statistics.getResult();
        expect(result.entries.length, examples.length);
        for (var i = 0; i < examples.length; i++) {
          final entry = result.entries[i];
          expect(result.entries[i].values.first, examples[i]);
        }
      },
    );
  });
}
