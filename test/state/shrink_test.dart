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

final class FlagTestBehavior extends Behavior<FlagTestState, Null> {
  @override
  FlagTestState createState() {
    return FlagTestState();
  }

  @override
  Null createSystem(FlagTestState state) {
    return null;
  }

  @override
  List<Command<FlagTestState, Null>> generateCommands(FlagTestState state) {
    return [
      Action0('no op', (s, system) {}),
      Action0('set a', (s, system) {
        s.a = true;
      }, postcondition: (s, system) => !s.allSet),
      Action0('set b', (s, system) {
        s.b = true;
      }, postcondition: (s, system) => !s.allSet),
      Action0('set c', (s, system) {
        s.c = true;
      }, postcondition: (s, system) => !s.allSet),
      Action0('clear a', (s, system) {
        s.a = false;
      }),
      Action0('clear b', (s, system) {
        s.b = false;
      }),
      Action0('clear c', (s, system) {
        s.c = false;
      }),
    ];
  }
}

final class FlagTestState {
  bool a = false;
  bool b = false;
  bool c = false;

  bool get allSet => a && b && c;
}

final class ShrinkingValueTestBehavior
    extends Behavior<ShrinkingValueTestState, Null> {
  @override
  ShrinkingValueTestState createState() {
    return ShrinkingValueTestState();
  }

  @override
  Null createSystem(ShrinkingValueTestState state) {
    return null;
  }

  @override
  List<Command<ShrinkingValueTestState, Null>> generateCommands(
      ShrinkingValueTestState state) {
    return [
      Action('increment', integer(min: 1000, max: 7000), (s, system, value) {
        print('increment $value');
        s.value += value;
      }, postcondition: (s, system) => s.value < 10000),
    ];
  }
}

final class ShrinkingValueTestState {
  int value = 0;
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  /*
  property('extract subsequence', () {
    runBehavior(
      SubsequenceTestBehavior(),
      onFalsify: (example) {
        expect(example.steps.length, lessThanOrEqualTo(5));
      },
      ignoreFalsify: true,
    );
  });

  property('cherrypick operations', () {
    runBehavior(
      FlagTestBehavior(),
      onFalsify: (example) {
        expect(example.steps.length, 3);
      },
      ignoreFalsify: true,
    );
  });
   */

  property('shrink values', () {
    runBehavior(
      ShrinkingValueTestBehavior(),
      onFalsify: (example) {
        final sum = example.falsifyingSteps
            .map((e) => e.value as int)
            .fold<int>(0, (a, b) => a + b);
        print('sum: $sum');
        expect(
          sum,
          allOf(
            lessThanOrEqualTo(example.originalState.value),
            greaterThanOrEqualTo(10000),
            lessThanOrEqualTo(15000),
          ),
        );
      },
      ignoreFalsify: true,
    );
  });
}
