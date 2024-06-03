import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

import 'sample_behaviors.dart';
import 'sample_model.dart';

final class SubsequenceTestBehavior
    extends Behavior<SubsequenceTestState, Null> {
  @override
  SubsequenceTestState createState() {
    return SubsequenceTestState();
  }

  @override
  Null createSystem(SubsequenceTestState state) {
    return null;
  }

  @override
  List<Command<SubsequenceTestState, Null>> generateCommands(
      SubsequenceTestState state) {
    var n = 0;
    Command<SubsequenceTestState, Null> increment([int value = 1]) {
      n++;
      return Action0('increment $value ($n)', (s, system) {
        s.increment(value);
      }, postcondition: (s, system) => s.value < 100);
    }

    return [
      Sequence('sequence', [
        increment(),
        increment(),
        increment(),
        increment(),
        increment(),
        increment(),
        increment(),
        increment(40),
        increment(),
        increment(40),
        increment(),
        increment(40),
      ]),
    ];
  }
}

final class SubsequenceTestState {
  int value = 0;

  void increment(int value) {
    this.value += value;
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  property('subsequence', () {
    runBehavior(
      SubsequenceTestBehavior(),
      onFalsify: (example) {
        expect(example.steps.length, lessThanOrEqualTo(5));
      },
      ignoreFalsify: true,
    );
  });
}
