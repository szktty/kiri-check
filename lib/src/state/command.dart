import 'dart:math';

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';

abstract class Command<State, System> {
  Command(this.description);

  final String description;

  bool requires(State state);

  bool ensures(State state, System system);

  void execute(State state, System system, Random random);

  @internal
  bool get useCache;

  set useCache(bool value);

  @internal
  bool nextShrink();

  @internal
  void failShrunk();

  @internal
  dynamic get minValue;
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

  @override
  void execute(State state, System system, Random random) {
    command.execute(state, system, random);
  }

  @override
  bool get useCache => command.useCache;

  @override
  set useCache(bool value) {
    command.useCache = value;
  }

  @override
  bool nextShrink() => command.nextShrink();

  @override
  void failShrunk() => command.failShrunk();

  @override
  dynamic get minValue => command.minValue;
}

final class Initialize<State, System> extends Container<State, System> {
  Initialize(super.description, super.command);
}

final class Finalize<State, System> extends Container<State, System> {
  Finalize(super.description, super.command);
}
