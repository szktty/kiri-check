import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

Future<String> simulateApiCall(int id) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  if (id < 0) {
    throw Exception('Invalid ID');
  }
  return 'Result for ID: $id';
}

void main() {
  property('Async API call test', () {
    forAll(
      integer(min: -10, max: 100),
      (id) async {
        if (id < 0) {
          expect(() => simulateApiCall(id), throwsException);
        } else {
          final result = await simulateApiCall(id);
          expect(result, startsWith('Result for ID:'));
          expect(result, contains(id.toString()));
        }
      },
    );
  });

  property('Multiple async calls test', () {
    forAll(
      list(integer(min: 0, max: 100), minLength: 1, maxLength: 5),
      (ids) async {
        final futures = ids.map(simulateApiCall);
        final results = await Future.wait(futures);

        expect(results.length, equals(ids.length));
        for (var i = 0; i < ids.length; i++) {
          expect(results[i], contains(ids[i].toString()));
        }
      },
    );
  });
}
