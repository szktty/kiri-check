import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/state.dart';

final class Initialize<T extends State> extends Command<T> {
  Initialize(
    super.description,
    this.command, {
    super.dependencies,
    super.canExecute,
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final Command<T> command;

  @override
  List<Command<T>> get subcommands => [command];

  @override
  void execute(T state) {
    command.execute(state);
  }
}
