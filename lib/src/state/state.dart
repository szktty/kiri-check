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
  // 乱数が必要な場合はこれを使うこと
  // これを使うと、シードの指定で再現可能になる
  late final RandomContext random;
}
