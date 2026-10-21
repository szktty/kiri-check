import 'dart:async';

import 'package:collection/collection.dart';
import 'package:kiri_check/src/property/property_internal.dart';
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
    final falsifyingSequence = result.falsifyingSequence;
    final falsifyingValues = falsifyingSequence.steps
        .map((step) => step.commandContext.minValue)
        .toList();
    final buffer = StringBuffer()..writeln('Falsifying example sequence:');
    _writeSteps(buffer, falsifyingSequence, falsifyingValues, 'Shrunk value');
    final shrunk = !const ListEquality<Command<dynamic, dynamic>>().equals(
          result.originalSequence.steps.map((step) => step.command).toList(),
          falsifyingSequence.steps.map((step) => step.command).toList(),
        ) ||
        !const DeepCollectionEquality()
            .equals(result.originalValues, falsifyingValues);
    if (shrunk) {
      buffer.writeln('Original example sequence:');
      _writeSteps(
        buffer,
        result.originalSequence,
        result.originalValues,
        'Value',
      );
    }
    if (result.exception != null) {
      buffer.writeln('Exception: ${result.exception}');
    }
    if (result.stackTrace != null) {
      buffer
        ..writeln('Stack trace:')
        ..writeln(result.stackTrace);
    }
    return buffer.toString();
  }

  static void _writeSteps<State, System>(
    StringBuffer buffer,
    TraversalSequence<State, System> sequence,
    List<dynamic> values,
    String valueLabel,
  ) {
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      buffer.writeln('Step ${i + 1}: ${step.command.description}');
      if (step.commandContext.arbitrary != null) {
        buffer.writeln('  $valueLabel: ${values[i]}');
      }
    }
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
          StatefulExampleStep.fromSequence(
            result.originalSequence,
            result.originalValues,
          ),
          result.falsifyingState,
          result.falsifyingSystem,
          StatefulExampleStep.fromSequence(result.falsifyingSequence),
          result.exception,
          result.stackTrace,
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
        } on Exception catch (e, s) {
          printVerbose('  Error: $e');
          await _destroyBehavior(behavior, system);

          final shrinker = _StatefulPropertyShrinker(
            propertyContext,
            stateContext.state,
            stateContext.system,
            TraversalSequence(sequence.steps.sublist(0, i + 1)),
            lastException: e,
            lastStackTrace: s,
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
    if (await commandContext.precondition(context.state)) {
      await _executeCommand(context, commandContext);
      return true;
    } else {
      throw PropertyException('precondition is not satisfied');
    }
  }

  // Runs a command whose precondition is satisfied.
  Future<void> _executeCommand(
    StateContext<State, System> context,
    CommandContext<State, System> commandContext,
  ) async {
    final state = context.state;
    final result = await commandContext.run(context.system);
    if (await commandContext.postcondition(state, result)) {
      await commandContext.nextState(state);
    } else {
      throw PropertyException('postcondition is not satisfied');
    }
  }
}

final class _StatefulPropertyShrinker<State, System> {
  _StatefulPropertyShrinker(
    this.propertyContext,
    this.originalState,
    this.originalSystem,
    this.originalSequence, {
    this.lastException,
    this.lastStackTrace,
  }) : originalValues = originalSequence.steps
            .map((step) => step.commandContext.currentValue)
            .toList();

  final StatefulPropertyContext<State, System> propertyContext;
  final State originalState;
  final System originalSystem;
  final TraversalSequence<State, System> originalSequence;

  // The values the original failure ran with. Shrinking changes the values
  // held by the steps, which the original sequence shares.
  final List<dynamic> originalValues;

  // The failure of the smallest failing sequence found so far, initially the
  // original failure.
  Exception? lastException;
  StackTrace? lastStackTrace;
  StateContext<State, System>? _falsifyingContext;

  StatefulProperty<State, System> get property => propertyContext.property;

  Behavior<State, System> get behavior => propertyContext.behavior;

  Future<StatefulShrinkingResult<State, System>> shrink() async {
    propertyContext.shrinkCycle = 0;
    for (final step in originalSequence.steps) {
      step.commandContext.useCache = true;
    }

    final partial = await _checkPartialSequences(originalSequence);
    final reduced = await _checkReducedSequences(partial);
    final single = await _checkSingleRemovals(reduced);
    final shrunk = await _checkValues(single);
    for (final step in shrunk.steps) {
      step.commandContext.holdMin();
    }

    return StatefulShrinkingResult(
      originalState,
      originalSystem,
      originalSequence,
      originalValues,
      _falsifyingContext?.state ?? originalState,
      _falsifyingContext?.system ?? originalSystem,
      shrunk,
      lastException,
      lastStackTrace,
    );
  }

  int get _shrinkCycle => propertyContext.shrinkCycle;

  bool get _hasShrinkCycle =>
      _shrinkCycle < propertyContext.property.maxShrinkingCycles;

  // Records the failure as the smallest one found so far and returns its
  // sequence.
  TraversalSequence<State, System> _adopt(_ShrinkFailure<State, System> f) {
    lastException = f.exception;
    lastStackTrace = f.stackTrace;
    _falsifyingContext = f.context;
    return f.sequence;
  }

  Future<TraversalSequence<State, System>> _checkPartialSequences(
    TraversalSequence<State, System> baseSequence,
  ) async {
    var current = baseSequence;
    var previousSequences = <TraversalSequence<State, System>>[];
    while (_hasShrinkCycle) {
      final shrunkSequences = current.shrink();
      if (TraversalSequence.equals(previousSequences, shrunkSequences)) {
        break;
      }
      previousSequences = shrunkSequences;

      for (final shrunkSequence in shrunkSequences) {
        printVerbose(
          'Shrink cycle ${_shrinkCycle + 1}: '
          '${shrunkSequence.steps.length} steps',
        );
        final failure =
            await _runCandidate(shrunkSequence, stepType: 'partial');
        propertyContext.shrinkCycle++;
        if (failure != null &&
            failure.sequence.steps.length < current.steps.length) {
          current = _adopt(failure);
        }
        if (!_hasShrinkCycle) {
          break;
        }
      }
    }
    return current;
  }

  Future<TraversalSequence<State, System>> _checkReducedSequences(
    TraversalSequence<State, System> baseSequence,
  ) async {
    final commandTypeSet = <String>{};
    for (final step in baseSequence.steps) {
      commandTypeSet.add(step.command.description);
    }

    var current = baseSequence;
    for (final target in commandTypeSet) {
      if (!_hasShrinkCycle) {
        break;
      }

      final shrunkSequence = TraversalSequence<State, System>();
      for (final step in current.steps) {
        if (step.command.description != target) {
          shrunkSequence.addStep(step);
        }
      }
      if (shrunkSequence.steps.isEmpty) {
        continue;
      }

      final failure = await _runCandidate(shrunkSequence, stepType: 'reduced');
      if (failure != null &&
          failure.sequence.steps.length < current.steps.length) {
        current = _adopt(failure);
      }
    }
    return current;
  }

  // Drops one step at a time, from the last back to the first. A candidate
  // that still fails replaces the sequence and the pass starts again from its
  // end. The partial and reduced passes cannot drop a single step from the
  // middle of a sequence.
  Future<TraversalSequence<State, System>> _checkSingleRemovals(
    TraversalSequence<State, System> baseSequence,
  ) async {
    var current = baseSequence;
    var i = current.steps.length - 1;
    while (i >= 0 && current.steps.length > 1 && _hasShrinkCycle) {
      final shrunkSequence = TraversalSequence<State, System>();
      for (var j = 0; j < current.steps.length; j++) {
        if (j != i) {
          shrunkSequence.addStep(current.steps[j]);
        }
      }
      printVerbose('Shrink cycle ${_shrinkCycle + 1}: without step ${i + 1}');
      final failure = await _runCandidate(shrunkSequence, stepType: 'single');
      propertyContext.shrinkCycle++;
      if (failure != null) {
        current = _adopt(failure);
        i = current.steps.length - 1;
      } else {
        i--;
      }
    }
    return current;
  }

  // Shrinks the value of one step at a time, holding the other steps at their
  // smallest failing values. The rounds over the steps repeat until a round
  // shrinks no value, since a smaller value of one step can let another
  // shrink further.
  Future<TraversalSequence<State, System>> _checkValues(
    TraversalSequence<State, System> baseSequence,
  ) async {
    var current = baseSequence;
    var shrunk = true;
    while (shrunk && _hasShrinkCycle) {
      shrunk = false;
      var restart = false;
      for (var target = 0;
          target < current.steps.length && _hasShrinkCycle && !restart;
          target++) {
        final context = current.steps[target].commandContext..restartShrink();
        while (_hasShrinkCycle && context.tryShrink()) {
          context.nextValue();
          printVerbose(
            'Shrink cycle ${_shrinkCycle + 1}: the value of step ${target + 1}',
          );
          final failure = await _runCandidate(current, stepType: 'value');
          propertyContext.shrinkCycle++;
          if (failure == null) {
            context.holdMin();
            continue;
          }

          // A failure anywhere in the sequence is caused by the target value.
          context.failShrink();
          shrunk = true;
          final length = current.steps.length;
          current = _adopt(failure);
          if (current.steps.length < length) {
            // Steps were dropped, so the targets have moved.
            restart = true;
            break;
          }
        }
        context.holdMin();
      }
    }
    return current;
  }

  // Runs a candidate sequence against a new system. Returns the failure with
  // the steps executed up to the failing one, or null if the candidate passes.
  //
  // A step whose precondition is not satisfied is skipped, so a failing
  // candidate is reported as the steps actually executed.
  Future<_ShrinkFailure<State, System>?> _runCandidate(
    TraversalSequence<State, System> sequence, {
    required String stepType,
  }) async {
    await behavior.setUp();
    final (initPrecond, state) = await property._initialState();
    if (!initPrecond) {
      printVerbose('  Error: initial precondition is not satisfied');
      await behavior.tearDown();
      return null;
    }

    final system = await behavior.createSystem(state);
    final stateContext =
        StateContext(state, system, property, propertyContext.test);
    final executed = TraversalSequence<State, System>();
    try {
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        printVerbose('Shrink $stepType step ${i + 1}: '
            '${step.command.description}');
        executed.addStep(step);
        try {
          if (!await step.commandContext.precondition(state)) {
            printVerbose('  Skipped: precondition is not satisfied');
            executed.steps.removeLast();
            continue;
          }
          await property._executeCommand(stateContext, step.commandContext);
        } on Exception catch (e, s) {
          printVerbose('  Error: $e');
          return _ShrinkFailure(executed, stateContext, e, s);
        }
      }
      return null;
    } finally {
      await property._destroyBehavior(behavior, system);
    }
  }
}

final class _ShrinkFailure<State, System> {
  _ShrinkFailure(this.sequence, this.context, this.exception, this.stackTrace);

  final TraversalSequence<State, System> sequence;
  final StateContext<State, System> context;
  final Exception exception;
  final StackTrace stackTrace;
}

final class StatefulShrinkingResult<State, System> {
  StatefulShrinkingResult(
    this.originalState,
    this.originalSystem,
    this.originalSequence,
    this.originalValues,
    this.falsifyingState,
    this.falsifyingSystem,
    this.falsifyingSequence,
    this.exception,
    this.stackTrace,
  );

  final State originalState;
  final System originalSystem;
  final TraversalSequence<State, System> originalSequence;
  final List<dynamic> originalValues;
  final State falsifyingState;
  final System falsifyingSystem;
  final TraversalSequence<State, System> falsifyingSequence;
  final Exception? exception;
  final StackTrace? stackTrace;
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
    this.stackTrace,
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

  /// The stack trace that occurred during the initial failure or shrinking.
  final StackTrace? stackTrace;
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
    TraversalSequence<State, System> sequence, [
    List<dynamic>? values,
  ]) {
    return sequence.steps
        .mapIndexed(
          (i, step) => StatefulExampleStep(
            i,
            step.command,
            values != null ? values[i] : step.commandContext.minValue,
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
