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

  TraversalPath<T> generatePath() {
    final path = TraversalPath<T>();
    for (final command in commands) {
      path.addStep(command);
    }
    for (var tries = 0; tries < maxSteps; tries++) {
      final n = context.property.random.nextInt(actionCommands.length);
      final command = actionCommands[n];
      path.addStep(command);
    }
    return path;
  }
}

final class TraversalStep<T extends State> {
  TraversalStep(this.number, this.command);

  final int number;
  final Command<T> command;
}

final class TraversalPath<T extends State> {
  TraversalPath([List<TraversalStep<T>> steps = const []]) {
    this.steps.addAll(steps);
  }

  final List<TraversalStep<T>> steps = [];

  void addStep(Command<T> command) {
    steps.add(TraversalStep(steps.length, command));
  }

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
    final range = ArbitraryUtils.shrinkLength(
      steps.length,
      minLength: 0,
      granularity: granularity,
    );
    var start = 0;
    final paths = <TraversalPath<T>>[];
    for (final length in range) {
      final end = start + length;
      final substeps = steps.sublist(start, end);
      if (substeps.isNotEmpty) {
        final path = TraversalPath(substeps);
        paths.add(path);
      }
      start = end;
    }
    return paths;
  }
}
