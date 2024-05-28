import 'dart:math';

import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:meta/meta.dart';

// ignore: one_member_abstracts
abstract class Behavior<State, System> {
  @factory
  State createState();

  @factory
  System createSystem(State state);

  List<Command<State, System>> generateCommands(State state);
}
