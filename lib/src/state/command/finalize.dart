import 'dart:math';

import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';

final class Finalize<State, System> extends Command<State, System> {
  Finalize(
    super.description,
    this.command, {
    super.precondition,
    super.postcondition,
  });

  final Command<State, System> command;

  @override
  List<Command<State, System>> get subcommands => [command];

  @override
  void execute(State state, System system, Random random) {
    command.execute(state, system, random);
  }
}
