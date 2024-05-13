import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

enum CounterEvent {
  initialize,
  increment,
  decrement,
  reset,
}

final class CounterBehavior extends Behavior<CounterState> {
  @override
  CounterState createState() {
    final state = CounterState();
    state.count = 0;
    state.previous = 0;
    return state;
  }

  @override
  List<Command<CounterState>> generateCommands(CounterState s) {
    return [
      Action(
        'increment',
        (s) {
          s.previous = s.count;
          s.count++;
        },
        postcondition: (s) {
          return s.count == s.previous + 2;
        },
      ),
      Action(
        'decrement',
        (s) {
          s.previous = s.count;
          s.count--;
        },
        postcondition: (s) {
          return s.count == s.previous - 1;
        },
      ),
      Action(
        'reset',
        (s) {
          s.previous = s.count;
          s.count = 0;
        },
        postcondition: (s) {
          return s.count == 0;
        },
      ),
    ];
  }
}

final class CounterState extends State {
  int count = 0;
  int previous = 0;

  final events = <CounterEvent>[];

  void addEvent(CounterEvent event) {
    events.add(event);
  }

  @override
  void setUp() {
    events.clear();
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
