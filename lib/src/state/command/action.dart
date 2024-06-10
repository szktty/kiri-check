import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:meta/meta.dart';

enum ActionShrinkingState {
  notStarted,
  running,
  finished,
}

/// A command that performs an action with generated values.
final class Action<State, System, T, R> extends Command<State, System, R> {
  /// Creates a new action command.
  ///
  /// Parameters:
  /// - `description`: The description of the action.
  /// - `arbitrary`: The arbitrary used to generate values.
  /// - `run`: A function to perform the action.
  /// - `require`: A function to test the precondition of the action.
  /// - `ensure`: A function to test the postcondition of the action.
  Action(
    super.description,
    Arbitrary<T> arbitrary, {
    required void Function(State, T) update,
    required R Function(System, T) run,
    bool Function(State)? require,
    bool Function(State, R)? ensure,
  }) {
    _arbitrary = arbitrary;
    _update = update;
    _run = run;

    _require = require;
    _ensure = ensure;
  }

  late final Arbitrary<T> _arbitrary;

  ArbitraryBase<T> get _arbitraryBase => _arbitrary as ArbitraryBase<T>;
  late final R Function(System, T) _run;
  late final void Function(State, T) _update;

  late final bool Function(State)? _require;
  late final bool Function(State, R)? _ensure;

  T? _current;

  @override
  void update(State state) {
    _update(state, _current as T);
  }

  @override
  R run(System system) {
    return _run(system, _current as T);
  }

  @override
  bool requires(State state) {
    return _require?.call(state) ?? true;
  }

  @override
  bool ensures(State state, R result) {
    return _ensure?.call(state, result) ?? true;
  }

  /// @nodoc
  @override
  ActionContext<State, System, T, R> createContext() {
    return ActionContext(this);
  }
}

final class ActionContext<State, System, T, R>
    extends CommandContext<State, System, R> {
  ActionContext(super.command) {
    _distance = null;
    _shrunkQueue = null;
  }

  Action<State, System, T, R> get action =>
      command as Action<State, System, T, R>;

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
  T? _current;

  @override
  dynamic get minValue => _minShrunk;

  T generateValue(Random random) {
    if (_shrinkState == ActionShrinkingState.running) {
      if (_shrunkQueue!.isNotEmpty) {
        _lastShrunk = _shrunkQueue!.removeFirst();
      }
      return _lastShrunk!;
    } else if (useCache) {
      return _cache!;
    } else {
      return _cache = arbitrary.generate(random as RandomContext);
    }
  }

  @override
  void update(State state) {
    _current ??= generateValue(command.random);
    action
      .._current = _current
      ..update(state);
  }

  @override
  R run(System system) {
    _current = null;
    return action.run(system);
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
final class Action0<State, System, R> extends Action<State, System, void, R> {
  Action0(
    String description, {
    required void Function(State) update,
    required R Function(System) run,
    super.require,
    super.ensure,
  }) : super(
          description,
          null_(),
          update: (s, _) => update(s),
          run: (sys, _) => run(sys),
        );
}

/// A command [Action] with 2 arbitraries.
final class Action2<State, System, E1, E2, R>
    extends Action<State, System, (E1, E2), R> {
  Action2(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2, {
    required void Function(State, E1, E2) update,
    required R Function(System, E1, E2) run,
    super.require,
    super.ensure,
  }) : super(
          description,
          combine2(arbitrary1, arbitrary2, (a, b) => (a, b)),
          update: (s, args) => update(s, args.$1, args.$2),
          run: (sys, args) => run(sys, args.$1, args.$2),
        );
}
