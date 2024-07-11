import 'dart:async';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/home.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/state/behavior.dart';
import 'package:kiri_check/src/state/command/command.dart';
import 'package:kiri_check/src/state/command/context.dart';
import 'package:kiri_check/src/state/top.dart';
import 'package:kiri_check/src/state/traversal.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

final class StatefulFalsifiedException<State, System> implements Exception {
  StatefulFalsifiedException(this.result);

  final StatefulShrinkingResult<State, System> result;

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('Falsifying example sequence:');
    final sequence = result.falsifyingSequence;
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      buffer.writeln('Step ${i + 1}: ${step.command.description}');
      if (step.commandContext.arbitrary != null) {
        buffer.writeln('  Shrunk value: ${step.commandContext.minValue}');
      }
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

  Future<bool> runCommand(CommandContext<State, System> commandContext) {
    return property._runCommand(this, commandContext);
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
    this.onDestroy,
    this.onFalsify,
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

  final FutureOr<void> Function(Behavior<State, System>, System)? onDestroy;
  final FutureOr<void> Function(StatefulFalsifyingExample<State, System>)?
      onFalsify;

  late final int maxCycles;
  late final int maxSteps;
  late final int maxShrinkingCycles;
  late final int maxCommandTries;
  late final Timeout cycleTimeout;

  @override
  Future<void> check(PropertyTest test) async {
    final (result, exception) = await _check(test);

    if (exception != null) {
      throw exception;
    } else if (result != null) {
      final description = result.toString();
      printVerbose('');
      printVerbose(description);

      if (onFalsify != null) {
        final example = StatefulFalsifyingExample(
          result.originalState,
          result.originalSystem,
          StatefulExampleStep.fromSequence(result.originalSequence),
          result.falsifyingState,
          result.falsifyingSystem,
          StatefulExampleStep.fromSequence(result.falsifyingSequence),
          result.exception,
        );
        await onFalsify!.call(example);
      }

      if (!settings.ignoreFalsify) {
        throw StatefulFalsifiedException<State, System>(result);
      }
    }
  }

  Future<(StatefulShrinkingResult<State, System>?, Exception?)> _check(
    PropertyTest test,
  ) async {
    printVerbose('Check behavior: ${behavior.runtimeType}');
    await this.setUp?.call();
    await behavior.setUpAll();

    StatefulShrinkingResult<State, System>? result;
    Exception? exception;
    try {
      result = await _checkSequences(test);
    } on Exception catch (e) {
      exception = e;
    }
    await behavior.tearDownAll();
    await this.tearDown?.call();
    return (result, exception);
  }

  Future<(bool, State)> _initialState() async {
    final state = await behavior.initialState();
    return (await behavior.initialPrecondition(state), state);
  }

  Future<StatefulShrinkingResult<State, System>?> _checkSequences(
    PropertyTest test,
  ) async {
    final propertyContext = StatefulPropertyContext(this, test);
    for (propertyContext.cycle = 0;
        propertyContext.cycle < maxCycles;
        propertyContext.cycle++) {
      printVerbose('--------------------------------------------');
      printVerbose('Cycle ${propertyContext.cycle + 1}');

      await behavior.setUp();

      printVerbose('Generate commands...');
      final (initPrecond0, state0) = await _initialState();
      if (!initPrecond0) {
        await behavior.tearDown();
        throw KiriCheckException('initial precondition is not satisfied');
      }

      await behavior.onGenerate(state0);
      final commands = await behavior.generateCommands(state0);
      final traversal = Traversal(propertyContext, commands);
      final sequence = await traversal.generateSequence(state0);

      final (initPrecond, state) = await _initialState();
      if (!initPrecond) {
        await behavior.tearDown();
        throw KiriCheckException('initial precondition is not satisfied');
      }
      final system = await behavior.createSystem(state);
      final stateContext = StateContext(state, system, this, test);

      printVerbose('Create state: ${state.runtimeType}');
      printVerbose('Create system: ${system.runtimeType}');
      await behavior.onExecute(state, system);

      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        printVerbose('Step ${i + 1}: ${step.command.description}');
        try {
          step.commandContext.nextValue();
          final result = await stateContext.runCommand(step.commandContext);
          if (!result) {
            i--;
          }
        } on Exception catch (e) {
          printVerbose('  Error: $e');
          await _destroyBehavior(behavior, system);

          final shrinker = _StatefulPropertyShrinker(
            propertyContext,
            stateContext.state,
            stateContext.system,
            TraversalSequence(sequence.steps.sublist(0, i + 1)),
          );
          printVerbose('--------------------------------------------');
          return shrinker.shrink();
        }
      }
      await _destroyBehavior(behavior, system);
    }
    printVerbose('--------------------------------------------');
    return null;
  }

  Future<void> _destroyBehavior(
    Behavior<State, System> behavior,
    System system,
  ) async {
    if (onDestroy != null) {
      await onDestroy?.call(behavior, system);
    }
    await behavior.destroySystem(system);
    await behavior.tearDown();
  }

  Future<bool> _runCommand(
    StateContext<State, System> context,
    CommandContext<State, System> commandContext,
  ) async {
    final state = context.state;
    if (await commandContext.precondition(state)) {
      final result = await commandContext.run(context.system);
      if (await commandContext.postcondition(state, result)) {
        await commandContext.nextState(state);
        return true;
      } else {
        throw PropertyException('postcondition is not satisfied');
      }
    } else {
      throw PropertyException('precondition is not satisfied');
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

  Behavior<State, System> get behavior => propertyContext.behavior;

  Future<StatefulShrinkingResult<State, System>> shrink() async {
    final partial = await _checkPartialSequences(originalSequence);
    final reduced = await _checkReducedSequences(partial);
    final shrunk = await _checkValues(reduced);
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

  Future<TraversalSequence<State, System>> _checkPartialSequences(
    TraversalSequence<State, System> baseSequence,
  ) async {
    propertyContext.shrinkCycle = 0;
    var previousSequences = <TraversalSequence<State, System>>[];
    var minShrunkSequence = baseSequence;
    var minShrunkNum = baseSequence.steps.length;
    while (_hasShrinkCycle) {
      final shrunkSequences = minShrunkSequence.shrink();
      if (TraversalSequence.equals(previousSequences, shrunkSequences)) {
        break;
      }
      previousSequences = shrunkSequences;

      for (var i = 0; i < shrunkSequences.length; i++) {
        final shrunkSequence = shrunkSequences[i];
        printVerbose(
          'Shrink cycle ${_shrinkCycle + 1}: '
          '${shrunkSequence.steps.length} steps',
        );
        await behavior.setUp();
        if (!await _checkShrunkSequence(shrunkSequence, stepType: 'partial')) {
          if (i < minShrunkNum) {
            minShrunkSequence = shrunkSequence;
            minShrunkNum = i;
          }
        }
        behavior.tearDown();
        propertyContext.shrinkCycle++;
        if (!_hasShrinkCycle) {
          break;
        }
      }
    }
    return minShrunkSequence;
  }

  Future<TraversalSequence<State, System>> _checkReducedSequences(
    TraversalSequence<State, System> baseSequence,
  ) async {
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
          shrunkSequence.addStep(step);
        }
      }

      if (shrunkSequence.steps.isNotEmpty &&
          !await _checkShrunkSequence(shrunkSequence, stepType: 'reduced')) {
        if (shrunkSequence.steps.length < minShrunkSequence.steps.length) {
          minShrunkSequence = shrunkSequence;
        }
      }
    }

    return minShrunkSequence;
  }

  Future<bool> _checkShrunkSequence(
    TraversalSequence<State, System> sequence, {
    required String stepType,
  }) async {
    await behavior.setUp();
    final (initPrecond, state) = await property._initialState();
    if (!initPrecond) {
      return false;
    }
    final system = await behavior.createSystem(state);
    final stateContext =
        StateContext(state, system, property, propertyContext.test);
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      printVerbose('Shrink $stepType step ${i + 1}: '
          '${step.command.description}');
      try {
        step.commandContext.useCache = true;
        step.commandContext.nextValue();
        await stateContext.runCommand(step.commandContext);
      } on Exception catch (e) {
        printVerbose('  Error: $e');
        if (i + 1 < sequence.steps.length) {
          sequence.truncateSteps(i + 1);
        }
        lastException = e;

        await property._destroyBehavior(behavior, system);
        return false;
      }
    }
    await property._destroyBehavior(behavior, system);
    return true;
  }

  Future<StateContext<State, System>?> _checkValues(
    TraversalSequence<State, System> sequence,
  ) async {
    var allShrinkDone = false;
    StateContext<State, System>? shrunkContext;
    while (_hasShrinkCycle && !allShrinkDone) {
      printVerbose('Shrink cycle ${_shrinkCycle + 1}');
      final (initPrecond, state) = await property._initialState();
      if (!initPrecond) {
        printVerbose('  Error: initial precondition is not satisfied');
        return shrunkContext;
      }

      final system = await propertyContext.behavior.createSystem(state);
      final stateContext =
          StateContext(state, system, property, propertyContext.test);
      allShrinkDone = true;
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        printVerbose('Shrink value step ${i + 1}: ${step.command.description}');
        try {
          if (step.commandContext.tryShrink()) {
            step.commandContext.nextValue();
            allShrinkDone = false;
          }
          await stateContext.runCommand(step.commandContext);
        } on Exception catch (e) {
          printVerbose('  Error: $e');
          lastException = e;
          step.commandContext.failShrink();
          shrunkContext = stateContext;
          break;
        }
      }
      await property._destroyBehavior(behavior, system);
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

/// A falsifying example of a stateful property.
///
/// See also:
/// - [runBehavior], runs a stateful test according to the behavior.
/// - [StatefulExampleStep], a step in a stateful example.
final class StatefulFalsifyingExample<State, System> {
  /// @nodoc
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

  /// The state in which the initial failure occurred.
  final State originalState;

  /// The system in which the initial failure occurred.
  final System originalSystem;

  /// The steps that led to the initial failure.
  final List<StatefulExampleStep<State, System>> originalSteps;

  /// The state in which the failure was found after shrinking.
  final State falsifyingState;

  /// The system in which the failure was found after shrinking.
  final System falsifyingSystem;

  /// The steps that led to the failure after shrinking.
  final List<StatefulExampleStep<State, System>> falsifyingSteps;

  /// The exception that occurred during the initial failure or shrinking.
  final Exception? exception;
}

/// A step in a stateful example.
///
/// See also:
/// - [StatefulFalsifyingExample], a falsifying example of a stateful property.
final class StatefulExampleStep<State, System> {
  /// @nodoc
  @protected
  StatefulExampleStep(this.number, this.command, this.value);

  /// @nodoc
  @protected
  @internal
  static List<StatefulExampleStep<State, System>> fromSequence<State, System>(
    TraversalSequence<State, System> sequence,
  ) {
    return sequence.steps
        .mapIndexed(
          (i, step) => StatefulExampleStep(
            i,
            step.command,
            step.commandContext.minValue,
          ),
        )
        .toList();
  }

  /// The number of the step.
  final int number;

  /// The command that was run in this step.
  final Command<State, System> command;

  /// The value that was used in this step.
  final dynamic value;
}
