import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/finalize.dart';
import 'package:kiri_check/src/state/command/initialize.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

// ランダムにコマンドを選択
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

  TraversalPath? currentPath = null;
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
      // 依存関係をチェック
      if (command.canExecute(context.state) &&
          command.dependencies.every(context.executed.containsKey)) {
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

  List<TraversalPath> shrink(int granularity) {
    if (granularity < 1) {
      throw PropertyException(
          'Granularity must be greater than or equal to 1.');
    }
    // TODO
    final shrunkPaths = <TraversalPath>[];
    final division = granularity + 1;
    var previousSteps = <TraversalStep>[];
    for (var i = 0; i < division; i++) {
      final shrunkSteps =
          steps.sublist(0, (steps.length ~/ division) * (i + 1));
      print('division $division, ${steps.length ~/ division} * ${(i + 1)}');
      print('shrunk steps: ${steps.length} -> ${shrunkSteps.length}');
      if (previousSteps.length == shrunkSteps.length &&
          const DeepCollectionEquality().equals(previousSteps, shrunkSteps)) {
        continue;
      }
      previousSteps = shrunkSteps;
      final shrunkPath = TraversalPath(traversal, shrunkSteps);
      shrunkPaths.add(shrunkPath);
    }

    return shrunkPaths;
  }
}
