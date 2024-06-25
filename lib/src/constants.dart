import 'dart:math' as math;

import 'package:universal_platform/universal_platform.dart';

abstract class Constants {
  static int get safeIntMax => UniversalPlatform.isWeb ? int53Max : int64Max;

  static int get safeIntMin => UniversalPlatform.isWeb ? int53Min : int64Min;

  static const int8Max = (1 << 7) - 1;
  static const int8Min = -(1 << 7);
  static const int16Max = (1 << 15) - 1;
  static const int16Min = -(1 << 15);
  static const int32Max = (1 << 31) - 1;
  static const int32Min = -(1 << 31);

  static int get int53Max => (math.pow(2, 53) - 1).toInt();

  static int get int53Min => -math.pow(2, 53).toInt();

  static int get int64Max => (math.pow(2, 63) - 1).toInt();

  static int get int64Min => -math.pow(2, 63).toInt();

  static const doubleMax = 1.7976931348623157e+308;
  static const doubleMin = 2.2250738585072014E-308;
  static const float32Max = 3.4028235e+38;
  static const float32Min = 1.17549435e-38;
}
