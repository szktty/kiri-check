import 'package:collection/collection.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/sequence.dart';
import 'package:kiri_check/src/state/property.dart';

final class Traversal<State, System, R> {
  Traversal(
    this.context,
    this.commands,
  ) {
    for (final command in commands) {
      if (command is Initialize<State, System, R>) {
        initializeCommands.add(command);
      } else if (command is Finalize<State, System, R>) {
        finalizeCommands.add(command);
      } else {
        actionCommands.add(command);
      }
    }
  }

  final StatefulPropertyContext<State, System, R> context;
  final List<Command<State, System, R>> commands;
  final List<Command<State, System, R>> initializeCommands = [];
  final List<Command<State, System, R>> finalizeCommands = [];
  final List<Command<State, System, R>> actionCommands = [];

  List<Command<State, System, R>> _selectCommands(State state) {
    final selected = <Command<State, System, R>>[];
    final finalizers = <Command<State, System, R>>[];
    var tries = 0;

    bool hasNext() =>
        tries < context.property.maxCommandTries &&
        finalizers.length + selected.length < context.property.maxSteps;

    void addCommand(
      List<Command<State, System, R>> list,
      Command<State, System, R> command,
    ) {
      if (!hasNext()) {
        return;
      }

      if (command is Initialize<State, System, R>) {
        addCommand(list, command.command);
      } else if (command is Finalize<State, System, R>) {
        addCommand(list, command.command);
      } else if (command is Sequence<State, System, R>) {
        for (final c in command.commands) {
          addCommand(list, c);
        }
      } else if (command.requires(state)) {
        // TODO: update state
        // postcondnitionはチェックしない
        list.add(command);
        tries++;
      }
    }

    void addCommands(
      List<Command<State, System, R>> list,
      List<Command<State, System, R>> commands,
    ) {
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

  TraversalSequence<State, System, R> generateSequence(State state) {
    final commands = _selectCommands(state);
    final sequence = TraversalSequence<State, System, R>();
    for (final command in commands) {
      sequence.addStep(TraversalStep(command));
    }
    return sequence;
  }
}

final class TraversalStep<State, System, R> {
  TraversalStep(Command<State, System, R> command) {
    context = command.createContext();
  }

  late final CommandContext<State, System, R> context;
}

final class TraversalSequence<State, System, R> {
  TraversalSequence([List<TraversalStep<State, System, R>> steps = const []]) {
    this.steps.addAll(steps);
  }

  final List<TraversalStep<State, System, R>> steps = [];

  void addStep(TraversalStep<State, System, R> step) {
    steps.add(step);
  }

  void truncateSteps(int index) {
    steps.removeRange(index, steps.length);
  }

  static bool equals<State, System, R>(
    List<TraversalSequence<State, System, R>> a,
    List<TraversalSequence<State, System, R>> b,
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

  List<TraversalSequence<State, System, R>> shrink() {
    final n = (steps.length / (steps.length <= 5 ? 2 : 3)).ceil();
    return steps
        .splitAfterIndexed((i, _) => (i + 1) % n == 0)
        .map(TraversalSequence<State, System, R>.new)
        .toList();
  }
}
