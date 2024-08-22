import 'package:kiri_check/src/helpers/helpers_internal.dart';
import 'package:test/test.dart';

void main() {
  group('asyncCallOr', () {
    test('returns a non-null value', () async {
      final result = await asyncCallOr(() async => 42, 0);
      expect(result, equals(42));
    });

    test('returns a default value when the function returns null', () async {
      final result = await asyncCallOr(() async => null, 'default');
      expect(result, equals('default'));
    });

    test('returns a non-null value synchronously', () async {
      final result = await asyncCallOr(() => 'sync', 'default');
      expect(result, equals('sync'));
    });

    test('returns a default value when the synchronous function returns null',
        () async {
      final result = await asyncCallOr(() => null, 100);
      expect(result, equals(100));
    });

    test('propagates an exception when the function throws', () async {
      expect(
        () => asyncCallOr(() => throw Exception('Test error'), 'default'),
        throwsException,
      );
    });
  });
}
