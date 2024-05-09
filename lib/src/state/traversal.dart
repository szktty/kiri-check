import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';

// ランダムにコマンドを選択
final class Traversal<T extends State> {
  Traversal(
    this.context,
    this.commands, {
    this.maxSteps = 10,
    this.maxPaths = 100,
  });

  final StateContextImpl<T> context;
  final List<Command> commands;
  final int maxSteps;
  final int maxPaths;

  final List<TraversalPath> paths = [];

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
  Command nextStep() {
    if (!hasNextStep) {
      throw PropertyException('No more steps.');
    }

    // TODO: 重みづけ
    final n = context.property.random.nextInt(commands.length);
    final command = commands[n];
    currentPath!.steps.add(TraversalStep(currentStep, command));
    currentStep++;
    return command;
  }
}

final class TraversalStep {
  TraversalStep(this.number, this.command);

  final int number;
  final Command command;
}

final class TraversalPath {
  TraversalPath(this.traversal, this.steps);

  final Traversal traversal;
  final List<TraversalStep> steps;
}
