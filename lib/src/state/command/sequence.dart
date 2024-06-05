import 'dart:math';

import 'package:kiri_check/src/state/command.dart';

final class Sequence<State, System> extends Command<State, System> {
  Sequence(super.description, this.commands);

  final List<Command<State, System>> commands;

  @override
  bool requires(State state) {
    // do nothing
    return true;
  }

  @override
  bool ensures(State state, System system) {
    // do nothing
    return true;
  }
}
