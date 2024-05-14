import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';

final class StateContext<T extends State> {
  StateContext(this.state, this.property, this.test);

  final T state;
  final StatefulProperty<T> property;
  final PropertyTest test;

  Behavior<T> get behavior => property.behavior;
}

final class StatefulProperty<T extends State> extends Property<T> {
  StatefulProperty(
    this.behavior, {
    required super.settings,
    super.setUp,
    super.tearDown,
  }) {
    maxCycles = settings.maxStatefulCycles ?? KiriCheck.maxStatefulCycles;
    /*
    maxShrinkingCycles =
        settings.maxShrinkingCycles ?? KiriCheck.maxShrinkingCycles;

     */
    maxShrinkingCycles = 50;
  }

  final Behavior<T> behavior;

  late final int maxCycles;
  late final int maxShrinkingCycles;

  @override
  void check(PropertyTest test) {
    print('Check behavior: ${behavior.runtimeType}');

    for (var i = 0; i < maxShrinkingCycles; i++) {
      var state = behavior.createState()..random = random;
      print('Create state: ${state.runtimeType}');
      final commands = behavior.generateCommands(state);
      final context = StateContext(state, this, test);
      print('Run command sequence...');
      final traversal = Traversal(context, commands);
      TraversalPath? shrunkPath;
      try {
        traversal.nextPath();
        print('--------------------------------------------');
        print('Cycle #${i + 1}');
        print('Set up...');
        (setUp ?? state.setUp).call();
        while (traversal.hasNextStep) {
          final command = traversal.nextStep();
          final i = traversal.currentStep + 1;
          if (command.precondition?.call(state) ?? true) {
            print('Step $i: ${command.description}');
            command.run(state);
            if (command.postcondition?.call(state) ?? true) {
              state = command.nextState?.call(state) ?? state;
            } else {
              print('Postcondition is not satisfied');
              throw PropertyException('postcondition is not satisfied');
            }
          }
        }
      } catch (e) {
        // TODO: shrink
        print('Error: $e');
        shrunkPath = _shrinkPath(context, traversal);
      }

      print('Tear down...');
      (tearDown ?? state.tearDown).call();
      print('--------------------------------------------');

      if (shrunkPath != null) {
        print('Shrink result');
        throw PropertyException('Shrink failed: $shrunkPath');
      }
    }
  }

  // 1. パスを短縮する
  // 2. バンドルの値を短縮する
  TraversalPath _shrinkPath(StateContext<T> context, Traversal traversal) {
    // TODO
    final start = traversal.currentPath!;
    var granularity = 1;
    var cycle = 0;
    var failed = start;
    while (cycle < maxShrinkingCycles) {
      print('--------------------------------------------');
      final paths = start.shrink(granularity);
      for (final path in paths) {
        print('Shrink cycle ${cycle + 1}');
        for (var i = 0; i < path.steps.length; i++) {
          // TODO: 最後にエラーになったパスの短縮の繰り返し
          final step = path.steps[i];
          final command = step.command;
          print('Shrink step ${i + 1}: ${command.description}');
          try {
            command.precondition?.call(context.state);
            command.run(context.state);
            command.postcondition?.call(context.state);
          } catch (e) {
            print('Error: $e');
            failed = path;
            continue;
          }
          // passのシュリンク終了
          _shrinkValue(path);
          return failed;
        }
        cycle++;
      }
    }
    return failed;
  }

  void _shrinkValue(TraversalPath path) {
    // TODO
    print('Shrink bundles...');
  }
}
