import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';

enum ActionShrinkingState {
  notStarted,
  running,
  finished,
}

final class Action<T extends State, U> extends Command<T> {
  Action(
    super.description,
    Arbitrary<U> arbitrary,
    void Function(T, U) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) {
    _arbitrary = arbitrary;
    _action = action;
    _distance = null;
    _shrunkQueue = null;
  }

  late final Arbitrary<U> _arbitrary;

  ArbitraryBase<U> get _arbitraryBase => _arbitrary as ArbitraryBase<U>;
  late final void Function(T, U) _action;

  U? _cache;

  @override
  void execute(T state) {
    if (_shrinkState == ActionShrinkingState.running) {
      if (_shrunkQueue!.isNotEmpty) {
        _lastShrunk = _shrunkQueue!.removeFirst();
        _action(state, _lastShrunk as U);
      } else {
        _action(state, _lastShrunk as U);
      }
    } else if (useCache) {
      _action(state, _cache as U);
    } else {
      final value = _arbitraryBase.generate(state.random as RandomContext);
      _cache = value;
      _action(state, value);
    }
  }

  ActionShrinkingState _shrinkState = ActionShrinkingState.notStarted;
  ShrinkingDistance? _distance;
  int _shrinkGranularity = 1;
  List<U>? _previousShrunk;
  Queue<U>? _shrunkQueue;
  U? _minShrunk;
  U? _lastShrunk;

  @override
  dynamic get falsifyingExample => _minShrunk;

  @override
  bool nextShrink() {
    switch (_shrinkState) {
      case ActionShrinkingState.notStarted:
        _shrinkState = ActionShrinkingState.running;
        _distance = _arbitraryBase.calculateDistance(_cache as U)
          ..granularity = _shrinkGranularity;
        final shrunk = _arbitraryBase.shrink(_cache as U, _distance!);
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
          final shrunk = _arbitraryBase.shrink(_cache as U, _distance!);
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

final class Action0<T extends State> extends Action<T, void> {
  Action0(
    String description,
    void Function(T) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(description, null_(), (s, _) => action(s));
}

final class Action2<T extends State, E1, E2> extends Action<T, (E1, E2)> {
  Action2(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    void Function(T, E1, E2) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(
          description,
          combine2(arbitrary1, arbitrary2, (a, b) => (a, b)),
          (s, args) => action(s, args.$1, args.$2),
        );
}

final class Action3<T extends State, E1, E2, E3>
    extends Action<T, (E1, E2, E3)> {
  Action3(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    void Function(T, E1, E2, E3) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(
          description,
          combine3(arbitrary1, arbitrary2, arbitrary3, (a, b, c) => (a, b, c)),
          (s, args) => action(s, args.$1, args.$2, args.$3),
        );
}

final class Action4<T extends State, E1, E2, E3, E4>
    extends Action<T, (E1, E2, E3, E4)> {
  Action4(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    void Function(T, E1, E2, E3, E4) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(
          description,
          combine4(arbitrary1, arbitrary2, arbitrary3, arbitrary4,
              (a, b, c, d) => (a, b, c, d)),
          (s, args) => action(s, args.$1, args.$2, args.$3, args.$4),
        );
}

final class Action5<T extends State, E1, E2, E3, E4, E5>
    extends Action<T, (E1, E2, E3, E4, E5)> {
  Action5(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    void Function(T, E1, E2, E3, E4, E5) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(
          description,
          combine5(arbitrary1, arbitrary2, arbitrary3, arbitrary4, arbitrary5,
              (a, b, c, d, e) => (a, b, c, d, e)),
          (s, args) => action(s, args.$1, args.$2, args.$3, args.$4, args.$5),
        );
}

final class Action6<T extends State, E1, E2, E3, E4, E5, E6>
    extends Action<T, (E1, E2, E3, E4, E5, E6)> {
  Action6(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    Arbitrary<E6> arbitrary6,
    void Function(T, E1, E2, E3, E4, E5, E6) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
  }) : super(
          description,
          combine6(arbitrary1, arbitrary2, arbitrary3, arbitrary4, arbitrary5,
              arbitrary6, (a, b, c, d, e, f) => (a, b, c, d, e, f)),
          (s, args) =>
              action(s, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6),
        );
}

final class Action7<T extends State, E1, E2, E3, E4, E5, E6, E7>
    extends Action<T, (E1, E2, E3, E4, E5, E6, E7)> {
  Action7(
    String description,
    Arbitrary<E1> arbitrary1,
    Arbitrary<E2> arbitrary2,
    Arbitrary<E3> arbitrary3,
    Arbitrary<E4> arbitrary4,
    Arbitrary<E5> arbitrary5,
    Arbitrary<E6> arbitrary6,
    Arbitrary<E7> arbitrary7,
    void Function(T, E1, E2, E3, E4, E5, E6, E7) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
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
          (s, args) => action(
              s, args.$1, args.$2, args.$3, args.$4, args.$5, args.$6, args.$7),
        );
}

final class Action8<T extends State, E1, E2, E3, E4, E5, E6, E7, E8>
    extends Action<T, (E1, E2, E3, E4, E5, E6, E7, E8)> {
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
    void Function(T, E1, E2, E3, E4, E5, E6, E7, E8) action, {
    super.precondition,
    super.postcondition,
    super.nextState,
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
          (s, args) => action(s, args.$1, args.$2, args.$3, args.$4, args.$5,
              args.$6, args.$7, args.$8),
        );
}
