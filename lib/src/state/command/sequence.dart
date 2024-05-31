import 'dart:math';

import 'package:kiri_check/src/state/command.dart';

final class Sequence<State, System> extends Command<State, System> {
  Sequence(super.description, this.commands);

  final List<Command<State, System>> commands;

  @override
  bool get useCache => false;

  @override
  set useCache(bool value) {
    // do nothing
  }

  @override
  bool requires(State state) {
    return true;
  }

  @override
  bool ensures(State state, System system) {
    // do nothing
    return true;
  }

  @override
  void execute(State state, System system, Random random) {
    // do nothing
  }

  @override
  bool nextShrink() {
    // do nothing
    return false;
  }

  @override
  void failShrunk() {
    // do nothing
  }

  @override
  dynamic get minValue => null;
}
