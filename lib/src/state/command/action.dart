import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';

enum ActionShrinkingState {
  notStarted,
  running,
  finished,
}

/// A command that performs an action with generated values.
final class Action<State, System, T> extends Command<State, System> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary`: The arbitrary used to generate values.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action(
    super.description,
    Arbitrary<T> arbitrary,
    void Function(State, System, T) action, {
    bool Function(State)? precondition,
    bool Function(State, System)? postcondition,
  }) {
    _arbitrary = arbitrary;
    _action = action;

    _precondition = precondition;
    _postcondition = postcondition;
  }

  late final Arbitrary<T> _arbitrary;

  ArbitraryBase<T> get _arbitraryBase => _arbitrary as ArbitraryBase<T>;
  late final void Function(State, System, T) _action;

  late final bool Function(State)? _precondition;
  late final bool Function(State, System)? _postcondition;

  /// @nodoc
  @override
  bool requires(State state) {
    return _precondition?.call(state) ?? true;
  }

  /// @nodoc
  @override
  bool ensures(State state, System system) {
    return _postcondition?.call(state, system) ?? true;
  }

  void _execute(State state, System system, dynamic value) {
    _action(state, system, value as T);
  }
}

final class ActionContext<State, System, T>
    extends CommandContext<State, System> {
  ActionContext(super.command) {
    _distance = null;
    _shrunkQueue = null;
  }

  Action<State, System, T> get action => command as Action<State, System, T>;

  ArbitraryBase<T> get arbitrary => action._arbitraryBase;

  @override
  bool useCache = false;

  T? _cache;
  ActionShrinkingState _shrinkState = ActionShrinkingState.notStarted;
  ShrinkingDistance? _distance;
  int _shrinkGranularity = 1;
  List<T>? _previousShrunk;
  Queue<T>? _shrunkQueue;
  T? _minShrunk;
  T? _lastShrunk;

  @override
  dynamic get minValue => _minShrunk;

  @override
  void execute(State state, System system, Random random) {
    if (_shrinkState == ActionShrinkingState.running) {
      if (_shrunkQueue!.isNotEmpty) {
        _lastShrunk = _shrunkQueue!.removeFirst();
        action._execute(state, system, _lastShrunk as T);
      } else {
        action._execute(state, system, _lastShrunk as T);
      }
    } else if (useCache) {
      action._execute(state, system, _cache as T);
    } else {
      final value = arbitrary.generate(random as RandomContext);
      _cache = value;
      action._execute(state, system, value);
    }
  }

  @override
  bool nextShrink() {
    switch (_shrinkState) {
      case ActionShrinkingState.notStarted:
        _shrinkState = ActionShrinkingState.running;
        _distance = arbitrary.calculateDistance(_cache as T)
          ..granularity = _shrinkGranularity;
        final shrunk = arbitrary.shrink(_cache as T, _distance!);
        _previousShrunk = shrunk;
        _shrunkQueue = Queue.of(shrunk);
        _minShrunk = _cache;
        return true;
      case ActionShrinkingState.running:
        if (_shrunkQueue!.isNotEmpty) {
          return true;
        } else {
          _shrinkGranularity++;
          _distance!.granularity = _shrinkGranularity;
          final shrunk = arbitrary.shrink(_cache as T, _distance!);
          if (const DeepCollectionEquality().equals(shrunk, _previousShrunk)) {
            _shrinkState = ActionShrinkingState.finished;
            return false;
          } else {
            _previousShrunk = shrunk;
            _shrunkQueue = Queue.of(shrunk);
            return true;
          }
        }
      case ActionShrinkingState.finished:
        return false;
    }
  }

  @override
  void failShrunk() {
    _minShrunk = _lastShrunk;
  }
}

/// A command [Action] with no arbitrary.
final class Action0<State, System> extends Action<State, System, void> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action0(
    String description,
    void Function(State, System) action, {
    super.precondition,
    super.postcondition,
  }) : super(description, null_(), (s, sys, _) => action(s, sys));
}

/// A command [Action] with 2 arbitraries.
final class Action2<State, System, T, E1, E2>
    extends Action<State, System, (E1, E2)> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action2(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    void Function(State, System, E1, E2) action, {
    super.precondition,
    super.postcondition,
  }) : super(
          description,
          combine2(arbitrary1, arbitrary2, (a, b) => (a, b)),
          (s, sys, args) => action(s, sys, args.$1, args.$2),
        );
}

/// A command [Action] with 3 arbitraries.
final class Action3<State, System, T, E1, E2, E3>
    extends Action<State, System, (E1, E2, E3)> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action3(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    void Function(State, System, E1, E2, E3) action, {
    super.precondition,
    super.postcondition,
  }) : super(
          description,
          combine3(arbitrary1, arbitrary2, arbitrary3, (a, b, c) => (a, b, c)),
          (s, sys, args) => action(s, sys, args.$1, args.$2, args.$3),
        );
}

/// A command [Action] with 4 arbitraries.
final class Action4<State, System, T, E1, E2, E3, E4>
    extends Action<State, System, (E1, E2, E3, E4)> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action4(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    void Function(State, System, E1, E2, E3, E4) action, {
    super.precondition,
    super.postcondition,
  }) : super(
          description,
          combine4(
            arbitrary1,
            arbitrary2,
            arbitrary3,
            arbitrary4,
            (a, b, c, d) => (a, b, c, d),
          ),
          (s, sys, args) => action(s, sys, args.$1, args.$2, args.$3, args.$4),
        );
}

/// A command [Action] with 5 arbitraries.
final class Action5<State, System, T, E1, E2, E3, E4, E5>
    extends Action<State, System, (E1, E2, E3, E4, E5)> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `arbitrary5`: The arbitrary used to generate the fifth value.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action5(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    void Function(State, System, E1, E2, E3, E4, E5) action, {
    super.precondition,
    super.postcondition,
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
          (s, sys, args) =>
              action(s, sys, args.$1, args.$2, args.$3, args.$4, args.$5),
        );
}

/// A command [Action] with 6 arbitraries.
final class Action6<State, System, T, E1, E2, E3, E4, E5, E6>
    extends Action<State, System, (E1, E2, E3, E4, E5, E6)> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary1`: The arbitrary used to generate the first value.
  /// - `arbitrary2`: The arbitrary used to generate the second value.
  /// - `arbitrary3`: The arbitrary used to generate the third value.
  /// - `arbitrary4`: The arbitrary used to generate the fourth value.
  /// - `arbitrary5`: The arbitrary used to generate the fifth value.
  /// - `arbitrary6`: The arbitrary used to generate the sixth value.
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action6(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    Arbitrary<E6> arbitrary6,
    void Function(State, System, E1, E2, E3, E4, E5, E6) action, {
    super.precondition,
    super.postcondition,
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
          (s, sys, args) => action(
            s,
            sys,
            args.$1,
            args.$2,
            args.$3,
            args.$4,
            args.$5,
            args.$6,
          ),
        );
}

/// A command [Action] with 7 arbitraries.
final class Action7<State, System, T, E1, E2, E3, E4, E5, E6, E7>
    extends Action<State, System, (E1, E2, E3, E4, E5, E6, E7)> {
  /// Creates a new action command.
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
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action7(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    Arbitrary<E6> arbitrary6,
    Arbitrary<E7> arbitrary7,
    void Function(State, System, E1, E2, E3, E4, E5, E6, E7) action, {
    super.precondition,
    super.postcondition,
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
          (s, sys, args) => action(
            s,
            sys,
            args.$1,
            args.$2,
            args.$3,
            args.$4,
            args.$5,
            args.$6,
            args.$7,
          ),
        );
}

/// A command [Action] with 8 arbitraries.
final class Action8<State, System, T, E1, E2, E3, E4, E5, E6, E7, E8>
    extends Action<State, System, (E1, E2, E3, E4, E5, E6, E7, E8)> {
  /// Creates a new action command.
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
  /// - `action`: A function to execute the action.
  /// - `precondition`: A function to describe the precondition of the action.
  /// - `postcondition`: A function to describe the postcondition of the action.
  Action8(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    Arbitrary<E6> arbitrary6,
    Arbitrary<E7> arbitrary7,
    Arbitrary<E8> arbitrary8,
    void Function(State, System, E1, E2, E3, E4, E5, E6, E7, E8) action, {
    super.precondition,
    super.postcondition,
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
          (s, sys, args) => action(
            s,
            sys,
            args.$1,
            args.$2,
            args.$3,
            args.$4,
            args.$5,
            args.$6,
            args.$7,
            args.$8,
          ),
        );
}
