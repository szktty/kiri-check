import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

abstract class Command<T extends State> {
  Command(
    this.description, {
    this.precondition,
    this.postcondition,
    this.nextState,
  });

  final String description;
  final bool Function(T)? precondition;
  final bool Function(T)? postcondition;
  final T Function(T)? nextState;

  void run(T state);
}

final class Generate<T extends State, U> extends Command<T> {
  Generate(
    super.description,
    this.arbitrary,
    this.action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final Arbitrary<U> arbitrary;
  final void Function(T, U) action;

  @override
  void run(T state) {
    final base = arbitrary as ArbitraryBase<U>;
    final value = base.generate(state.random);
    action(state, value);
  }
}

final class Action<T extends State> extends Command<T> {
  Action(
    super.description,
    this.action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final void Function(T) action;

  @override
  void run(T state) {
    action(state);
  }
}
