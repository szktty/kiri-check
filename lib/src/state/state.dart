import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

// ignore: one_member_abstracts
abstract class Behavior<T extends State> {
  @factory
  T createState();

  List<Command<T>> generateCommands(T state);
}

abstract class State {
  late final RandomContext random;

  void setUp() {}

  void tearDown() {}
}
