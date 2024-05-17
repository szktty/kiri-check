import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';

final class Generate<T extends State, U> extends Command<T> {
  Generate(
    super.description,
    this.arbitrary,
    this.action, {
    super.dependencies,
    super.canExecute,
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
