import 'dart:async';

import 'package:kiri_check/src/state/command/context.dart';
import 'package:meta/meta.dart';

/// A operation that can be performed on a state and system.
abstract class Command<State, System> {
  /// Creates a new command.
  @protected
  Command(this.description);

  /// A description of the command.
  final String description;

  /// Performs the command on the given system.
  Future<dynamic> run(CommandContext<State, System> context, System system);

  /// Updates the state to the next state.
  Future<void> nextState(CommandContext<State, System> context, State state);

  /// Returns true if the command can be run on the given state.
  Future<bool> precondition(CommandContext<State, System> context, State state);

  /// Returns true if postcondition of the command is satisfied.
  Future<bool> postcondition(
    CommandContext<State, System> context,
    State state,
    dynamic result,
  );
}

/// A command that initializes the state and system with another command.
final class Initialize<State, System> extends Command<State, System> {
  /// Creates a new initialize command.
  Initialize(this.command) : super(command.description);

  /// @nodoc
  final Command<State, System> command;

  @override
  Future<dynamic> run(CommandContext<State, System> context, System system) {
    throw UnsupportedError('Initialize does not support run');
  }

  @override
  Future<void> nextState(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Initialize does not support update');
  }

  @override
  Future<bool> postcondition(
    CommandContext<State, System> context,
    State state,
    dynamic result,
  ) async {
    throw UnsupportedError('Initialize does not support postcondition');
  }

  @override
  Future<bool> precondition(
    CommandContext<State, System> context,
    State state,
  ) async {
    throw UnsupportedError('Initialize does not support precondition');
  }
}

/// A command that finalizes the state and system with another command.
final class Finalize<State, System> extends Command<State, System> {
  /// Creates a new finalize command.
  Finalize(this.command) : super(command.description);

  /// @nodoc
  final Command<State, System> command;

  @override
  Future<dynamic> run(CommandContext<State, System> context, System system) {
    throw UnsupportedError('Finalize does not support run');
  }

  @override
  Future<void> nextState(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Finalize does not support update');
  }

  @override
  Future<bool> postcondition(
    CommandContext<State, System> context,
    State state,
    dynamic result,
  ) {
    throw UnsupportedError('Finalize does not support postcondition');
  }

  @override
  Future<bool> precondition(
    CommandContext<State, System> context,
    State state,
  ) {
    throw UnsupportedError('Finalize does not support precondition');
  }
}
