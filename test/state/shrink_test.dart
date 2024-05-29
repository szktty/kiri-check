import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

import 'model.dart';

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('bank account', () {
    /*
    property('base', () {
      forAllStates(
        BankAccountBehavior(),
      );
    });
     */

    property('freeze not working', () {
      forAllStates(
        BankAccountFreezeNotWorkingBehavior(),
        seed: 12345,
      );
    });
  });
}
