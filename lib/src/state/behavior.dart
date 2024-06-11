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
  State createState();

  /// Creates a new system with the given state.
  @factory
  System createSystem(State state);

  /// Generates a list of commands to run on the given state.
  List<Command<State, System>> generateCommands(State state);

  /// Disposes of the given state and system.
  void dispose(State state, System system) {}

  /// Called before the test is run.
  void setUp() {}

  /// Called once before all tests are run.
  void setUpAll() {}

  /// Called after the test is run.
  void tearDown() {}

  /// Called once after all tests are run.
  void tearDownAll() {}
}
