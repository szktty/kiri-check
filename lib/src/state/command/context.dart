import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/random.dart';
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
    _distance = null;
    _shrunkQueue = null;
  }

  final Command<State, System> command;
  final RandomContext random;
  late final Arbitrary<dynamic>? arbitrary;

  ArbitraryBase<dynamic>? get _arbitraryBase =>
      arbitrary as ArbitraryBase<dynamic>?;

  bool useCache = false;

  CommandShrinkingState _shrinkState = CommandShrinkingState.notStarted;
  ShrinkingDistance? _distance;
  int _shrinkGranularity = 1;
  List<dynamic>? _previousShrunk;
  Queue<dynamic>? _shrunkQueue;
  dynamic _minShrunk;
  dynamic _current;

  dynamic get currentValue => _current;

  dynamic get minValue => _minShrunk;

  void nextValue() {
    if (_shrinkState == CommandShrinkingState.running) {
      if (_shrunkQueue!.isNotEmpty) {
        _current = _shrunkQueue!.removeFirst();
      }
    } else if (!useCache) {
      _current = _arbitraryBase?.generate(random);
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
    if (arbitrary == null) {
      return false;
    }

    switch (_shrinkState) {
      case CommandShrinkingState.notStarted:
        _shrinkState = CommandShrinkingState.running;
        _distance = _arbitraryBase!.calculateDistance(_current)
          ..granularity = _shrinkGranularity;
        final shrunk = _arbitraryBase!.shrink(_current, _distance!);
        _previousShrunk = shrunk;
        _shrunkQueue = Queue.of(shrunk);
        _minShrunk = _current;
        return true;
      case CommandShrinkingState.running:
        if (_shrunkQueue!.isNotEmpty) {
          return true;
        } else {
          _shrinkGranularity++;
          _distance!.granularity = _shrinkGranularity;
          final shrunk = _arbitraryBase!.shrink(_current, _distance!);
          if (const DeepCollectionEquality().equals(shrunk, _previousShrunk)) {
            _shrinkState = CommandShrinkingState.finished;
            return false;
          } else {
            _previousShrunk = shrunk;
            _shrunkQueue = Queue.of(shrunk);
            return true;
          }
        }
      case CommandShrinkingState.finished:
        return false;
    }
  }

  void failShrink() {
    _minShrunk = _current;
  }
}
