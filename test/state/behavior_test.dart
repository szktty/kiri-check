import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

final class CounterBehavior extends Behavior<CounterState, CounterSystem> {
  @override
  CounterState createState() {
    return CounterState();
  }

  @override
  CounterSystem createSystem(CounterState s) {
    return CounterSystem(s.count);
  }

  @override
  List<Command<CounterState, CounterSystem>> generateCommands(CounterState s) {
    return [
      Action(
        'set',
        integer(),
        nextState: (s, value) => s.count = value,
        run: (system, value) => system.count = value,
        postcondition: (s, value, result) => (s.count = value) == result,
      ),
      Action0(
        'increment',
        nextState: (s) => s.count++,
        run: (system) => ++system.count,
        postcondition: (s, count) => s.count + 1 == count,
      ),
      Action0(
        'decrement',
        nextState: (s) => s.count--,
        run: (system) => --system.count,
        postcondition: (s, count) => s.count - 1 == count,
      ),
    ];
  }
}

final class CounterState {
  int count = 0;
}

final class CounterSystem {
  CounterSystem(this.count);

  int count;
}

final class PreconditionCountBehavior extends Behavior<Null, Null> {
  @override
  Null createState() => null;

  @override
  Null createSystem(Null s) => null;

  int preconditionsOnGenerate = 0;
  int preconditionsOnExecute = 0;

  bool _onGenerate = true;

  @override
  void onGenerate(Null s) {
    _onGenerate = true;
  }

  @override
  void onExecute(Null s, Null sys) {
    _onGenerate = false;
  }

  @override
  List<Command<Null, Null>> generateCommands(
    Null state,
  ) {
    return [
      Action0(
        'count',
        nextState: (s) {},
        run: (system) {},
        precondition: (s) {
          if (_onGenerate) {
            preconditionsOnGenerate++;
          } else {
            preconditionsOnExecute++;
          }
          return true;
        },
      ),
    ];
  }
}

final class PreconditionConditionalBehavior extends Behavior<Null, Null> {
  @override
  Null createState() => null;

  @override
  Null createSystem(Null s) => null;

  int preconditionsOnGenerate = 0;
  int preconditionsOnExecute = 0;

  bool _onGenerate = true;

  @override
  void onGenerate(Null s) {
    _onGenerate = true;
  }

  @override
  void onExecute(Null s, Null sys) {
    _onGenerate = false;
  }

  @override
  List<Command<Null, Null>> generateCommands(
    Null state,
  ) {
    var i = 0;
    return [
      Action0(
        'count',
        nextState: (s) {},
        run: (system) {},
        precondition: (s) {
          if (_onGenerate) {
            preconditionsOnGenerate++;
          } else {
            preconditionsOnExecute++;
          }

          if (_onGenerate) {
            i++;
            return i.isEven;
          } else {
            return true;
          }
        },
      ),
    ];
  }
}

final class PostconditionCountBehavior extends Behavior<Null, Null> {
  @override
  Null createState() => null;

  @override
  Null createSystem(Null s) => null;

  int postconditions = 0;

  @override
  List<Command<Null, Null>> generateCommands(
    Null state,
  ) {
    return [
      Action0(
        'count',
        nextState: (s) {
          print('run action');
        },
        run: (system) {},
        postcondition: (s, _) {
          postconditions++;
          return true;
        },
      ),
    ];
  }

  @override
  void dispose(Null s, Null system) {
    print('postconditions: $postconditions');
  }
}

final class TestCallbacksBehavior extends Behavior<TestCallbacksState, Null> {
  int setUpCount = 0;
  int setUpAllCount = 0;
  int tearDownCount = 0;
  int tearDownAllCount = 0;
  int disposeCount = 0;

  @override
  TestCallbacksState createState() => TestCallbacksState();

  @override
  Null createSystem(TestCallbacksState s) => null;

  @override
  List<Command<TestCallbacksState, Null>> generateCommands(
    TestCallbacksState state,
  ) {
    return [
      Action0('no op', nextState: (s) {}, run: (system) {}),
    ];
  }

  @override
  void dispose(TestCallbacksState s, Null system) {
    disposeCount++;
  }

  @override
  void setUp() {
    setUpCount++;
  }

  @override
  void setUpAll() {
    setUpAllCount++;
  }

  @override
  void tearDown() {
    tearDownCount++;
  }

  @override
  void tearDownAll() {
    tearDownAllCount++;
  }
}

final class TestCallbacksState {}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('StatefulProperty', () {
    property('basic', () {
      runBehavior(
        CounterBehavior(),
        maxCycles: 10,
        maxSteps: 10,
      );
    });

    property('precondition calls on selecting and running commands', () {
      final behavior = PreconditionCountBehavior();
      runBehavior(
        behavior,
        maxCycles: 10,
        maxSteps: 10,
        tearDown: () {
          expect(behavior.preconditionsOnGenerate, 100);
          expect(behavior.preconditionsOnExecute, 100);
        },
      );
    });

    property('run commands which satisfies precondition', () {
      final behavior = PreconditionConditionalBehavior();
      runBehavior(
        behavior,
        maxCycles: 10,
        maxSteps: 10,
        tearDown: () {
          expect(behavior.preconditionsOnGenerate, 200);
          expect(behavior.preconditionsOnExecute, 100);
        },
      );
    });

    property('postcondition calls', () {
      final behavior = PostconditionCountBehavior();
      runBehavior(
        behavior,
        maxCycles: 10,
        maxSteps: 10,
        tearDown: () {
          expect(behavior.postconditions, 100);
        },
      );
    });

    property('test callbacks', () {
      final behavior = TestCallbacksBehavior();
      runBehavior(
        behavior,
        maxCycles: 10,
        maxSteps: 10,
        tearDown: () {
          expect(behavior.setUpCount, 10);
          expect(behavior.setUpAllCount, 1);
          expect(behavior.disposeCount, 10);
          expect(behavior.tearDownCount, 10);
          expect(behavior.tearDownAllCount, 1);
        },
      );
    });
  });
}
