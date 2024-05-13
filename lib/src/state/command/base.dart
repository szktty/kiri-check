import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

abstract class Command<T extends State> {
  Command(
    this.description, {
    this.precondition,
    this.postcondition,
    this.nextState,
  });

  final String description;
  final bool Function(T)? precondition;
  final bool Function(T)? postcondition;
  final T Function(T)? nextState;

  void run(T state);
}

final class Update<T extends State> extends Command<T> {
  Update(
    super.description,
    this.target,
    this.arbitrary, {
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final Bundle<T> target;
  final Arbitrary<T> arbitrary;

  @override
  void run(T state) {
    // プロパティ側で処理する
  }
}

final class Action<T extends State> extends Command<T> {
  Action(
    super.description,
    this.action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  });

  final void Function(T) action;

  @override
  void run(T state) {
    action(state);
  }
}
