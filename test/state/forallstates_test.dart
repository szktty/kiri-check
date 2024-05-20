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

final class CounterBehavior extends Behavior<CounterState> {
  @override
  CounterState createState() {
    return CounterState();
  }

  @override
  List<Command<CounterState>> generateCommands(CounterState s) {
    return [
      Action(
        'set',
        integer(),
        (s, value) {
          s
            ..previous = s.count
            ..count = value
            ..addEvent(CounterEvent.set);
        },
      ),
      Action0(
        'increment',
        (s) {
          s.previous = s.count;
          s.count++;
          s.addEvent(CounterEvent.increment);
        },
        postcondition: (s) {
          return s.count == s.previous + 1;
        },
      ),
      Action0(
        'decrement',
        (s) {
          s.previous = s.count;
          s.count--;
          s.addEvent(CounterEvent.decrement);
        },
        postcondition: (s) {
          return s.count == s.previous - 1;
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

  @override
  void tearDown() {
    print('events: $events');
    expect(events, isNotEmpty);
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('StatefulProperty', () {
    property('basic', () {
      forAllStates(CounterBehavior(), (_) {});
    });
  });
}
