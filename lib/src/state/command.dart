import 'dart:math';

import 'package:kiri_check/src/state/command/action.dart';
import 'package:meta/meta.dart';

/// A operation that can be performed on a state and system.
abstract class Command<State, System, R> {
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

  R run(System system);

  void update(State state);

  bool requires(State state);

  bool ensures(State state, R result);

  /// @nodoc
  @internal
  CommandContext<State, System, R> createContext();
}

/// A command that encapsulates and controls another command.
abstract class Container<State, System, R> extends Command<State, System, R> {
  @protected
  Container(super.description, this.command);

  final Command<State, System, R> command;

  @override
  void update(State state) {
    command.update(state);
  }

  @override
  R run(System system) {
    return command.run(system);
  }

  @override
  bool requires(State state) {
    return command.requires(state);
  }

  @override
  bool ensures(State state, R result) {
    return command.ensures(state, result);
  }

  @override
  CommandContext<State, System, R> createContext() {
    return command.createContext();
  }
}

/// A command that initializes the state and system with another command.
final class Initialize<State, System, R> extends Container<State, System, R> {
  /// Creates a new initialize command.
  Initialize(super.description, super.command);
}

/// A command that finalizes the state and system with another command.
final class Finalize<State, System, R> extends Container<State, System, R> {
  /// Creates a new finalize command.
  Finalize(super.description, super.command);
}

abstract class CommandContext<State, System, R> {
  CommandContext(this.command);

  final Command<State, System, R> command;

  Random? random;

  bool get useCache;

  set useCache(bool value);

  // ignore: use_setters_to_change_properties
  void initialize(Random random) {
    this.random = random;
  }

  R run(System system);

  void update(State state);

  bool nextShrink();

  void failShrunk();

  dynamic get minValue;
}
