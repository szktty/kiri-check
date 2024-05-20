import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

final class ConditionalTestState extends State {
  bool precondition = false;
  bool postcondition = false;
}

final class ConditionalTestBehavior extends Behavior<ConditionalTestState> {
  @override
  ConditionalTestState createState() => ConditionalTestState();

  @override
  List<Command<ConditionalTestState>> generateCommands(ConditionalTestState s) {
    return [
      Action0<ConditionalTestState>(
        'no op',
        (s) {},
        precondition: (s) {
          s.precondition = true;
          return true;
        },
        postcondition: (s) {
          s.postcondition = true;
          return true;
        },
      ),
    ];
  }
}

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
      Action0<NextStateTestState>(
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
      Action0('executable', (s) {
        s.b++;
      }),
    ];
  }
}

final class NonExecutableState extends NextStateTestState {
  int a = 0;
  int b = 0;
}

final class DependencyTestState extends State {
  int a = 0;
  int b = 0;
  int c = 0;
}

final class DependencyTestBehavior extends Behavior<DependencyTestState> {
  @override
  DependencyTestState createState() => DependencyTestState();

  @override
  List<Command<DependencyTestState>> generateCommands(DependencyTestState s) {
    final a = Action0<DependencyTestState>('a', (s) {
      s.a++;
    });
    final b = Action0<DependencyTestState>('b', (s) {
      s.b++;
    }, dependencies: [a]);
    final c = Action0<DependencyTestState>('c', (s) {
      s.c++;
    }, dependencies: [b]);
    return [a, b, c];
  }
}

final class UnknownDependencyTestBehavior extends Behavior<State> {
  @override
  State createState() => DependencyTestState();

  @override
  List<Command<State>> generateCommands(State s) {
    final a = Action0<State>('a', (_) {});
    final b = Action0<State>('b', (_) {}, dependencies: [a]);
    final c = Action0<State>('c', (_) {}, dependencies: [b]);
    return [b, c];
  }
}

final class CircularDependencyTestState extends State {}

final class CircularDependencyTest extends Behavior<State> {
  @override
  State createState() => CircularDependencyTestState();

  @override
  List<Command<State>> generateCommands(State s) {
    final a = Action0<State>('a', (_) {});
    final b = Action0<State>('b', (_) {}, dependencies: [a]);
    a.addDependency(b);
    return [a, b];
  }
}

void main() {
  property('conditional', () {
    forAllStates(ConditionalTestBehavior(), (s) {
      expect(s.precondition, isTrue);
      expect(s.postcondition, isTrue);
    });
  });

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

  group('dependency', () {
    property('basic', () {
      var aZero = false;
      var bZero = false;
      forAllStates(
        DependencyTestBehavior(),
        (s) {
          if (s.a == 0) {
            aZero = true;
            expect(s.b, 0);
            expect(s.c, 0);
          } else if (s.b == 0) {
            bZero = true;
            expect(s.a, greaterThan(0));
            expect(s.c, 0);
          } else {
            expect(s.a, greaterThan(0));
            expect(s.b, greaterThan(0));
          }
        },
        tearDown: () {
          expect(aZero, isTrue, reason: 'case a == 0 is not found');
          expect(bZero, isTrue, reason: 'case b == 0 is not found');
        },
      );
    });

    property('unknown dependency', () {
      forAllStates(
        UnknownDependencyTestBehavior(),
        (_) {},
        onCheck: (f) {
          expect(f, throwsA(isA<CommandDependencyException>()));
        },
      );
    });

    property('detect circular dependency', () {
      forAllStates(
        CircularDependencyTest(),
        (_) {},
        onCheck: (f) {
          expect(f, throwsA(isA<CommandDependencyException>()));
        },
      );
    });
  });
}
