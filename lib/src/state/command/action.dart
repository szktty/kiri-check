import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';

enum ActionShrinkingState {
  notStarted,
  running,
  finished,
}

abstract class ActionBase<State, System, T> extends Command<State, System> {
  ActionBase(
    super.description, {
    bool Function(State)? precondition,
    bool Function(State, System)? postcondition,
  }) {
    _precondition = precondition;
    _postcondition = postcondition;
  }

  late final bool Function(State)? _precondition;
  late final bool Function(State, System)? _postcondition;

  @override
  bool requires(State state) {
    return _precondition?.call(state) ?? true;
  }

  @override
  bool ensures(State state, System system) {
    return _postcondition?.call(state, system) ?? true;
  }

  @override
  @internal
  bool useCache = false;

  @override
  @internal
  bool nextShrink() => false;

  @override
  @internal
  void failShrunk() {}

  @override
  @internal
  dynamic get minValue => null;
}

final class Action<State, System, T> extends ActionBase<State, System, T> {
  Action(
    super.description,
    Arbitrary<T> arbitrary,
    void Function(State, System, T) action, {
    super.precondition,
    super.postcondition,
  }) {
    _arbitrary = arbitrary;
    _action = action;
    _distance = null;
    _shrunkQueue = null;
  }

  late final Arbitrary<T> _arbitrary;

  ArbitraryBase<T> get _arbitraryBase => _arbitrary as ArbitraryBase<T>;
  late final void Function(State, System, T) _action;

  T? _cache;

  @override
  void execute(State state, System system, Random random) {
    if (_shrinkState == ActionShrinkingState.running) {
      if (_shrunkQueue!.isNotEmpty) {
        _lastShrunk = _shrunkQueue!.removeFirst();
        _action(state, system, _lastShrunk as T);
      } else {
        _action(state, system, _lastShrunk as T);
      }
    } else if (useCache) {
      _action(state, system, _cache as T);
    } else {
      final value = _arbitraryBase.generate(random as RandomContext);
      _cache = value;
      _action(state, system, value);
    }
  }

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
  bool nextShrink() {
    switch (_shrinkState) {
      case ActionShrinkingState.notStarted:
        _shrinkState = ActionShrinkingState.running;
        _distance = _arbitraryBase.calculateDistance(_cache as T)
          ..granularity = _shrinkGranularity;
        final shrunk = _arbitraryBase.shrink(_cache as T, _distance!);
        print('first shrink: $shrunk');
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
          final shrunk = _arbitraryBase.shrink(_cache as T, _distance!);
          print('next shrink: $shrunk');
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

final class Action0<State, System> extends Action<State, System, void> {
  Action0(
    String description,
    void Function(State, System) action, {
    super.precondition,
    super.postcondition,
  }) : super(description, null_(), (s, sys, _) => action(s, sys));
}

final class Action2<State, System, T, E1, E2>
    extends Action<State, System, (E1, E2)> {
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

final class Action3<State, System, T, E1, E2, E3>
    extends Action<State, System, (E1, E2, E3)> {
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

final class Action4<State, System, T, E1, E2, E3, E4>
    extends Action<State, System, (E1, E2, E3, E4)> {
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
          combine4(arbitrary1, arbitrary2, arbitrary3, arbitrary4,
              (a, b, c, d) => (a, b, c, d)),
          (s, sys, args) => action(s, sys, args.$1, args.$2, args.$3, args.$4),
        );
}

final class Action5<State, System, T, E1, E2, E3, E4, E5>
    extends Action<State, System, (E1, E2, E3, E4, E5)> {
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
          combine5(arbitrary1, arbitrary2, arbitrary3, arbitrary4, arbitrary5,
              (a, b, c, d, e) => (a, b, c, d, e)),
          (s, sys, args) =>
              action(s, sys, args.$1, args.$2, args.$3, args.$4, args.$5),
        );
}

final class Action6<State, System, T, E1, E2, E3, E4, E5, E6>
    extends Action<State, System, (E1, E2, E3, E4, E5, E6)> {
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
          combine6(arbitrary1, arbitrary2, arbitrary3, arbitrary4, arbitrary5,
              arbitrary6, (a, b, c, d, e, f) => (a, b, c, d, e, f)),
          (s, sys, args) => action(
              s, sys, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6),
        );
}

final class Action7<State, System, T, E1, E2, E3, E4, E5, E6, E7>
    extends Action<State, System, (E1, E2, E3, E4, E5, E6, E7)> {
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
              (a, b, c, d, e, f, g) => (a, b, c, d, e, f, g)),
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

final class Action8<State, System, T, E1, E2, E3, E4, E5, E6, E7, E8>
    extends Action<State, System, (E1, E2, E3, E4, E5, E6, E7, E8)> {
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
              (a, b, c, d, e, f, g, h) => (a, b, c, d, e, f, g, h)),
          (s, sys, args) => action(s, sys, args.$1, args.$2, args.$3, args.$4,
              args.$5, args.$6, args.$7, args.$8),
        );
}
