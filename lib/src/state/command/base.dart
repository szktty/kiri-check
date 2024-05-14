import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

abstract class Command<T extends State> {
  Command(
    this.description, {
    List<Command<T>>? dependencies,
    this.isExecutable,
    this.precondition,
    this.postcondition,
    this.nextState,
  }) {
    this.dependencies = dependencies ?? [];
  }

  final String description;

  late final List<Command<T>> dependencies;

  final bool Function(T)? isExecutable;
  final bool Function(T)? precondition;
  final bool Function(T)? postcondition;
  final T Function(T)? nextState;

  void addDependency(Command<T> command) {
    dependencies.add(command);
  }

  void removeDependency(Command<T> command) {
    dependencies.remove(command);
  }

  void execute(T state);
}

final class Generate<T extends State, U> extends Command<T> {
  Generate(
    super.description,
    this.arbitrary,
    this.action, {
    super.dependencies,
    super.isExecutable,
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final Arbitrary<U> arbitrary;
  final void Function(T, U) action;

  @override
  void execute(T state) {
    final base = arbitrary as ArbitraryBase<U>;
    final value = base.generate(state.random);
    action(state, value);
  }
}

final class Action<T extends State> extends Command<T> {
  Action(
    super.description,
    this.action, {
    super.dependencies,
    super.isExecutable,
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final void Function(T) action;

  @override
  void execute(T state) {
    action(state);
  }
}
