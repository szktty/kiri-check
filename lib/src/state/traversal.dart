import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/finalize.dart';
import 'package:kiri_check/src/state/command/initialize.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

// ランダムにコマンドを選択
// TODO: パスの数は考慮しない。純粋にパスのみ生成する
// ステップも一度にすべて生成する
final class Traversal<State, System> {
  Traversal(
    this.context,
    this.commands, {
    this.maxSteps = 30,
  }) {
    for (final command in commands) {
      if (command is Initialize) {
        initializeCommands.add(command);
      } else if (command is Finalize) {
        finalizeCommands.add(command);
      } else {
        actionCommands.add(command);
      }
    }
  }

  final StatefulPropertyContext<State, System> context;
  final List<Command<State, System>> commands;
  final List<Command<State, System>> initializeCommands = [];
  final List<Command<State, System>> finalizeCommands = [];
  final List<Command<State, System>> actionCommands = [];
  final int maxSteps;

  TraversalSequence<State, System> generateSequence() {
    final sequence = TraversalSequence<State, System>();
    for (final command in initializeCommands) {
      sequence.addStep(command);
    }
    final count = context.property.random.nextIntInclusive(
      maxSteps - initializeCommands.length - finalizeCommands.length,
    );
    for (var i = 0; i < count; i++) {
      final n = context.property.random.nextInt(actionCommands.length);
      final command = actionCommands[n];
      sequence.addStep(command);
    }
    for (final command in finalizeCommands) {
      sequence.addStep(command);
    }
    return sequence;
  }
}

final class TraversalStep<State, System> {
  TraversalStep(this.number, this.command);

  final int number;
  final Command<State, System> command;
}

final class TraversalSequence<State, System> {
  TraversalSequence([List<TraversalStep<State, System>> steps = const []]) {
    this.steps.addAll(steps);
  }

  final List<TraversalStep<State, System>> steps = [];

  void addStep(Command<State, System> command) {
    steps.add(TraversalStep(steps.length, command));
  }

  static bool equals<State, System>(
    List<TraversalSequence<State, System>> a,
    List<TraversalSequence<State, System>> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!const DeepCollectionEquality().equals(a[i].steps, b[i].steps)) {
        return false;
      }
    }
    return true;
  }

  List<TraversalSequence<State, System>> shrink() {
    print('TraversalSequence.shrink: steps ${steps.length}');
    final n = steps.length ~/ (steps.length <= 5 ? 2 : 3);
    return steps
        .splitAfterIndexed((i, _) => i > 0 && i % n == 0)
        .map(TraversalSequence<State, System>.new)
        .toList();
  }
}
