import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

final class SubsequenceTestBehavior
    extends Behavior<SubsequenceTestState, Null> {
  @override
  SubsequenceTestState initialState() {
    return SubsequenceTestState();
  }

  @override
  Null createSystem(SubsequenceTestState state) {
    return null;
  }

  @override
  List<Command<SubsequenceTestState, Null>> generateCommands(
    SubsequenceTestState state,
  ) {
    var n = 0;
    Command<SubsequenceTestState, Null> increment([int value = 1]) {
      n++;
      return Action0(
        'increment $value ($n)',
        nextState: (s) {
          s.increment(value);
        },
        run: (system) {},
        postcondition: (s, _) => s.value < 100,
      );
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

  @override
  void destroy(Null system) {}
}

final class SubsequenceTestState {
  int value = 0;

  void increment(int value) {
    this.value += value;
  }
}

final class FlagTestBehavior extends Behavior<FlagTestState, Null> {
  @override
  FlagTestState initialState() {
    return FlagTestState();
  }

  @override
  Null createSystem(FlagTestState state) {
    return null;
  }

  @override
  List<Command<FlagTestState, Null>> generateCommands(FlagTestState state) {
    return [
      Action0('no op', nextState: (s) {}, run: (system) {}),
      Action0(
        'set a',
        nextState: (s) {
          s.a = true;
        },
        run: (system) {},
        postcondition: (s, _) => !s.allSet,
      ),
      Action0(
        'set b',
        nextState: (s) {
          s.b = true;
        },
        run: (system) {},
        postcondition: (s, _) => !s.allSet,
      ),
      Action0(
        'set c',
        nextState: (s) {
          s.c = true;
        },
        run: (system) {},
        postcondition: (s, _) => !s.allSet,
      ),
      Action0('clear a', nextState: (s) {
        s.a = false;
      }, run: (system) {}),
      Action0('clear b', nextState: (s) {
        s.b = false;
      }, run: (system) {}),
      Action0('clear c', nextState: (s) {
        s.c = false;
      }, run: (system) {}),
    ];
  }

  @override
  void destroy(Null system) {}
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
  ShrinkingValueTestState initialState() {
    return ShrinkingValueTestState();
  }

  @override
  Null createSystem(ShrinkingValueTestState state) {
    return null;
  }

  @override
  List<Command<ShrinkingValueTestState, Null>> generateCommands(
    ShrinkingValueTestState state,
  ) {
    return [
      Action(
        'increment',
        integer(min: 1000, max: 7000),
        nextState: (s, value) {
          print('increment $value');
          s.value += value;
        },
        run: (system, value) {},
        postcondition: (s, value, _) => (s.value + value) < 10000,
      ),
    ];
  }

  @override
  void destroy(Null system) {}
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
        expect(example.falsifyingSteps.length,
            lessThan(example.originalSteps.length));
      },
      ignoreFalsify: true,
    );
  });

  property('cherrypick operations', () {
    runBehavior(
      FlagTestBehavior(),
      onFalsify: (example) {
        expect(example.falsifyingSteps.length,
            lessThan(example.originalSteps.length));
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
        expect(example.falsifyingState.value,
            lessThan(example.originalState.value));
        expect(
          sum,
          allOf(greaterThanOrEqualTo(10000), lessThanOrEqualTo(15000)),
        );
      },
      ignoreFalsify: true,
    );
  });
}
