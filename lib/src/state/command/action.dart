import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command/command.dart';
import 'package:kiri_check/src/state/command/context.dart';
import 'package:meta/meta.dart';

/// A command that performs an action with generated values.
final class Action<State, System, T, R> extends Command<State, System> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary`: The arbitrary used to generate values.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action(
    super.description,
    this.arbitrary, {
    required void Function(State, T) nextState,
    required R Function(System, T) run,
    bool Function(State, T)? precondition,
    bool Function(State, T, R)? postcondition,
  }) {
    _nextState = nextState;
    _run = run;
    _precondition = precondition;
    _postcondition = postcondition;
  }

  /// :nodoc:
  @internal
  final Arbitrary<T>? arbitrary;

  late final R Function(System, T) _run;
  late final void Function(State, T) _nextState;

  late final bool Function(State, T)? _precondition;
  late final bool Function(State, T, R)? _postcondition;

  @override
  void nextState(CommandContext<State, System> context, State state) {
    _nextState(state, context.currentValue as T);
  }

  @override
  R run(CommandContext<State, System> context, System system) {
    return _run(system, context.currentValue as T);
  }

  @override
  bool precondition(CommandContext<State, System> context, State state) {
    return _precondition?.call(state, context.currentValue as T) ?? true;
  }

  @override
  bool postcondition(
      CommandContext<State, System> context, State state, dynamic result) {
    return _postcondition?.call(
          state,
          context.currentValue as T,
          result as R,
        ) ??
        true;
  }
}

/// A command [Action] with no arbitrary.
final class Action0<State, System, R> extends Action<State, System, void, R> {
  /// Creates a new action command with no arbitrary.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `nextState`: A function to update the state.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action0(
    String description, {
    required void Function(State) nextState,
    required R Function(System) run,
    bool Function(State)? precondition,
    bool Function(State, R)? postcondition,
  }) : super(
          description,
          null,
          nextState: (s, _) => nextState(s),
          run: (sys, _) => run(sys),
          precondition: (s, _) => precondition?.call(s) ?? true,
          postcondition: (s, _, r) => postcondition?.call(s, r) ?? true,
        );
}

/// A command [Action] with 2 arbitraries.
final class Action2<State, System, T1, T2, R>
    extends Action<State, System, (T1, T2), R> {
  /// Creates a new action command with 2 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action2(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2, {
    required void Function(State, T1, T2) nextState,
    required R Function(System, T1, T2) run,
    super.precondition,
    super.postcondition,
  }) : super(
          description,
          combine2(arbitrary1, arbitrary2, (a, b) => (a, b)),
          nextState: (s, args) => nextState(s, args.$1, args.$2),
          run: (sys, args) => run(sys, args.$1, args.$2),
        );
}
