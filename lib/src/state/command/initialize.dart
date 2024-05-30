import 'dart:math';

import 'package:kiri_check/src/state/command.dart';

final class Initialize<State, System> extends Command<State, System> {
  Initialize(
    super.description,
    this.command, {
    super.precondition,
    super.postcondition,
  });

  final Command<State, System> command;

  @override
  List<Command<State, System>> get subcommands => [command];

  @override
  bool requires(State state) {
    return command.requires(state);
  }

  @override
  bool ensures(State state, System system) {
    return command.ensures(state, system);
  }

  @override
  void execute(State state, System system, Random random) {
    command.execute(state, system, random);
  }
}
