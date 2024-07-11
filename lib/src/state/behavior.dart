import 'dart:async';

import 'package:kiri_check/src/state/command/command.dart';
import 'package:kiri_check/src/state/top.dart';
import 'package:meta/meta.dart';

/// Describes behavior of a stateful test.
///
/// See also:
/// - [runBehavior], runs a stateful test according to the behavior.
abstract class Behavior<State, System> {
  /// Creates a new state.
  @factory
  FutureOr<State> initialState();

  /// Returns true if the given state satisfies the initial precondition.
  FutureOr<bool> initialPrecondition(State state) => true;

  /// Creates a new system with the given state.
  @factory
  FutureOr<System> createSystem(State state);

  /// Generates a list of commands to run on the given state.
  FutureOr<List<Command<State, System>>> generateCommands(State state);

  /// Destroy the given system.
  FutureOr<void> destroySystem(System system);

  /// Called before the cycle is run.
  FutureOr<void> setUp() async {}

  /// Called once before all cycles are run.
  FutureOr<void> setUpAll() async {}

  /// Called after the cycle is run.
  FutureOr<void> tearDown() async {}

  /// Called once after all cycles are run.
  FutureOr<void> tearDownAll() async {}

  /// Called at the beginning of the command generation phase.
  FutureOr<void> onGenerate(State state) async {}

  /// Called at the beginning of the execution phase.
  FutureOr<void> onExecute(State state, System system) async {}
}
