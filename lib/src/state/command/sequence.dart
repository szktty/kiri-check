import 'dart:math';

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

  @override
  CommandContext<State, System> createContext(Random random) {
    throw UnsupportedError('Sequence does not support createContext');
  }

  @override
  dynamic run(System system) {
    throw UnsupportedError('Sequence does not support run');
  }

  @override
  void nextState(State state) {
    throw UnsupportedError('Sequence does not support update');
  }

  @override
  bool ensures(State state, dynamic result) {
    throw UnsupportedError('Sequence does not support ensures');
  }

  @override
  bool requires(State state) {
    throw UnsupportedError('Sequence does not support requires');
  }
}
