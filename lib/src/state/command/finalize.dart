import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';

final class Finalize<T extends State> extends Command<T> {
  Finalize(
    super.description,
    this.command, {
    List<Command<T>> super.dependencies = const [],
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
