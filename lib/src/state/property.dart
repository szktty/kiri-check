import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/action.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/state/traversal.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

final class StatefulFalsifiedException<State, System> implements Exception {
  StatefulFalsifiedException(this.description, this.result);

  // TODO: 使ってない？
  final Object? description;
  final StatefulShrinkingResult<State, System> result;

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('Falsifying command sequence:');
    final sequence = result.falsifyingSequence;
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      final command = step.context.command;
      buffer.writeln('  Step ${i + 1}: ${command.description}');
      //..writeln('    Value: ${command.minValue}');
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

  bool executeCommand(CommandContext<State, System> commandContext) {
    return property._executeCommand(this, commandContext);
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
    this.onDispose,
    this.onFalsify,
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
  final void Function(Behavior<State, System>, State, System)? onDispose;
  final void Function(StatefulFalsifyingExample<State, System>)? onFalsify;

  late final int maxCycles;
  late final int maxSteps;
  late final int maxShrinkingCycles;
  late final int maxCommandTries;
  late final Timeout cycleTimeout;

  @override
  void check(PropertyTest test) {
    StatefulShrinkingResult<State, System>? result;

    if (onCheck != null) {
      var called = false;
      onCheck!(() {
        if (called) {
          throw PropertyException('onCheck is called more than once');
        } else {
          called = true;
          result = _check(test);
        }
      });
      if (!called) {
        throw PropertyException('onCheck is not called');
      }
    } else {
      result = _check(test);
    }

    if (result != null) {
      print('Falsified example sequence:');
      final sequence = result!.falsifyingSequence;
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        final command = step.context.command;
        print('Step ${i + 1}: ${command.description}');
        if (step.context is ActionContext) {
          print('Shrunk value: ${step.context.minValue}');
        }
      }

      if (onFalsify != null) {
        final example = StatefulFalsifyingExample(
          result!.originalState,
          result!.originalSystem,
          StatefulExampleStep.fromSequence(result!.originalSequence),
          result!.falsifyingState,
          result!.falsifyingSystem,
          StatefulExampleStep.fromSequence(result!.falsifyingSequence),
          result!.exception,
        );
        onFalsify!.call(example);
      }

      if (!settings.ignoreFalsify) {
        throw StatefulFalsifiedException<State, System>(null, result!);
      }
    }
  }

  StatefulShrinkingResult<State, System>? _check(PropertyTest test) {
    print('Check behavior: ${behavior.runtimeType}');
    this.setUp?.call();
    final result = _checkSequences(test);
    this.tearDown?.call();
    return result;
  }

  StatefulShrinkingResult<State, System>? _checkSequences(PropertyTest test) {
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
          print('Step ${i + 1}: ${step.context.command.description}');
          try {
            final result = stateContext.executeCommand(step.context);
            if (!result) {
              i--;
            }
          } on Exception catch (e) {
            print('Error: $e');
            _disposeBehavior(behavior, state, system);

            final shrinker = _StatefulPropertyShrinker(
              propertyContext,
              stateContext.state,
              stateContext.system,
              TraversalSequence(sequence.steps.sublist(0, i + 1)),
            );
            return shrinker.shrink();
          }
        }
        _disposeBehavior(behavior, state, system);
      }

      print('--------------------------------------------');
    }
    return null;
  }

  void _disposeBehavior(
    Behavior<State, System> behavior,
    State state,
    System system,
  ) {
    if (onDispose != null) {
      onDispose?.call(behavior, state, system);
    }
    behavior.dispose(state, system);
  }

  bool _executeCommand(
    StateContext<State, System> context,
    CommandContext<State, System> commandContext,
  ) {
    final state = context.state;
    final command = commandContext.command;
    if (command.requires(state)) {
      commandContext.execute(state, context.system, context.property.random);
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
    this.originalState,
    this.originalSystem,
    this.originalSequence,
  );

  final StatefulPropertyContext<State, System> propertyContext;
  final State originalState;
  final System originalSystem;
  final TraversalSequence<State, System> originalSequence;
  Exception? lastException;

  StatefulProperty<State, System> get property => propertyContext.property;

  StatefulShrinkingResult<State, System> shrink() {
    final partial = _checkPartialSequences(originalSequence);
    final reduced = _checkReducedSequences(partial);
    final shrunk = _checkValues(reduced);
    return StatefulShrinkingResult(
      originalState,
      originalSystem,
      originalSequence,
      shrunk?.state ?? originalState,
      shrunk?.system ?? originalSystem,
      reduced,
      lastException,
    );
  }

  int get _shrinkCycle => propertyContext.shrinkCycle;

  bool get _hasShrinkCycle =>
      _shrinkCycle < propertyContext.property.maxShrinkingCycles;

  TraversalSequence<State, System> _checkPartialSequences(
    TraversalSequence<State, System> baseSequence,
  ) {
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
          'Shrink cycle ${_shrinkCycle + 1}: ${shrunkSequence.steps.length} steps',
        );
        if (!_checkShrunkSequence(shrunkSequence)) {
          // 先頭に近い部分列を最小とする
          if (i < minShrunkNum) {
            print(
              'min shrunk sequence: $i, ${shrunkSequence.steps.length} steps',
            );
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
    TraversalSequence<State, System> baseSequence,
  ) {
    // コマンドのdescriptionの重複なしリストを作成する
    // baseSequenceのコマンド列を走査し、descriptionが重複しないコマンドを取得する
    final commandTypeSet = <String>{};
    for (final step in baseSequence.steps) {
      commandTypeSet.add(step.context.command.description);
    }

    var minShrunkSequence = baseSequence;
    for (final target in commandTypeSet) {
      if (!_hasShrinkCycle) {
        break;
      }

      final shrunkSequence = TraversalSequence<State, System>();
      for (var i = 0; i < minShrunkSequence.steps.length; i++) {
        final step = minShrunkSequence.steps[i];
        if (step.context.command.description != target) {
          shrunkSequence.addStep(step);
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
      print('Step: ${step.context.command.description}');
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
      print('Shrink step ${i + 1}: ${step.context.command.description}');
      try {
        step.context.useCache = true;
        stateContext.executeCommand(step.context);
      } on Exception catch (e) {
        print('Error: $e');
        if (i + 1 < sequence.steps.length) {
          sequence.truncateSteps(i + 1);
        }
        lastException = e;
        stateContext.behavior.dispose(state, system);
        return false;
      }
    }
    stateContext.behavior.dispose(state, system);
    return true;
  }

  StateContext<State, System>? _checkValues(
    TraversalSequence<State, System> sequence,
  ) {
    var allShrinkDone = false;
    StateContext<State, System>? shrunkContext;
    while (_hasShrinkCycle && !allShrinkDone) {
      print('Shrink cycle ${_shrinkCycle + 1}');
      final state = propertyContext.behavior.createState();
      final system = propertyContext.behavior.createSystem(state);
      final stateContext =
          StateContext(state, system, property, propertyContext.test);
      allShrinkDone = true;
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        final context = step.context;
        print('Shrink step ${i + 1}: ${context.command.description}');
        try {
          // サイクル制限に達するか、すべてのコマンドのシュリンクが終了するまで繰り返す
          if (context.nextShrink()) {
            allShrinkDone = false;
          }
          stateContext.executeCommand(context);
        } on Exception catch (e) {
          print('Error: $e');
          lastException = e;
          context.failShrunk();
          shrunkContext = stateContext;
          break;
        }
      }
      stateContext.behavior.dispose(state, system);
      propertyContext.shrinkCycle++;
    }
    return shrunkContext;
  }
}

final class StatefulShrinkingResult<State, System> {
  StatefulShrinkingResult(
    this.originalState,
    this.originalSystem,
    this.originalSequence,
    this.falsifyingState,
    this.falsifyingSystem,
    this.falsifyingSequence,
    this.exception,
  );

  final State originalState;
  final System originalSystem;
  final TraversalSequence<State, System> originalSequence;
  final State falsifyingState;
  final System falsifyingSystem;
  final TraversalSequence<State, System> falsifyingSequence;
  final Exception? exception;
}

final class StatefulFalsifyingExample<State, System> {
  @protected
  StatefulFalsifyingExample(
    this.originalState,
    this.originalSystem,
    this.originalSteps,
    this.falsifyingState,
    this.falsifyingSystem,
    this.falsifyingSteps,
    this.exception,
  );

  final State originalState;
  final System originalSystem;
  final List<StatefulExampleStep<State, System>> originalSteps;
  final State falsifyingState;
  final System falsifyingSystem;
  final List<StatefulExampleStep<State, System>> falsifyingSteps;

  final Exception? exception;
}

final class StatefulExampleStep<State, System> {
  @protected
  StatefulExampleStep(this.number, this.command, this.value);

  /// :nodoc:
  @protected
  static List<StatefulExampleStep<State, System>> fromSequence<State, System>(
    TraversalSequence<State, System> sequence,
  ) {
    return sequence.steps
        .mapIndexed(
          (i, step) => StatefulExampleStep(
            i,
            step.context.command,
            step.context.minValue,
          ),
        )
        .toList();
  }

  final int number;
  final Command<State, System> command;
  final dynamic value;
}
