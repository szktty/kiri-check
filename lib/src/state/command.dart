import 'dart:math';

import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';

abstract class Command<State, System> {
  Command(
    this.description, {
    bool Function(State)? precondition,
    bool Function(State)? postcondition,
  }) {
    _precondition = precondition;
    _postcondition = postcondition;
  }

  final String description;

  late final bool Function(State)? _precondition;
  late final bool Function(State)? _postcondition;

  List<Command<State, System>> get subcommands => const [];

  bool requires(State state) {
    return _precondition?.call(state) ?? true;
  }

  bool ensures(State state) {
    return _postcondition?.call(state) ?? true;
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
