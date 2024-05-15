import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class DependencyTestState extends State {
  int a = 0;
  int b = 0;
  int c = 0;
}

final class DependencyTest extends Behavior<DependencyTestState> {
  @override
  DependencyTestState createState() => DependencyTestState();

  @override
  List<Command<DependencyTestState>> generateCommands(DependencyTestState s) {
    final a = Action<DependencyTestState>('a', (s) {
      s.a++;
    });
    final b = Action<DependencyTestState>('b', (s) {
      s.b++;
    }, dependencies: [a]);
    final c = Action<DependencyTestState>('c', (s) {
      s.c++;
    }, dependencies: [b]);
    return [a, b, c];
  }
}

final class UnknownDependencyTest extends Behavior<State> {
  @override
  State createState() => DependencyTestState();

  @override
  List<Command<State>> generateCommands(State s) {
    final a = Action<State>('a', (_) {});
    final b = Action<State>('b', (_) {}, dependencies: [a]);
    final c = Action<State>('c', (_) {}, dependencies: [b]);
    return [b, c];
  }
}

final class CircularDependencyTestState extends State {}

final class CircularDependencyTest extends Behavior<State> {
  @override
  State createState() => CircularDependencyTestState();

  @override
  List<Command<State>> generateCommands(State s) {
    final a = Action<State>('a', (_) {});
    final b = Action<State>('b', (_) {}, dependencies: [a]);
    a.addDependency(b);
    return [a, b];
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('dependency', () {
    property('basic', () {
      var aZero = false;
      var bZero = false;
      forAllStates(
        DependencyTest(),
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
        UnknownDependencyTest(),
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
