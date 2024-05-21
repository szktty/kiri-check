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
            state = _executeCommand(stateContext, command, random);
            stateContext.state = state;
          } catch (e) {
            print('Error: $e');
            state.tearDown();
            final shrinker = _StatefulPropertyShrinker(
              propertyContext,
              stateContext,
              TraversalPath(path.steps.sublist(0, i + 1)),
            );
            // TODO: result
            shrinker.shrink();
            throw PropertyException('Shrink failed');
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
    // TODO: 最小のステップ数を見つける
    // TODO: 単純に末尾以前をカットしても意味がない。すべて成功するから
    /*
    List<TraversalPath<T>>? minShrunkPath;
    for (var granularity = 1; granularity < 10; granularity++) {
      final shrunkPaths = path.shrink(granularity);
      if (_checkShrinkedPath(shrinkedPath)) {
        return true;
      }
    }
     */
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
