import 'dart:math';

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';

abstract class Command<State, System> {
  Command(
    this.description, {
    bool Function(State, System)? precondition,
    bool Function(State, System)? postcondition,
  }) {
    _precondition = precondition;
    _postcondition = postcondition;
  }

  final String description;

  late final bool Function(State, System)? _precondition;
  late final bool Function(State, System)? _postcondition;

  List<Command<State, System>> get subcommands => const [];

  bool requires(State state, System system) {
    return _precondition?.call(state, system) ?? true;
  }

  bool ensures(State state, System system) {
    return _postcondition?.call(state, system) ?? true;
  }

  void execute(State state, System system, Random random);

  @internal
  bool useCache = false;

  @internal
  bool nextShrink() => false;

  @internal
  void failShrunk() {}

  @internal
  dynamic get minValue => null;
}
