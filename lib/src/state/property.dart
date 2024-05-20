import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';

final class StateContext<T extends State> {
  StateContext(this.state, this.property, this.test);

  T state;
  final StatefulProperty<T> property;
  final PropertyTest test;
  late CommandDependencyGraph<T> dependencyGraph;
  final Map<Command<T>, int> executed = {};

  Behavior<T> get behavior => property.behavior;
}

final class StatefulPropertyContext<T extends State> {
  StatefulPropertyContext(this.property, this.test);

  final StatefulProperty<T> property;
  final PropertyTest test;
  int cycle = 0;
  int step = 0;
  int shrinkCycle = 0;

  bool get hasNextCycle => cycle < property.maxCycles;

  bool get hasNextShrinkCycle => shrinkCycle < property.maxShrinkingCycles;

  Behavior<T> get behavior => property.behavior;
}

final class StatefulProperty<T extends State> extends Property<T> {
  StatefulProperty(
    this.behavior,
    this.body, {
    required super.settings,
    super.setUp,
    super.tearDown,
    this.onCheck,
  }) {
    maxCycles = settings.maxStatefulCycles ?? KiriCheck.maxStatefulCycles;
    /*
    maxShrinkingCycles =
        settings.maxShrinkingCycles ?? KiriCheck.maxShrinkingCycles;

     */
    maxShrinkingCycles = 50;
  }

  final Behavior<T> behavior;

  final void Function(T) body;
  final void Function(void Function())? onCheck;

  late final int maxCycles;
  late final int maxShrinkingCycles;

  @override
  void check(PropertyTest test) {
    if (onCheck != null) {
      var called = false;
      onCheck!(() {
        if (called) {
          throw PropertyException('onCheck is called more than once');
        } else {
          called = true;
          _check(test);
        }
      });
      if (!called) {
        throw PropertyException('onCheck is not called');
      }
    } else {
      _check(test);
    }
  }

  void _check(PropertyTest test) {
    print('Check behavior: ${behavior.runtimeType}');
    setUp?.call();

    final propertyContext = StatefulPropertyContext(this, test);
    for (propertyContext.cycle = 0;
        propertyContext.cycle < maxCycles;
        propertyContext.cycle++) {
      var state = behavior.createState()..random = random;
      print('Create state: ${state.runtimeType}');
      final commands = behavior.generateCommands(state);
      final stateContext = StateContext(state, this, test);

      print('Check command dependency...');
      stateContext.dependencyGraph = CommandDependencyGraph(commands);

      final traversal = Traversal(stateContext, commands);
      TraversalPath? shrunkPath;
      try {
        traversal.nextPath();
        print('--------------------------------------------');
        print('Cycle ${propertyContext.cycle + 1}');
        state.setUp();
        while (traversal.hasNextStep) {
          final command = traversal.nextStep();
          if (command == null) {
            print('skip');
            break;
          }
          traversal.currentStep++;
          print('Step ${traversal.currentStep}: ${command.description}');
          state = _executeCommand(stateContext, command, random);
          stateContext.state = state;
        }
      } catch (e) {
        // TODO: shrink
        print('Error: $e');
        // FIXME: 無限ループになる
        // shrunkPath = _shrinkPath(propertyContext, stateContext, traversal);
      }

      print('--------------------------------------------');

      if (shrunkPath != null) {
        print('Shrink result');
        tearDown?.call();
        throw PropertyException('Shrink failed: $shrunkPath');
      }

      body(state);
      state.tearDown();
    }

    tearDown?.call();
  }

  T _executeCommand(
    StateContext<T> context,
    Command<T> command,
    RandomContext random,
  ) {
    final state = context.state;
    if (command.requires(state)) {
      _markAsExecuted(context, command);
      command.execute(state);
      if (command.ensures(state)) {
        final next = command.nextState(state);
        if (next != null) {
          return next..random = random;
        } else {
          return state;
        }
      } else {
        print('Postcondition is not satisfied');
        throw PropertyException('postcondition is not satisfied');
      }
    } else {
      print('Precondition is not satisfied');
      throw PropertyException('precondition is not satisfied');
    }
  }

  void _markAsExecuted(StateContext<T> context, Command<T> command) {
    context.executed[command] ??= (context.executed[command] ?? 0) + 1;
    for (final sub in command.subcommands) {
      _markAsExecuted(context, sub);
    }
  }

  // 1. パスを短縮する
  // 2. バンドルの値を短縮する
  TraversalPath _shrinkPath(
    StatefulPropertyContext<T> propertyContext,
    StateContext<T> stateContext,
    Traversal traversal,
  ) {
    // TODO
    final start = traversal.currentPath!;
    var granularity = 1;
    var failed = start;
    propertyContext.shrinkCycle = 0;
    while (propertyContext.shrinkCycle < maxShrinkingCycles) {
      print('--------------------------------------------');
      final paths = start.shrink(granularity);
      for (final path in paths) {
        print('Shrink cycle ${propertyContext.shrinkCycle + 1}');
        for (var i = 0; i < path.steps.length; i++) {
          // TODO: 最後にエラーになったパスの短縮の繰り返し
          final step = path.steps[i];
          final command = step.command;
          print('Shrink step ${i + 1}: ${command.description}');
          try {
            command
              ..requires(stateContext.state)
              ..execute(stateContext.state)
              ..ensures(stateContext.state);
          } catch (e) {
            print('Error: $e');
            failed = path;
            continue;
          }
          // passのシュリンク終了
          _shrinkValue(path);
          return failed;
        }
        propertyContext.shrinkCycle++;
      }
    }
    return failed;
  }

  void _shrinkValue(TraversalPath path) {
    // TODO
    print('Shrink bundles...');
  }
}

final class CommandDependencyException extends PropertyException {
  CommandDependencyException(super.message);
}

// TODO
final class CommandDependencyGraph<T extends State> {
  // TODO: 解析し、循環があればエラー
  CommandDependencyGraph(this.commands) {
    _analyze();
    _checkCircularDependency();
  }

  final List<Command<T>> commands;
  final Map<Command<T>, CommandDependency<T>> dependencies = {};

  void _analyze() {
    for (final command in commands) {
      final dependencies = <Command<T>>[];
      for (final dep in command.dependencies) {
        if (commands.contains(dep)) {
          dependencies.add(dep);
        } else {
          throw CommandDependencyException(
              'Unknown dependency: ${dep.description}');
        }
      }
      this.dependencies[command] = CommandDependency(command, dependencies);
    }
  }

  void _checkCircularDependency() {
    final visited = <Command<T>>{};
    final recStack = <Command<T>>{};

    bool dfs(Command<T> command) {
      if (!visited.contains(command)) {
        // Mark the current node as visited and part of the recursion stack
        visited.add(command);
        recStack.add(command);

        // Recur for all the vertices adjacent to this vertex
        final commandDependencies = dependencies[command]?.dependencies ?? [];
        for (final dep in commandDependencies) {
          if (!visited.contains(dep) && dfs(dep)) {
            return true;
          } else if (recStack.contains(dep)) {
            return true;
          }
        }
      }
      // Remove the vertex from recursion stack
      recStack.remove(command);
      return false;
    }

    for (final command in commands) {
      if (dfs(command)) {
        throw CommandDependencyException(
            'Cycle detected in command dependencies: ${command.description}');
      }
    }
  }
}

final class CommandDependency<T extends State> {
  CommandDependency(this.command, this.dependencies);

  final Command<T> command;
  final List<Command<T>> dependencies;
}
