import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

import 'sample_behaviors.dart';

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('bank account', () {
    property('base', () {
      runBehavior(BankAccountBehavior());
    });
  });
}
