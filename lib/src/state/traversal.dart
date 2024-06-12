import 'package:collection/collection.dart';
import 'package:kiri_check/src/state/command/command.dart';
import 'package:kiri_check/src/state/command/context.dart';
import 'package:kiri_check/src/state/command/sequence.dart';
import 'package:kiri_check/src/state/property.dart';

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

  List<CommandContext<State, System>> _generateCommands(State state) {
    final generated = <CommandContext<State, System>>[];
    final finalizers = <CommandContext<State, System>>[];
    var tries = 0;

    bool hasNext() =>
        tries < context.property.maxCommandTries &&
        finalizers.length + generated.length < context.property.maxSteps;

    void addCommand(
      List<CommandContext<State, System>> contexts,
      Command<State, System> command,
    ) {
      if (!hasNext()) {
        return;
      }

      if (command is Initialize<State, System>) {
        addCommand(contexts, command.command);
      } else if (command is Finalize<State, System>) {
        addCommand(contexts, command.command);
      } else if (command is Sequence<State, System>) {
        for (final c in command.commands) {
          addCommand(contexts, c);
        }
      } else {
        final commandContext =
            CommandContext(command, random: context.property.random)
              ..nextValue();
        if (commandContext.precondition(state)) {
          commandContext.nextState(state);
          contexts.add(commandContext);
          tries++;
        }
      }
    }

    void addCommands(
      List<CommandContext<State, System>> contexts,
      List<Command<State, System>> commands,
    ) {
      for (final command in commands) {
        if (!hasNext()) {
          break;
        }
        addCommand(contexts, command);
        tries++;
      }
    }

    addCommands(generated, initializeCommands);
    addCommands(finalizers, finalizeCommands);

    while (hasNext()) {
      final n = context.property.random.nextInt(actionCommands.length);
      addCommand(generated, actionCommands[n]);
      tries++;
    }

    generated.addAll(finalizers);
    return generated;
  }

  TraversalSequence<State, System> generateSequence(State state) {
    final contexts = _generateCommands(state);
    final sequence = TraversalSequence<State, System>();
    for (final context in contexts) {
      sequence.addStep(TraversalStep(context));
    }
    return sequence;
  }
}

final class TraversalStep<State, System> {
  TraversalStep(this.commandContext);

  final CommandContext<State, System> commandContext;

  Command<State, System> get command => commandContext.command;
}

final class TraversalSequence<State, System> {
  TraversalSequence([List<TraversalStep<State, System>> steps = const []]) {
    this.steps.addAll(steps);
  }

  final List<TraversalStep<State, System>> steps = [];

  void addStep(TraversalStep<State, System> step) {
    steps.add(step);
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
    return steps
        .splitAfterIndexed((i, _) => (i + 1) % n == 0)
        .map(TraversalSequence<State, System>.new)
        .toList();
  }
}
