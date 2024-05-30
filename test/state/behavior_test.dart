import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum CounterEvent {
  increment,
  decrement,
  set,
}

final class CounterBehavior extends Behavior<CounterState, Null> {
  @override
  CounterState createState() {
    return CounterState();
  }

  @override
  Null createSystem(CounterState s) {
    return null;
  }

  @override
  List<Command<CounterState, Null>> generateCommands(CounterState s) {
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
      PreconditionCountState state) {
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
      )
    ];
  }

  @override
  void dispose(PreconditionCountState s, Null system) {
    print(
        'preconditionsOnSelect: ${preconditionsOnSelect}, preconditionsOnRun: ${preconditionsOnRun}');
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
      PreconditionCountState state) {
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
      )
    ];
  }

  @override
  void dispose(PreconditionCountState s, Null system) {
    print('preconditions: ${tryPreconditions}');
  }
}

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
        maxCommandTries: 100,
        tearDown: () {
          expect(behavior.preconditionsOnSelect, 1000);
          expect(behavior.preconditionsOnRun, 1000);
        },
      );
    });

    property('run commands which satisfies precondition', () {
      final behavior = PreconditionConditionalBehavior();
      runBehavior(
        behavior,
        maxCycles: 10,
        maxSteps: 10,
        maxCommandTries: 100,
        tearDown: () {
          expect(behavior.tryPreconditions, 2500);
        },
      );
    });
  });
}
