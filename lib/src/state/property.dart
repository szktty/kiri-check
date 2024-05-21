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

      final traversal = Traversal(stateContext, commands);
      // TODO
      dynamic shrinkResult = null;
      var currentSteps = <TraversalStep<T>>[];
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
          currentSteps.add(TraversalStep(traversal.currentStep, command));
          traversal.currentStep++;
          print('Step ${traversal.currentStep}: ${command.description}');
          state = _executeCommand(stateContext, command, random);
          stateContext.state = state;
        }
      } catch (e) {
        // TODO: shrink
        print('Error: $e');
        final shrinker = _StatefulPropertyShrinker(
          propertyContext,
          stateContext,
          TraversalPath(traversal, currentSteps),
        );
        // TODO: result
        shrinker.shrink();
      }

      print('--------------------------------------------');

      if (shrinkResult != null) {
        print('Shrink result');
        tearDown?.call();
        throw PropertyException('Shrink failed: $shrinkResult');
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

  void shrink() {
    // TODO
    _shrinkPaths();
  }

  int get _shrinkCycle => propertyContext.shrinkCycle;

  bool get _hasShrinkCycle =>
      _shrinkCycle < propertyContext.property.maxShrinkingCycles;

  TraversalPath<T> _shrinkPaths() {
    propertyContext.shrinkCycle = 0;
    var basePath = originalPath;
    var previousPaths = <TraversalPath<T>>[];
    while (_hasShrinkCycle) {
      final granularity = _shrinkCycle + 1;
      final paths = basePath.shrink(granularity);
      if (TraversalPath.equals(previousPaths, paths)) {
        break;
      }
      previousPaths = paths;

      for (final path in paths) {
        print('Shrink cycle ${_shrinkCycle + 1}');
        if (_checkPath(path)) {
          break;
        } else {
          basePath = path;
          propertyContext.shrinkCycle++;
          if (!_hasShrinkCycle) {
            break;
          }
        }
      }
    }
    return basePath;
  }

  bool _checkPath(TraversalPath<T> path) {
    print('Check path: ${path.steps.length} steps');
    return true;
  }

  /*
  TraversalPath _shrinkPath(
    StatefulPropertyContext<T> propertyContext,
    StateContext<T> stateContext,
    TraversalPath originalPath,
  ) {
    var basePath = originalPath;
    var failed = originalPath;
    propertyContext.shrinkCycle = 0;
    while (propertyContext.shrinkCycle < maxShrinkingCycles) {
      print('--------------------------------------------');
      final paths = basePath.shrink(propertyContext.shrinkCycle);
      if (TraversalPath.equals(paths, basePath)) {
        return failed;
      }

      for (final path in paths) {
        print('Shrink cycle ${propertyContext.shrinkCycle + 1}');
        for (var i = 0; i < path.steps.length; i++) {
          final step = path.steps[i];
          final command = step.command;
          print('Shrink step ${i + 1}: ${command.description}');
          try {
            if (command.requires(stateContext.state)) {
              command.execute(stateContext.state);
              if (command.ensures(stateContext.state)) {
                // 成功
                basePath = path;
                break;
              } else {
                print('Postcondition is not satisfied');
                throw PropertyException('postcondition is not satisfied');
              }
            } else {
              print('Precondition is not satisfied');
              throw PropertyException('precondition is not satisfied');
            }
          } catch (e) {
            print('Error: $e');
            failed = path;
          }
        }
        propertyContext.shrinkCycle++;
      }
    }
    return failed;
  }

   */

  void _shrinkValue(TraversalPath path) {
    // TODO
    print('Shrink bundles...');
  }
}
