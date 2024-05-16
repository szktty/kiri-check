import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/state.dart';

final class Finalize<T extends State> extends Command<T> {
  Finalize(
    String description,
    this.command, {
    List<Command<T>> dependencies = const [],
    bool Function(T)? canExecute,
    bool Function(T)? precondition,
    bool Function(T)? postcondition,
    T Function(T)? nextState,
  }) : super(
          description,
          dependencies: dependencies,
          canExecute: canExecute,
          precondition: precondition,
          postcondition: postcondition,
          nextState: nextState,
        );

  final Command<T> command;

  @override
  List<Command<T>> get subcommands => [command];

  @override
  void execute(T state) {
    command.execute(state);
  }
}
