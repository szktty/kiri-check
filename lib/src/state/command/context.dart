import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/property/arbitrary.dart';
import 'package:kiri_check/src/property/property_internal.dart';
import 'package:kiri_check/src/state/command/action.dart';
import 'package:kiri_check/src/state/command/command.dart';

enum CommandShrinkingState {
  notStarted,
  running,
  finished,
}

final class CommandContext<State, System> {
  CommandContext(
    this.command, {
    required this.random,
    Arbitrary<dynamic>? arbitrary,
  }) {
    if (command is Action && arbitrary == null) {
      this.arbitrary = (command as Action).arbitrary;
    } else {
      this.arbitrary = arbitrary;
    }
    _shrunkQueue = null;
  }

  final Command<State, System> command;
  final RandomContext random;
  late final Arbitrary<dynamic>? arbitrary;

  ArbitraryBase<dynamic>? get _arbitraryBase =>
      arbitrary as ArbitraryBase<dynamic>?;

  bool useCache = false;

  CommandShrinkingState _shrinkState = CommandShrinkingState.notStarted;
  int _shrinkGranularity = 1;
  List<dynamic>? _previousShrunk;
  Queue<ValueWithState<dynamic>>? _shrunkQueue;
  ValueWithState<dynamic>? _minShrunk;
  ValueWithState<dynamic>? _current;

  dynamic get currentValue => _current?.value;

  dynamic get minValue => _minShrunk?.value;

  void nextValue() {
    if (_shrinkState == CommandShrinkingState.running) {
      if (_shrunkQueue!.isNotEmpty) {
        _current = _shrunkQueue!.removeFirst();
        // Restore the random state to the exact point when this value was generated
        final randomImpl = random as RandomContextImpl;
        final stateToRestore = _current!.state as RandomStateXorshift;
        randomImpl.xorshift.state =
            RandomStateXorshift.fromState(stateToRestore);
      }
    } else if (!useCache) {
      _current = _arbitraryBase?.generateWithState(random);
    }
  }

  Future<void> nextState(State state) async {
    await command.nextState(this, state);
  }

  Future<dynamic> run(System system) {
    return command.run(this, system);
  }

  Future<bool> precondition(State state) {
    return command.precondition(this, state);
  }

  Future<bool> postcondition(State state, dynamic result) {
    return command.postcondition(this, state, result);
  }

  bool tryShrink() {
    if (arbitrary == null || _current == null) {
      return false;
    }

    switch (_shrinkState) {
      case CommandShrinkingState.notStarted:
        _shrinkState = CommandShrinkingState.running;
        _minShrunk ??= _current;
        return _refillShrunkQueue();
      case CommandShrinkingState.running:
        if (_shrunkQueue!.isNotEmpty) {
          return true;
        } else {
          _shrinkGranularity++;
          return _refillShrunkQueue();
        }
      case CommandShrinkingState.finished:
        return false;
    }
  }

  // Cuts the next candidates from the smallest failing value, never from a
  // candidate that passed.
  bool _refillShrunkQueue() {
    final minShrunk = _minShrunk!;
    final distance = _arbitraryBase!.calculateDistance(minShrunk.value)
      ..granularity = _shrinkGranularity;
    final shrunk = distance.isEmpty
        ? <dynamic>[]
        : _arbitraryBase!.shrink(minShrunk.value, distance);
    if (shrunk.isEmpty ||
        const DeepCollectionEquality().equals(shrunk, _previousShrunk)) {
      _shrinkState = CommandShrinkingState.finished;
      return false;
    }
    _previousShrunk = shrunk;
    // Create ValueWithState instances for each shrunk value using the original state
    _shrunkQueue = Queue.of(
      shrunk.map((value) => ValueWithState<dynamic>(value, minShrunk.state)),
    );
    return true;
  }

  void failShrink() {
    _minShrunk = _current;
  }

  /// Holds the smallest failing value, or the current value if no failing
  /// value has been recorded.
  void holdMin() {
    _minShrunk ??= _current;
    _current = _minShrunk;
  }

  /// Starts shrinking again from the smallest failing value.
  void restartShrink() {
    holdMin();
    _shrinkState = CommandShrinkingState.notStarted;
    _shrinkGranularity = 1;
    _previousShrunk = null;
    _shrunkQueue = null;
  }
}
