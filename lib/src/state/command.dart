import 'dart:math';

import 'package:kiri_check/src/state/command/action.dart';
import 'package:meta/meta.dart';

/// A operation that can be performed on a state and system.
abstract class Command<State, System> {
  /// @nodoc
  @protected
  Command(this.description);

  /// @nodoc
  final String description;

  /// @nodoc
  bool requires(State state);

  /// @nodoc
  bool ensures(State state, System system);
}

/// A command that encapsulates and controls another command.
abstract class Container<State, System> extends Command<State, System> {
  /// @nodoc
  @protected
  Container(super.description, this.command);

  /// @nodoc
  final Command<State, System> command;

  /// @nodoc
  @override
  bool requires(State state) {
    return command.requires(state);
  }

  /// @nodoc
  @override
  bool ensures(State state, System system) {
    return command.ensures(state, system);
  }
}

/// A command that initializes the state and system with another command.
final class Initialize<State, System> extends Container<State, System> {
  /// Creates a new initialize command.
  Initialize(super.description, super.command);
}

/// A command that finalizes the state and system with another command.
final class Finalize<State, System> extends Container<State, System> {
  /// Creates a new finalize command.
  Finalize(super.description, super.command);
}

abstract class CommandContext<State, System> {
  CommandContext(this.command);

  static CommandContext<State, System> fromCommand<State, System>(
    Command<State, System> command,
  ) {
    if (command is Action<State, System, dynamic>) {
      return ActionContext<State, System, dynamic>(command);
    } else {
      throw Exception('Unknown command type: $command');
    }
  }

  final Command<State, System> command;

  bool get useCache;

  set useCache(bool value);

  void execute(State state, System system, Random random);

  bool nextShrink();

  void failShrunk();

  dynamic get minValue;
}
