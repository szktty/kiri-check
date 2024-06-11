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
        postcondition: (s, result) => s.count == result,
      ),
      Action0(
        'increment',
        nextState: (s) => s.count++,
        run: (system) => --system.count,
        postcondition: (s, result) => s.count == result,
      ),
      Action0(
        'decrement',
        nextState: (s) => s.count--,
        run: (system) {
          system.count--;
          return system.count;
        },
        postcondition: (s, result) {
          print('postcondition: ${s.count} $result');
          return s.count == result;
        },
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

final class PreconditionCountBehavior
    extends Behavior<PreconditionCountState, Null> {
  @override
  PreconditionCountState createState() => PreconditionCountState();

  @override
  Null createSystem(PreconditionCountState s) => null;

  int preconditionsOnSelect = 0;
  int preconditionsOnRun = 0;

  @override
  List<Command<PreconditionCountState, Null>> generateCommands(
    PreconditionCountState state,
  ) {
    var onSelect = true;
    return [
      Action0(
        'count',
        nextState: (s) {
          print('nextState');
          if (onSelect) {
            preconditionsOnSelect--;
            preconditionsOnRun++;
            onSelect = false;
          }
        },
        run: (system) {},
        precondition: (s) {
          if (onSelect) {
            preconditionsOnSelect++;
          } else {
            preconditionsOnRun++;
          }
          return true;
        },
      ),
    ];
  }

  @override
  void dispose(PreconditionCountState s, Null system) {
    print(
      'preconditionsOnSelect: $preconditionsOnSelect, preconditionsOnRun: $preconditionsOnRun',
    );
  }
}

final class PreconditionCountState {}

final class PreconditionConditionalBehavior
    extends Behavior<PreconditionCountState, Null> {
  @override
  PreconditionCountState createState() => PreconditionCountState();

  @override
  Null createSystem(PreconditionCountState s) => null;

  int tryPreconditions = 0;

  @override
  List<Command<PreconditionCountState, Null>> generateCommands(
    PreconditionCountState state,
  ) {
    var onSelect = true;
    var i = -1;
    return [
      Action0(
        'count',
        nextState: (s) {
          print('run action');
          onSelect = false;
        },
        run: (system) {},
        precondition: (s) {
          tryPreconditions++;
          if (onSelect && i < 10) {
            i++;
            return i.isEven;
          } else {
            return true;
          }
        },
      ),
    ];
  }

  @override
  void dispose(PreconditionCountState s, Null system) {
    print('preconditions: $tryPreconditions');
  }
}

final class PostconditionCountBehavior
    extends Behavior<PostconditionCountState, Null> {
  @override
  PostconditionCountState createState() => PostconditionCountState();

  @override
  Null createSystem(PostconditionCountState s) => null;

  int postconditions = 0;

  @override
  List<Command<PostconditionCountState, Null>> generateCommands(
    PostconditionCountState state,
  ) {
    return [
      Action0(
        'count',
        nextState: (s) {
          print('run action');
        },
        run: (system) {},
        postcondition: (s, system) {
          postconditions++;
          return true;
        },
      ),
    ];
  }

  @override
  void dispose(PostconditionCountState s, Null system) {
    print('postconditions: $postconditions');
  }
}

final class PostconditionCountState {}

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
          expect(behavior.preconditionsOnSelect, 100);
          expect(behavior.preconditionsOnRun, 100);
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
          expect(behavior.tryPreconditions, 250);
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
