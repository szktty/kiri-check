import 'package:kiri_check/src/state/command.dart';
import 'package:meta/meta.dart';

abstract class Behavior<State, System> {
  @factory
  State createState();

  @factory
  System createSystem(State state);

  List<Command<State, System>> generateCommands(State state);

  void dispose(State state, System system) {}
}
