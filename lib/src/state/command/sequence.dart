import 'package:kiri_check/src/state/command.dart';

/// A command that runs other commands in sequence.
final class Sequence<State, System, R> extends Command<State, System, R> {
  /// Creates a new sequence command.
  ///
  /// Parameters:
  /// - `description`: The description of the command.
  /// - `commands`: The commands to run in sequence.
  Sequence(super.description, this.commands);

  /// @nodoc
  final List<Command<State, System, R>> commands;

  @override
  CommandContext<State, System, R> createContext() {
    throw UnsupportedError('Sequence does not support createContext');
  }

  @override
  R run(System system) {
    throw UnsupportedError('Sequence does not support run');
  }

  @override
  void update(State state) {
    throw UnsupportedError('Sequence does not support update');
  }

  @override
  bool ensures(State state, R result) {
    throw UnsupportedError('Sequence does not support ensures');
  }

  @override
  bool requires(State state) {
    throw UnsupportedError('Sequence does not support requires');
  }
}
