import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';

final class Action<T extends State> extends Command<T> {
  Action(
    super.description,
    this.action, {
    super.dependencies,
    super.canExecute,
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
