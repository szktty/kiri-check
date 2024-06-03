import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/sequence.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

// ランダムにコマンドを選択
// TODO: パスの数は考慮しない。純粋にパスのみ生成する
// ステップも一度にすべて生成する
final class Traversal<State, System> {
  Traversal(
    this.context,
    this.commands,
  ) {
    for (final command in commands) {
      if (command is Initialize<State, System>) {
        initializeCommands.add(command);
      } else if (command is Finalize<State, System>) {
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

  List<Command<State, System>> _selectCommands(State state) {
    final selected = <Command<State, System>>[];
    final finalizers = <Command<State, System>>[];
    var tries = 0;

    bool hasNext() =>
        tries < context.property.maxCommandTries &&
        finalizers.length + selected.length < context.property.maxSteps;

    void addCommand(
        List<Command<State, System>> list, Command<State, System> command) {
      if (!hasNext()) {
        return;
      }

      if (command is Initialize<State, System>) {
        addCommand(list, command.command);
      } else if (command is Finalize<State, System>) {
        addCommand(list, command.command);
      } else if (command is Sequence<State, System>) {
        for (final c in command.commands) {
          addCommand(list, c);
        }
      } else if (command.requires(state)) {
        list.add(command);
        tries++;
      }
    }

    void addCommands(List<Command<State, System>> list,
        List<Command<State, System>> commands) {
      for (final command in commands) {
        if (!hasNext()) {
          break;
        }
        addCommand(list, command);
        tries++;
      }
    }

    addCommands(selected, initializeCommands);
    addCommands(finalizers, finalizeCommands);

    while (hasNext()) {
      final n = context.property.random.nextInt(actionCommands.length);
      addCommand(selected, actionCommands[n]);
      tries++;
    }

    selected.addAll(finalizers);
    return selected;
  }

  TraversalSequence<State, System> generateSequence(State state) {
    final commands = _selectCommands(state);
    final sequence = TraversalSequence<State, System>();
    for (final command in commands) {
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

  void truncateSteps(int index) {
    steps.removeRange(index, steps.length);
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
    final n = (steps.length / (steps.length <= 5 ? 2 : 3)).ceil();
    print('TraversalSequence.shrink: steps ${steps.length}, $n');
    return steps
        .splitAfterIndexed((i, _) => (i + 1) % n == 0)
        .map(TraversalSequence<State, System>.new)
        .toList();
  }
}
