import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class CircularDependencyTestState extends State {}

final class CircularDependencyTest extends Behavior<State> {
  @override
  State createState() => CircularDependencyTestState();

  @override
  List<Command<State>> generateCommands(State s) {
    final a = Action<State>(
      'a',
      (_) {},
    );
    final b = Action<State>(
      'b',
      (_) {},
      dependencies: [a],
    );
    a.addDependency(b);
    return [a, b];
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  property('circular dependency', () {
    forAllStates(
      CircularDependencyTest(),
      (_) {},
      onCheck: (f) {
        expect(f, throwsA(isA<CircularDependencyException>()));
      },
    );
  });
}
