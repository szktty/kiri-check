import 'dart:math';

import 'package:kiri_check/src/state/command/action.dart';
import 'package:meta/meta.dart';

abstract class Command<State, System> {
  Command(this.description);

  final String description;

  bool requires(State state);

  bool ensures(State state, System system);
}

abstract class Container<State, System> extends Command<State, System> {
  @protected
  Container(super.description, this.command);

  final Command<State, System> command;

  @override
  bool requires(State state) {
    return command.requires(state);
  }

  @override
  bool ensures(State state, System system) {
    return command.ensures(state, system);
  }
}

final class Initialize<State, System> extends Container<State, System> {
  Initialize(super.description, super.command);
}

final class Finalize<State, System> extends Container<State, System> {
  Finalize(super.description, super.command);
}

abstract class CommandContext<State, System> {
  CommandContext(this.command);

  static CommandContext<State, System> fromCommand<State, System, T>(
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
