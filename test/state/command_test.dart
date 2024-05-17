import 'package:kiri_check/kiri_check.dart';
import 'package:test/test.dart';

final class NextStateTestState extends State {
  int count1 = 0;
  int count2 = 0;

  void increment() {
    count1++;
  }

  NextStateTestState nextState() {
    return NextStateTestState()..count2 = count2 + 1;
  }
}

final class NextStateTestBehavior extends Behavior<NextStateTestState> {
  @override
  NextStateTestState createState() => NextStateTestState();

  @override
  List<Command<NextStateTestState>> generateCommands(NextStateTestState s) {
    return [
      Action<NextStateTestState>(
        'update',
        (s) {
          s.increment();
        },
        nextState: (s) => s.nextState(),
      ),
    ];
  }
}

void main() {
  property('next state', () {
    forAllStates(NextStateTestBehavior(), (s) {
      expect(s.count1, 0);
      expect(s.count2, greaterThan(1));
    });
  });
}
