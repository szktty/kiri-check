import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/action.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';
import 'package:test/test.dart';

final class StatefulFalsifiedException<State, System> implements Exception {
  StatefulFalsifiedException(this.description, this.result);

  final Object? description;
  final StatefulShrinkingResult<State, System> result;

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('Falsifying command sequence:');
    for (var i = 0; i < result.sequence.steps.length; i++) {
      final step = result.sequence.steps[i];
      final command = step.command;
      buffer
        ..writeln('  Step ${i + 1}: ${command.description}')
        ..writeln('    Value: ${command.minValue}');
    }
    if (result.exception != null) {
      buffer.writeln(result.exception!.toString());
    }
    return buffer.toString();
  }
}

final class StateContext<State, System> {
  StateContext(this.state, this.system, this.property, this.test);

  final State state;
  final System system;
  final StatefulProperty<State, System> property;
  final PropertyTest test;

  Behavior<State, System> get behavior => property.behavior;

  bool executeCommand(Command<State, System> command) {
    return property._executeCommand(this, command);
  }
}

final class StatefulPropertyContext<State, System> {
  StatefulPropertyContext(this.property, this.test);

  final StatefulProperty<State, System> property;
  final PropertyTest test;
  int cycle = 0;
  int step = 0;
  int shrinkCycle = 0;

  bool get hasNextCycle => cycle < property.maxCycles;

  bool get hasNextShrinkCycle => shrinkCycle < property.maxShrinkingCycles;

  Behavior<State, System> get behavior => property.behavior;
}

final class StatefulProperty<State, System> extends Property<State> {
  StatefulProperty(
    this.behavior, {
    required super.settings,
    Timeout? cycleTimeout,
    super.setUp,
    super.tearDown,
    this.onCheck,
  }) {
    maxCycles = settings.maxStatefulCycles ?? KiriCheck.maxStatefulCycles;
    maxSteps = settings.maxStatefulSteps ?? KiriCheck.maxStatefulSteps;
    maxShrinkingCycles = settings.maxStatefulShrinkingCycles ??
        KiriCheck.maxStatefulShrinkingCycles;
    maxCommandTries =
        settings.maxStatefulCommandTries ?? KiriCheck.maxStatefulCommandTries;
    this.cycleTimeout = cycleTimeout ?? KiriCheck.statefulCycleTimeout;
  }

  final Behavior<State, System> behavior;

  final void Function(void Function())? onCheck;

  late final int maxCycles;
  late final int maxSteps;
  late final int maxShrinkingCycles;
  late final int maxCommandTries;
  late final Timeout cycleTimeout;

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
    this.setUp?.call();
    _checkSequences(test);
    this.tearDown?.call();
  }

  void _checkSequences(PropertyTest test) {
    final propertyContext = StatefulPropertyContext(this, test);
    for (propertyContext.cycle = 0;
        propertyContext.cycle < maxCycles;
        propertyContext.cycle++) {
      for (var cycle = 0; cycle < maxCycles; cycle++) {
        print('--------------------------------------------');
        print('Cycle ${cycle + 1}');

        final commandState = behavior.createState();
        final commands = behavior.generateCommands(commandState);
        final traversal = Traversal(propertyContext, commands);
        final sequence = traversal.generateSequence(commandState);

        final state = behavior.createState();
        print('Create state: ${state.runtimeType}');
        final system = behavior.createSystem(state);
        final stateContext = StateContext(state, system, this, test);

        for (var i = 0; i < sequence.steps.length; i++) {
          final step = sequence.steps[i];
          final command = step.command;
          print('Step ${i + 1}: ${command.description}');
          try {
            final result = stateContext.executeCommand(command);
            if (!result) {
              i--;
            }
          } on Exception catch (e) {
            print('Error: $e');
            behavior.dispose(state, system);

            final shrinker = _StatefulPropertyShrinker(
              propertyContext,
              stateContext,
              TraversalSequence(sequence.steps.sublist(0, i + 1)),
            );
            final result = shrinker.shrink();

            print('Falsified example sequence:');
            for (var i = 0; i < result.sequence.steps.length; i++) {
              final step = result.sequence.steps[i];
              final command = step.command;
              print('Step ${i + 1}: ${command.description}');
              if (command is Action) {
                print('Shrunk value: ${command.minValue}');
              }
            }

            throw StatefulFalsifiedException(test.description, result);
          }
        }
        behavior.dispose(state, system);
      }

      print('--------------------------------------------');
    }
  }

  bool _executeCommand(
    StateContext<State, System> context,
    Command<State, System> command,
  ) {
    final state = context.state;
    if (command.requires(state)) {
      command.execute(state, context.system, context.property.random);
      if (command.ensures(state, context.system)) {
        return true;
      } else {
        print('Postcondition is not satisfied');
        throw PropertyException('postcondition is not satisfied');
      }
    } else {
      print('Precondition is not satisfied');
      throw PropertyException('Precondition is not satisfied');
    }
  }
}

final class _StatefulPropertyShrinker<State, System> {
  _StatefulPropertyShrinker(
    this.propertyContext,
    this.stateContext,
    this.originalSequence,
  );

  final StatefulPropertyContext<State, System> propertyContext;
  final StateContext<State, System> stateContext;
  final TraversalSequence<State, System> originalSequence;
  Exception? lastException;

  StatefulProperty<State, System> get property => propertyContext.property;

  StatefulShrinkingResult<State, System> shrink() {
    final partial = _checkPartialSequences(originalSequence);
    final reduced = _checkReducedSequences(partial);
    _checkValues(reduced);
    return StatefulShrinkingResult(
      stateContext.state,
      reduced,
      exception: lastException,
    );
  }

  int get _shrinkCycle => propertyContext.shrinkCycle;

  bool get _hasShrinkCycle =>
      _shrinkCycle < propertyContext.property.maxShrinkingCycles;

  TraversalSequence<State, System> _checkPartialSequences(
      TraversalSequence<State, System> baseSequence) {
    propertyContext.shrinkCycle = 0;
    var previousSequences = <TraversalSequence<State, System>>[];
    var minShrunkSequence = baseSequence;
    var minShrunkNum = baseSequence.steps.length;
    while (_hasShrinkCycle) {
      final shrunkSequences = minShrunkSequence.shrink();
      print('Shrunk sequences: ${shrunkSequences.length}');
      assert(shrunkSequences.length <= 3);
      if (TraversalSequence.equals(previousSequences, shrunkSequences)) {
        break;
      }
      previousSequences = shrunkSequences;

      for (var i = 0; i < shrunkSequences.length; i++) {
        final shrunkSequence = shrunkSequences[i];
        print(
            'Shrink cycle ${_shrinkCycle + 1}: ${shrunkSequence.steps.length} steps');
        if (!_checkShrunkSequence(shrunkSequence)) {
          // 先頭に近い部分列を最小とする
          if (i < minShrunkNum) {
            print(
                'min shrunk sequence: $i, ${shrunkSequence.steps.length} steps');
            minShrunkSequence = shrunkSequence;
            minShrunkNum = i;
          }
        }
        propertyContext.shrinkCycle++;
        if (!_hasShrinkCycle) {
          break;
        }
      }
    }
    return minShrunkSequence;
  }

  // 一部のコマンドを削除して検査する
  TraversalSequence<State, System> _checkReducedSequences(
      TraversalSequence<State, System> baseSequence) {
    // コマンドのdescriptionの重複なしリストを作成する
    // baseSequenceのコマンド列を走査し、descriptionが重複しないコマンドを取得する
    final commandTypeSet = <String>{};
    for (final step in baseSequence.steps) {
      commandTypeSet.add(step.command.description);
    }

    var minShrunkSequence = baseSequence;
    for (final target in commandTypeSet) {
      if (!_hasShrinkCycle) {
        break;
      }

      final shrunkSequence = TraversalSequence<State, System>();
      for (var i = 0; i < minShrunkSequence.steps.length; i++) {
        final step = minShrunkSequence.steps[i];
        if (step.command.description != target) {
          shrunkSequence.addStep(step.command);
        }
      }

      if (shrunkSequence.steps.isNotEmpty &&
          !_checkShrunkSequence(shrunkSequence)) {
        if (shrunkSequence.steps.length < minShrunkSequence.steps.length) {
          minShrunkSequence = shrunkSequence;
        }
      }
    }

    print('Reduced shrunk sequence: ${minShrunkSequence.steps.length} steps');
    for (final step in minShrunkSequence.steps) {
      print('Step: ${step.command.description}');
    }

    return minShrunkSequence;
  }

  bool _checkShrunkSequence(TraversalSequence<State, System> sequence) {
    print('Check shrunk sequence: ${sequence.steps.length} steps');
    final state = propertyContext.behavior.createState();
    final system = propertyContext.behavior.createSystem(state);
    final stateContext =
        StateContext(state, system, property, propertyContext.test);
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      final command = step.command;
      print('Shrink step ${i + 1}: ${command.description}');
      try {
        command.useCache = true;
        stateContext.executeCommand(command);
      } on Exception catch (e) {
        print('Error: $e');
        lastException = e;
        stateContext.behavior.dispose(state, system);
        return false;
      }
    }
    stateContext.behavior.dispose(state, system);
    return true;
  }

  void _checkValues(TraversalSequence<State, System> sequence) {
    var allShrinkDone = false;
    while (_hasShrinkCycle && !allShrinkDone) {
      print('Shrink cycle ${_shrinkCycle + 1}');
      final state = propertyContext.behavior.createState();
      final system = propertyContext.behavior.createSystem(state);
      final stateContext =
          StateContext(state, system, property, propertyContext.test);
      allShrinkDone = true;
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        final command = step.command;
        print('Shrink step ${i + 1}: ${command.description}');
        try {
          // サイクル制限に達するか、すべてのコマンドのシュリンクが終了するまで繰り返す
          if (command.nextShrink()) {
            allShrinkDone = false;
          }
          stateContext.executeCommand(command);
        } on Exception catch (e) {
          print('Error: $e');
          lastException = e;
          command.failShrunk();
        }
      }
      propertyContext.shrinkCycle++;
    }
  }
}

final class StatefulShrinkingResult<State, System> {
  StatefulShrinkingResult(this.state, this.sequence, {this.exception});

  final State state;
  final TraversalSequence<State, System> sequence;
  final Exception? exception;
}
