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
final class Traversal<T extends State> {
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

  final StatefulPropertyContext<T> context;
  final List<Command<T>> commands;
  final List<Command<T>> initializeCommands = [];
  final List<Command<T>> finalizeCommands = [];
  final List<Command<T>> actionCommands = [];
  final int maxSteps;

  TraversalSequence<T> generateSequence() {
    final sequence = TraversalSequence<T>();
    for (final command in initializeCommands) {
      sequence.addStep(command);
    }
    final count = context.property.random.nextIntInclusive(maxSteps);
    for (var i = 0; i < count; i++) {
      final n = context.property.random.nextInt(actionCommands.length);
      final command = actionCommands[n];
      sequence.addStep(command);
    }
    return sequence;
  }
}

final class TraversalStep<T extends State> {
  TraversalStep(this.number, this.command);

  final int number;
  final Command<T> command;
}

final class TraversalSequence<T extends State> {
  TraversalSequence([List<TraversalStep<T>> steps = const []]) {
    this.steps.addAll(steps);
  }

  final List<TraversalStep<T>> steps = [];

  void addStep(Command<T> command) {
    steps.add(TraversalStep(steps.length, command));
  }

  static bool equals<T extends State>(
    List<TraversalSequence<T>> a,
    List<TraversalSequence<T>> b,
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

  List<TraversalSequence<T>> shrink() {
    print('TraversalSequence.shrink: steps ${steps.length}');
    final n = steps.length ~/ (steps.length <= 5 ? 2 : 3);
    return steps
        .splitAfterIndexed((i, _) => i > 0 && i % n == 0)
        .map(TraversalSequence<T>.new)
        .toList();
  }
}
