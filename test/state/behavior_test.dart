import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class DependencyTestState extends State {}

final class DependencyTest extends Behavior<State> {
  @override
  State createState() => DependencyTestState();

  @override
  List<Command<State>> generateCommands(State s) {
    final a = Action<State>('a', (_) {});
    final b = Action<State>('b', (_) {}, dependencies: [a]);
    final c = Action<State>('c', (_) {}, dependencies: [b]);
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
