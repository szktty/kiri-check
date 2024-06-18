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
  State initialState();

  bool initialPrecondition(State state) => true;

  /// Creates a new system with the given state.
  @factory
  System createSystem(State state);

  /// Generates a list of commands to run on the given state.
  List<Command<State, System>> generateCommands(State state);

  /// Destroy the given system.
  void destroySystem(System system);

  /// Called before the cycle is run.
  void setUp() {}

  /// Called once before all cycles are run.
  void setUpAll() {}

  /// Called after the cycle is run.
  void tearDown() {}

  /// Called once after all cycles are run.
  void tearDownAll() {}

  /// Called at the beginning of the command generation phase.
  void onGenerate(State state) {}

  /// Called at the beginning of the execution phase.
  void onExecute(State state, System system) {}
}
