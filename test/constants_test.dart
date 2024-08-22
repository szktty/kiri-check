import 'package:kiri_check/src/property/constants.dart';
import 'package:test/test.dart';
import 'package:universal_platform/universal_platform.dart';

void main() {
  group('Integer value tests', () {
    test('int8 min and max values', () {
      expect(Constants.int8Min, equals(-128));
      expect(Constants.int8Max, equals(127));
    });

    test('int16 min and max values', () {
      expect(Constants.int16Min, equals(-32768));
      expect(Constants.int16Max, equals(32767));
    });

    test('int32 min and max values', () {
      expect(Constants.int32Min, equals(-2147483648));
      expect(Constants.int32Max, equals(2147483647));
    });

    if (UniversalPlatform.isWeb) {
      test('safe int min and max values (web)', () {
        expect(Constants.safeIntMin, equals(int.parse('-9007199254740992')));
        expect(Constants.safeIntMax, equals(int.parse('9007199254740991')));
      });
    } else {
      test('safe int min and max values (native)', () {
        expect(Constants.safeIntMin, equals(int.parse('-9223372036854775808')));
        expect(Constants.safeIntMax, equals(int.parse('9223372036854775807')));
      });
    }
  });
}
