import 'dart:math';

import 'package:kiri_check/src/state/command/action.dart';
import 'package:meta/meta.dart';

/// A operation that can be performed on a state and system.
abstract class Command<State, System> {
  /// @nodoc
  @protected
  Command(this.description) {
    _random = null;
  }

  /// @nodoc
  final String description;

  Random? _random;

  Random get random => _random!;

  // ignore: use_setters_to_change_properties
  void initialize(Random random) {
    _random = random;
  }

  dynamic run(System system);

  void nextState(State state);

  bool requires(State state);

  bool ensures(State state, dynamic result);

  /// @nodoc
  @internal
  CommandContext<State, System> createContext(Random random);
}

/// A command that encapsulates and controls another command.
abstract class Container<State, System> extends Command<State, System> {
  @protected
  Container(super.description, this.command);

  final Command<State, System> command;

  @override
  void nextState(State state) {
    command.nextState(state);
  }

  @override
  dynamic run(System system) {
    return command.run(system);
  }

  @override
  bool requires(State state) {
    return command.requires(state);
  }

  @override
  bool ensures(State state, dynamic result) {
    return command.ensures(state, result);
  }

  @override
  CommandContext<State, System> createContext(Random random) {
    return command.createContext(random);
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
  CommandContext(this.command, this.random) {
    command.initialize(random);
  }

  final Command<State, System> command;
  final Random random;

  bool get useCache;

  set useCache(bool value);

  void setUp();

  dynamic run(System system);

  void nextState(State state);

  bool requires(State state);

  bool ensures(State state, dynamic result);

  bool nextShrink();

  void failShrunk();

  dynamic get minValue;
}
