import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

import 'model.dart';

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('shrink', () {
    property('shrink', () {
      forAllStates(
        BankAccountBasicBehavior(),
        (s) {
          // TODO
        },
      );
    });
  });
}
