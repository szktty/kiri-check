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

final class NonExecutableCommand<T extends State> extends Command<T> {
  NonExecutableCommand(super.description);

  @override
  bool canExecute(T state) => false;

  @override
  void execute(T state) {
    throw StateError('This command should not be executed');
  }
}

final class NonExecutableBehavior extends Behavior<NonExecutableState> {
  @override
  NonExecutableState createState() => NonExecutableState();

  @override
  List<Command<NonExecutableState>> generateCommands(NonExecutableState s) {
    return [
      NonExecutableCommand('non executable'),
      Action('executable', (s) {
        s.b++;
      }),
    ];
  }
}

final class NonExecutableState extends NextStateTestState {
  int a = 0;
  int b = 0;
}

void main() {
  property('next state', () {
    forAllStates(NextStateTestBehavior(), (s) {
      expect(s.count1, 0);
      expect(s.count2, greaterThan(1));
    });
  });

  property('non executable', () {
    forAllStates(NonExecutableBehavior(), (s) {
      expect(s.a, 0);
      expect(s.b, greaterThan(0));
    });
  });
}
