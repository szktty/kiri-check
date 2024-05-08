// TODO: stub で web に対応する
abstract class Constants {
  static const intMax = int64Max;
  static const intMin = int64Min;
  static const int8Max = (1 << 7) - 1;
  static const int8Min = -(1 << 7);
  static const int16Max = (1 << 15) - 1;
  static const int16Min = -(1 << 15);
  static const int32Max = (1 << 31) - 1;
  static const int32Min = -(1 << 31);
  static const int64Max = (1 << 63) - 1;
  static const int64Min = -(1 << 63);
  static const uint8Max = (1 << 8) - 1;
  static const uint8Min = 0;
  static const uint16Max = (1 << 16) - 1;
  static const uint16Min = 0;
  static const uint32Max = (1 << 32) - 1;
  static const uint32Min = 0;

  static const doubleMax = 1.7976931348623157e+308;
  static const doubleMin = 2.2250738585072014E-308;
  static const float32Max = 3.4028235e+38;
  static const float32Min = 1.17549435e-38;
}
