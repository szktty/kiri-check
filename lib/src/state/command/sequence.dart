import 'package:kiri_check/src/state/command/command.dart';
import 'package:kiri_check/src/state/command/context.dart';

/// A command that runs other commands in sequence.
final class Sequence<State, System> extends Command<State, System> {
  /// Creates a new sequence command.
  ///
  /// Parameters:
  /// - `description`: The description of the command.
  /// - `commands`: The commands to run in sequence.
  Sequence(super.description, this.commands);

  /// @nodoc
  final List<Command<State, System>> commands;

  @override
  Future<dynamic> run(CommandContext<State, System> context, System system) {
    throw UnsupportedError('Sequence does not support run');
  }

  @override
  Future<void> nextState(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Sequence does not support update');
  }

  @override
  Future<bool> postcondition(
    CommandContext<State, System> context,
    State state,
    dynamic result,
  ) {
    throw UnsupportedError('Sequence does not support postcondition');
  }

  @override
  Future<bool> precondition(
    CommandContext<State, System> context,
    State state,
  ) {
    throw UnsupportedError('Sequence does not support precondition');
  }
}
