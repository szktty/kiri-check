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

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('StatefulProperty', () {
    property('basic', () {
      forAllStates(CounterBehavior());
    });
  });
}
