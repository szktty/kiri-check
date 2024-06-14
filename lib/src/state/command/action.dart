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
    bool Function(State, T1, T2)? precondition,
    bool Function(State, T1, T2, R)? postcondition,
  }) : super(
          description,
          combine2(arbitrary1, arbitrary2, (a, b) => (a, b)),
          nextState: (s, args) => nextState(s, args.$1, args.$2),
          run: (sys, args) => run(sys, args.$1, args.$2),
          precondition: (s, args) =>
              precondition?.call(s, args.$1, args.$2) ?? true,
          postcondition: (s, args, r) =>
              postcondition?.call(s, args.$1, args.$2, r) ?? true,
        );
}

/// A command [Action] with 3 arbitraries.
final class Action3<State, System, T1, T2, T3, R>
    extends Action<State, System, (T1, T2, T3), R> {
  /// Creates a new action command with 3 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action3(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2,
    Arbitrary<T3> arbitrary3, {
    required void Function(State, T1, T2, T3) nextState,
    required R Function(System, T1, T2, T3) run,
    bool Function(State, T1, T2, T3)? precondition,
    bool Function(State, T1, T2, T3, R)? postcondition,
  }) : super(
          description,
          combine3(arbitrary1, arbitrary2, arbitrary3, (a, b, c) => (a, b, c)),
          nextState: (s, args) => nextState(s, args.$1, args.$2, args.$3),
          run: (sys, args) => run(sys, args.$1, args.$2, args.$3),
          precondition: (s, args) =>
              precondition?.call(s, args.$1, args.$2, args.$3) ?? true,
          postcondition: (s, args, r) =>
              postcondition?.call(s, args.$1, args.$2, args.$3, r) ?? true,
        );
}

/// A command [Action] with 4 arbitraries.
final class Action4<State, System, T1, T2, T3, T4, R>
    extends Action<State, System, (T1, T2, T3, T4), R> {
  /// Creates a new action command with 4 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action4(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2,
    Arbitrary<T3> arbitrary3,
    Arbitrary<T4> arbitrary4, {
    required void Function(State, T1, T2, T3, T4) nextState,
    required R Function(System, T1, T2, T3, T4) run,
    bool Function(State, T1, T2, T3, T4)? precondition,
    bool Function(State, T1, T2, T3, T4, R)? postcondition,
  }) : super(
          description,
          combine4(
            arbitrary1,
            arbitrary2,
            arbitrary3,
            arbitrary4,
            (a, b, c, d) => (a, b, c, d),
          ),
          nextState: (s, args) =>
              nextState(s, args.$1, args.$2, args.$3, args.$4),
          run: (sys, args) => run(sys, args.$1, args.$2, args.$3, args.$4),
          precondition: (s, args) =>
              precondition?.call(s, args.$1, args.$2, args.$3, args.$4) ?? true,
          postcondition: (s, args, r) =>
              postcondition?.call(s, args.$1, args.$2, args.$3, args.$4, r) ??
              true,
        );
}

/// A command [Action] with 5 arbitraries.
final class Action5<State, System, T1, T2, T3, T4, T5, R>
    extends Action<State, System, (T1, T2, T3, T4, T5), R> {
  /// Creates a new action command with 5 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `arbitrary5`: The arbitrary used to generate the fifth value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action5(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2,
    Arbitrary<T3> arbitrary3,
    Arbitrary<T4> arbitrary4,
    Arbitrary<T5> arbitrary5, {
    required void Function(State, T1, T2, T3, T4, T5) nextState,
    required R Function(System, T1, T2, T3, T4, T5) run,
    bool Function(State, T1, T2, T3, T4, T5)? precondition,
    bool Function(State, T1, T2, T3, T4, T5, R)? postcondition,
  }) : super(
          description,
          combine5(
            arbitrary1,
            arbitrary2,
            arbitrary3,
            arbitrary4,
            arbitrary5,
            (a, b, c, d, e) => (a, b, c, d, e),
          ),
          nextState: (s, args) =>
              nextState(s, args.$1, args.$2, args.$3, args.$4, args.$5),
          run: (sys, args) =>
              run(sys, args.$1, args.$2, args.$3, args.$4, args.$5),
          precondition: (s, args) =>
              precondition?.call(
                  s, args.$1, args.$2, args.$3, args.$4, args.$5) ??
              true,
          postcondition: (s, args, r) =>
              postcondition?.call(
                  s, args.$1, args.$2, args.$3, args.$4, args.$5, r) ??
              true,
        );
}

/// A command [Action] with 6 arbitraries.
final class Action6<State, System, T1, T2, T3, T4, T5, T6, R>
    extends Action<State, System, (T1, T2, T3, T4, T5, T6), R> {
  /// Creates a new action command with 6 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `arbitrary5`: The arbitrary used to generate the fifth value.
  /// - `arbitrary6`: The arbitrary used to generate the sixth value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action6(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2,
    Arbitrary<T3> arbitrary3,
    Arbitrary<T4> arbitrary4,
    Arbitrary<T5> arbitrary5,
    Arbitrary<T6> arbitrary6, {
    required void Function(State, T1, T2, T3, T4, T5, T6) nextState,
    required R Function(System, T1, T2, T3, T4, T5, T6) run,
    bool Function(State, T1, T2, T3, T4, T5, T6)? precondition,
    bool Function(State, T1, T2, T3, T4, T5, T6, R)? postcondition,
  }) : super(
          description,
          combine6(
            arbitrary1,
            arbitrary2,
            arbitrary3,
            arbitrary4,
            arbitrary5,
            arbitrary6,
            (a, b, c, d, e, f) => (a, b, c, d, e, f),
          ),
          nextState: (s, args) => nextState(
              s, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6),
          run: (sys, args) =>
              run(sys, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6),
          precondition: (s, args) =>
              precondition?.call(
                  s, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6) ??
              true,
          postcondition: (s, args, r) =>
              postcondition?.call(
                  s, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6, r) ??
              true,
        );
}

/// A command [Action] with 7 arbitraries.
final class Action7<State, System, T1, T2, T3, T4, T5, T6, T7, R>
    extends Action<State, System, (T1, T2, T3, T4, T5, T6, T7), R> {
  /// Creates a new action command with 7 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `arbitrary5`: The arbitrary used to generate the fifth value.
  /// - `arbitrary6`: The arbitrary used to generate the sixth value.
  /// - `arbitrary7`: The arbitrary used to generate the seventh value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action7(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2,
    Arbitrary<T3> arbitrary3,
    Arbitrary<T4> arbitrary4,
    Arbitrary<T5> arbitrary5,
    Arbitrary<T6> arbitrary6,
    Arbitrary<T7> arbitrary7, {
    required void Function(State, T1, T2, T3, T4, T5, T6, T7) nextState,
    required R Function(System, T1, T2, T3, T4, T5, T6, T7) run,
    bool Function(State, T1, T2, T3, T4, T5, T6, T7)? precondition,
    bool Function(State, T1, T2, T3, T4, T5, T6, T7, R)? postcondition,
  }) : super(
          description,
          combine7(
            arbitrary1,
            arbitrary2,
            arbitrary3,
            arbitrary4,
            arbitrary5,
            arbitrary6,
            arbitrary7,
            (a, b, c, d, e, f, g) => (a, b, c, d, e, f, g),
          ),
          nextState: (s, args) => nextState(
              s, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6, args.$7),
          run: (sys, args) => run(sys, args.$1, args.$2, args.$3, args.$4,
              args.$5, args.$6, args.$7),
          precondition: (s, args) =>
              precondition?.call(s, args.$1, args.$2, args.$3, args.$4, args.$5,
                  args.$6, args.$7) ??
              true,
          postcondition: (s, args, r) =>
              postcondition?.call(s, args.$1, args.$2, args.$3, args.$4,
                  args.$5, args.$6, args.$7, r) ??
              true,
        );
}

/// A command [Action] with 8 arbitraries.
final class Action8<State, System, T1, T2, T3, T4, T5, T6, T7, T8, R>
    extends Action<State, System, (T1, T2, T3, T4, T5, T6, T7, T8), R> {
  /// Creates a new action command with 8 arbitraries.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `arbitrary5`: The arbitrary used to generate the fifth value.
  /// - `arbitrary6`: The arbitrary used to generate the sixth value.
  /// - `arbitrary7`: The arbitrary used to generate the seventh value.
  /// - `arbitrary8`: The arbitrary used to generate the eighth value.
  /// - `run`: A function to perform the action.
  /// - `precondition`: A function to test the precondition of the action.
  /// - `postcondition`: A function to test the postcondition of the action.
  Action8(
    String description,
    Arbitrary<T1> arbitrary1,
    Arbitrary<T2> arbitrary2,
    Arbitrary<T3> arbitrary3,
    Arbitrary<T4> arbitrary4,
    Arbitrary<T5> arbitrary5,
    Arbitrary<T6> arbitrary6,
    Arbitrary<T7> arbitrary7,
    Arbitrary<T8> arbitrary8, {
    required void Function(State, T1, T2, T3, T4, T5, T6, T7, T8) nextState,
    required R Function(System, T1, T2, T3, T4, T5, T6, T7, T8) run,
    bool Function(State, T1, T2, T3, T4, T5, T6, T7, T8)? precondition,
    bool Function(State, T1, T2, T3, T4, T5, T6, T7, T8, R)? postcondition,
  }) : super(
          description,
          combine8(
            arbitrary1,
            arbitrary2,
            arbitrary3,
            arbitrary4,
            arbitrary5,
            arbitrary6,
            arbitrary7,
            arbitrary8,
            (a, b, c, d, e, f, g, h) => (a, b, c, d, e, f, g, h),
          ),
          nextState: (s, args) => nextState(s, args.$1, args.$2, args.$3,
              args.$4, args.$5, args.$6, args.$7, args.$8),
          run: (sys, args) => run(sys, args.$1, args.$2, args.$3, args.$4,
              args.$5, args.$6, args.$7, args.$8),
          precondition: (s, args) =>
              precondition?.call(s, args.$1, args.$2, args.$3, args.$4, args.$5,
                  args.$6, args.$7, args.$8) ??
              true,
          postcondition: (s, args, r) =>
              postcondition?.call(s, args.$1, args.$2, args.$3, args.$4,
                  args.$5, args.$6, args.$7, args.$8, r) ??
              true,
        );
}
