import 'package:kiri_check/src/constants.dart';
import 'package:test/test.dart';

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

    test('int64 min and max values', () {
      expect(Constants.int64Min, equals(-9223372036854775808));
      expect(Constants.int64Max, equals(9223372036854775807));
    });

    test('uint8 min and max values', () {
      expect(Constants.uint8Min, equals(0));
      expect(Constants.uint8Max, equals(255));
    });

    test('uint16 min and max values', () {
      expect(Constants.uint16Min, equals(0));
      expect(Constants.uint16Max, equals(65535));
    });

    test('uint32 min and max values', () {
      expect(Constants.uint32Min, equals(0));
      expect(Constants.uint32Max, equals(4294967295));
    });
  });
}
