import 'dart:collection';

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
    this.maxSteps = 10,
    this.maxPaths = 100,
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
    _initializeCommandQueue = Queue.of(initializeCommands);
    _finalizeCommandQueue = Queue.of(finalizeCommands);
  }

  final StateContext<T> context;
  final List<Command<T>> commands;
  final List<Command<T>> initializeCommands = [];
  final List<Command<T>> finalizeCommands = [];
  final List<Command<T>> actionCommands = [];
  final int maxSteps;
  final int maxPaths;

  final List<TraversalPath> paths = [];

  late final Queue<Command<T>> _initializeCommandQueue;
  late final Queue<Command<T>> _finalizeCommandQueue;

  TraversalPath? currentPath;
  int currentCycle = -1;
  int currentStep = 0;

  bool get hasNextPath => paths.length < maxPaths;

  bool get hasNextStep => currentPath != null && currentStep < maxSteps;

  void nextPath() {
    if (!hasNextPath) {
      throw PropertyException('No more paths.');
    }

    currentPath = TraversalPath(this, []);
    paths.add(currentPath!);

    currentCycle++;
    currentStep = 0;
  }

  // ランダムにコマンドを選択
  Command<T>? nextStep() {
    if (!hasNextStep) {
      throw PropertyException('No more steps.');
    }

    if (_initializeCommandQueue.isNotEmpty) {
      return _initializeCommandQueue.removeFirst();
    } else if (currentStep + finalizeCommands.length >= maxSteps) {
      return _finalizeCommandQueue.removeFirst();
    }

    for (var tries = 0; tries < 10; tries++) {
      final n = context.property.random.nextInt(actionCommands.length);
      final command = actionCommands[n];
      if (command.canExecute(context.state)) {
        return command;
      }
    }
    return null;
  }
}

final class TraversalStep<T extends State> {
  TraversalStep(this.number, this.command);

  final int number;
  final Command<T> command;
}

final class TraversalPath<T extends State> {
  TraversalPath(this.traversal, this.steps);

  final Traversal traversal;
  final List<TraversalStep<T>> steps;

  static bool equals<T extends State>(
    List<TraversalPath<T>> a,
    List<TraversalPath<T>> b,
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

  List<TraversalPath<T>> shrink(int granularity) {
    if (granularity < 1) {
      throw PropertyException(
          'Granularity must be greater than or equal to 1.');
    }
    print('TraversalPath.shrink: steps ${steps.length}');
    return ArbitraryUtils.shrinkLength(
      steps.length,
      minLength: 1,
      granularity: granularity,
    ).map((e) {
      if (e > steps.length) {
        return TraversalPath<T>(traversal, []);
      } else {
        final shrunkSteps = steps.sublist(0, e);
        return TraversalPath(traversal, shrunkSteps);
      }
    }).toList();
  }
}
