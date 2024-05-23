import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/action.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';

final class StatefulFalsifiedException<T extends State> implements Exception {
  StatefulFalsifiedException(this.description, this.result);

  final Object? description;
  final StatefulShrinkingResult<T> result;
}

final class StateContext<T extends State> {
  StateContext(this.state, this.property, this.test);

  T state;
  final StatefulProperty<T> property;
  final PropertyTest test;

  Behavior<T> get behavior => property.behavior;

  void executeCommand(Command<T> command) {
    state = property._executeCommand(this, command);
  }
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
    _checkPaths(test);
    tearDown?.call();
  }

  void _checkPaths(PropertyTest test) {
    final propertyContext = StatefulPropertyContext(this, test);
    for (propertyContext.cycle = 0;
        propertyContext.cycle < maxCycles;
        propertyContext.cycle++) {
      for (var cycle = 0; cycle < maxCycles; cycle++) {
        print('--------------------------------------------');
        print('Cycle ${cycle + 1}');

        var state = behavior.createState()..random = random;
        print('Create state: ${state.runtimeType}');
        final stateContext = StateContext(state, this, test);
        final commands = behavior.generateCommands(state);
        final traversal = Traversal(propertyContext, commands);
        final path = traversal.generatePath();

        state.setUp();

        for (var i = 0; i < path.steps.length; i++) {
          final step = path.steps[i];
          final command = step.command;
          print('Step ${i + 1}: ${command.description}');
          try {
            stateContext.executeCommand(command);
          } catch (e) {
            print('Error: $e');
            state.tearDown();

            // TODO: 次に一部のコマンドをカットするフェーズを挟む

            final shrinker = _StatefulPropertyShrinker(
              propertyContext,
              stateContext,
              TraversalPath(path.steps.sublist(0, i + 1)),
            );
            final result = shrinker.shrink();

            print('Falsified example path:');
            for (var i = 0; i < result.path.steps.length; i++) {
              final step = result.path.steps[i];
              final command = step.command;
              print('Step ${i + 1}: ${command.description}');
              if (command is Action) {
                print('Shrunk value: ${command.falsifyingExample}');
              }
            }

            throw StatefulFalsifiedException(test.description, result);
          }
        }

        body(state);
        state.tearDown();
      }

      print('--------------------------------------------');
    }
  }

  T _executeCommand(
    StateContext<T> context,
    Command<T> command,
  ) {
    final state = context.state;
    if (command.requires(state)) {
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
}

final class _StatefulPropertyShrinker<T extends State> {
  _StatefulPropertyShrinker(
    this.propertyContext,
    this.stateContext,
    this.originalPath,
  );

  final StatefulPropertyContext<T> propertyContext;
  final StateContext<T> stateContext;
  final TraversalPath<T> originalPath;

  StatefulProperty<T> get property => propertyContext.property;

  StatefulShrinkingResult<T> shrink() {
    final subpath = _checkSubpaths();
    // TODO: 一部のパスをカットしてチェック

    _checkValues(subpath);
    return StatefulShrinkingResult(stateContext.state, subpath);
  }

  int get _shrinkCycle => propertyContext.shrinkCycle;

  bool get _hasShrinkCycle =>
      _shrinkCycle < propertyContext.property.maxShrinkingCycles;

  TraversalPath<T> _checkSubpaths() {
    propertyContext.shrinkCycle = 0;
    var previousPaths = <TraversalPath<T>>[];
    var minShrunkPath = originalPath;
    while (_hasShrinkCycle) {
      final granularity = _shrinkCycle + 1;
      final shrunkPaths = minShrunkPath.shrink(granularity);
      if (TraversalPath.equals(previousPaths, shrunkPaths)) {
        break;
      }
      previousPaths = shrunkPaths;

      for (final shrunkPath in shrunkPaths) {
        print('Shrink cycle ${_shrinkCycle + 1}');
        if (!_checkShrunkPath(shrunkPath)) {
          // 最も短い操作列を最小とする
          if (shrunkPath.steps.length < minShrunkPath.steps.length) {
            minShrunkPath = shrunkPath;
          }
        }
        propertyContext.shrinkCycle++;
        if (!_hasShrinkCycle) {
          break;
        }
      }
    }
    return minShrunkPath;
  }

  bool _checkShrunkPath(TraversalPath<T> path) {
    print('Check shrunk path: ${path.steps.length} steps');
    final state = propertyContext.behavior.createState()
      ..random = property.random;
    final stateContext = StateContext(state, property, propertyContext.test);
    for (var i = 0; i < path.steps.length; i++) {
      final step = path.steps[i];
      final command = step.command;
      print('Shrink step ${i + 1}: ${command.description}');
      try {
        command.useCache = true;
        stateContext.executeCommand(command);
      } catch (e) {
        print('Error: $e');
        return false;
      }
    }
    return true;
  }

  void _checkValues(TraversalPath<T> path) {
    var allShrinkDone = false;
    while (_hasShrinkCycle && !allShrinkDone) {
      print('Shrink cycle ${_shrinkCycle + 1}');
      final state = propertyContext.behavior.createState()
        ..random = property.random;
      final stateContext = StateContext(state, property, propertyContext.test);
      allShrinkDone = true;
      for (var i = 0; i < path.steps.length; i++) {
        final step = path.steps[i];
        final command = step.command;
        print('Shrink step ${i + 1}: ${command.description}');
        try {
          // サイクル制限に達するか、すべてのコマンドのシュリンクが終了するまで繰り返す
          if (command.nextShrink()) {
            allShrinkDone = false;
          }
          stateContext.executeCommand(command);
        } catch (e) {
          print('Error: $e');
          command.failShrunk();
        }
      }
      propertyContext.shrinkCycle++;
    }
  }
}

final class StatefulShrinkingResult<T extends State> {
  StatefulShrinkingResult(this.state, this.path);

  final T state;
  final TraversalPath<T> path;
}
