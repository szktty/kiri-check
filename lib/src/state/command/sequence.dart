import 'package:kiri_check/src/state/command.dart';

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

  /// @nodoc
  @override
  bool requires(State state) {
    // do nothing
    return true;
  }

  /// @nodoc
  @override
  bool ensures(State state, System system) {
    // do nothing
    return true;
  }
}
