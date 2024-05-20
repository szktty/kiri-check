import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';

final class Action<T extends State, U> extends Command<T> {
  Action(
    super.description,
    this.arbitrary,
    this.action, {
    super.dependencies,
    super.canExecute,
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  // TODO: private
  final Arbitrary<U> arbitrary;
  final void Function(T, U) action;

  @override
  void execute(T state) {
    final base = arbitrary as ArbitraryBase<U>;
    final value = base.generate(state.random);
    action(state, value);
  }
}

final class Action0<T extends State> extends Action<T, void> {
  Action0(
    String description,
    void Function(T) action, {
    super.dependencies,
    super.canExecute,
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(description, null_(), (s, _) => action(s));
}

final class Action2<T extends State, E1, E2> extends Action<T, (E1, E2)> {
  Action2(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    void Function(T, E1, E2) action, {
    super.dependencies,
    super.canExecute,
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(
          description,
          combine2(arbitrary1, arbitrary2, (a, b) => (a, b)),
          (s, args) => action(s, args.$1, args.$2),
        );
}
