import 'package:kiri_check/src/state/command/context.dart';
import 'package:meta/meta.dart';

/// A operation that can be performed on a state and system.
abstract class Command<State, System> {
  @protected
  Command(this.description);

  final String description;

  dynamic run(CommandContext<State, System> context, System system);

  void nextState(CommandContext<State, System> context, State state);

  bool precondition(CommandContext<State, System> context, State state);

  bool postcondition(
    CommandContext<State, System> context,
    State state,
    dynamic result,
  );
}

/// A command that encapsulates and controls another command.
abstract class Container<State, System> extends Command<State, System> {
  @protected
  Container(super.description, this.command);

  final Command<State, System> command;

  @override
  void nextState(CommandContext<State, System> context, State state) {
    command.nextState(context, state);
  }

  @override
  dynamic run(CommandContext<State, System> context, System system) {
    return command.run(context, system);
  }

  @override
  bool precondition(CommandContext<State, System> context, State state) {
    return command.precondition(context, state);
  }

  @override
  bool postcondition(
      CommandContext<State, System> context, State state, dynamic result) {
    return command.postcondition(context, state, result);
  }
}

/// A command that initializes the state and system with another command.
final class Initialize<State, System> extends Command<State, System> {
  /// Creates a new initialize command.
  Initialize(this.command) : super(command.description);

  final Command<State, System> command;

  @override
  dynamic run(CommandContext<State, System> context, System system) {
    throw UnsupportedError('Initialize does not support run');
  }

  @override
  void nextState(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Initialize does not support update');
  }

  @override
  bool postcondition(
      CommandContext<State, System> context, State state, dynamic result) {
    throw UnsupportedError('Initialize does not support postcondition');
  }

  @override
  bool precondition(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Initialize does not support precondition');
  }
}

/// A command that finalizes the state and system with another command.
final class Finalize<State, System> extends Command<State, System> {
  /// Creates a new finalize command.
  Finalize(this.command) : super(command.description);

  final Command<State, System> command;

  @override
  dynamic run(CommandContext<State, System> context, System system) {
    throw UnsupportedError('Finalize does not support run');
  }

  @override
  void nextState(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Finalize does not support update');
  }

  @override
  bool postcondition(
      CommandContext<State, System> context, State state, dynamic result) {
    throw UnsupportedError('Finalize does not support postcondition');
  }

  @override
  bool precondition(CommandContext<State, System> context, State state) {
    throw UnsupportedError('Finalize does not support precondition');
  }
}
