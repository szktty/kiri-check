import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum CounterEvent {
  increment,
  decrement,
  set,
}

final class CounterBehavior extends Behavior<CounterState, Null, dynamic> {
  @override
  CounterState createState() {
    return CounterState();
  }

  @override
  Null createSystem(CounterState s) {
    return null;
  }

  @override
  List<Command<CounterState, Null, R>> generateCommands(CounterState s) {
    return [
      Action(
        'set',
        integer(),
        (s, system, value) {
          s
            ..previous = s.count
            ..count = value
            ..addEvent(CounterEvent.set);
        },
      ),
      Action0(
        'increment',
        (s, system) {
          s.previous = s.count;
          s.count++;
          s.addEvent(CounterEvent.increment);
        },
        postcondition: (s, system) {
          return s.count == s.previous + 1;
        },
      ),
      Action0(
        'decrement',
        (s, system) {
          s.previous = s.count;
          s.count--;
          s.addEvent(CounterEvent.decrement);
        },
        postcondition: (s, system) {
          return s.count == s.previous - 1;
        },
      ),
    ];
  }
}

final class CounterState {
  int count = 0;
  int previous = 0;

  final events = <CounterEvent>[];

  void addEvent(CounterEvent event) {
    events.add(event);
  }
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
        (s, system) {
          print('run action');
          if (onSelect) {
            preconditionsOnSelect--;
            preconditionsOnRun++;
            onSelect = false;
          }
        },
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
        (s, system) {
          print('run action');
          onSelect = false;
        },
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
        (s, system) {
          print('run action');
        },
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
      Action0('no op', (s, system) {}),
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
