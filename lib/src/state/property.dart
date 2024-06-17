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

  bool runCommand(CommandContext<State, System> commandContext) {
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

  final void Function(Behavior<State, System>, System)? onDestroy;
  final void Function(StatefulFalsifyingExample<State, System>)? onFalsify;

  late final int maxCycles;
  late final int maxSteps;
  late final int maxShrinkingCycles;
  late final int maxCommandTries;
  late final Timeout cycleTimeout;

  @override
  void check(PropertyTest test) {
    final (result, exception) = _check(test);

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
        onFalsify!.call(example);
      }

      if (!settings.ignoreFalsify) {
        throw StatefulFalsifiedException<State, System>(result);
      }
    }
  }

  (StatefulShrinkingResult<State, System>?, Exception?) _check(
      PropertyTest test) {
    printVerbose('Check behavior: ${behavior.runtimeType}');
    this.setUp?.call();
    behavior.setUpAll();

    StatefulShrinkingResult<State, System>? result;
    Exception? exception;
    try {
      result = _checkSequences(test);
    } on Exception catch (e) {
      exception = e;
    }
    behavior.tearDownAll();
    this.tearDown?.call();
    return (result, exception);
  }

  (bool, State) _initialState() {
    final state = behavior.initialState();
    return (behavior.initialPrecondition(state), state);
  }

  StatefulShrinkingResult<State, System>? _checkSequences(PropertyTest test) {
    final propertyContext = StatefulPropertyContext(this, test);
    for (propertyContext.cycle = 0;
        propertyContext.cycle < maxCycles;
        propertyContext.cycle++) {
      printVerbose('--------------------------------------------');
      printVerbose('Cycle ${propertyContext.cycle + 1}');

      behavior.setUp();

      printVerbose('Generate commands...');
      final (initPrecond0, state0) = _initialState();
      if (!initPrecond0) {
        behavior.tearDown();
        throw KiriCheckException('initial precondition is not satisfied');
      }

      behavior.onGenerate(state0);
      final commands = behavior.generateCommands(state0);
      final traversal = Traversal(propertyContext, commands);
      final sequence = traversal.generateSequence(state0);

      final (initPrecond, state) = _initialState();
      if (!initPrecond) {
        behavior.tearDown();
        throw KiriCheckException('initial precondition is not satisfied');
      }
      final system = behavior.createSystem(state);
      final stateContext = StateContext(state, system, this, test);

      printVerbose('Create state: ${state.runtimeType}');
      printVerbose('Create system: ${system.runtimeType}');
      behavior.onExecute(state, system);

      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        printVerbose('Step ${i + 1}: ${step.command.description}');
        try {
          step.commandContext.nextValue();
          final result = stateContext.runCommand(step.commandContext);
          if (!result) {
            i--;
          }
        } on Exception catch (e) {
          printVerbose('  Error: $e');
          _destroyBehavior(behavior, system);

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
      _destroyBehavior(behavior, system);
    }
    printVerbose('--------------------------------------------');
    return null;
  }

  void _destroyBehavior(
    Behavior<State, System> behavior,
    System system,
  ) {
    if (onDestroy != null) {
      onDestroy?.call(behavior, system);
    }
    behavior
      ..destroy(system)
      ..tearDown();
  }

  bool _runCommand(
    StateContext<State, System> context,
    CommandContext<State, System> commandContext,
  ) {
    final state = context.state;
    if (commandContext.precondition(state)) {
      final result = commandContext.run(context.system);
      if (commandContext.postcondition(state, result)) {
        commandContext.nextState(state);
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
        behavior.setUp();
        if (!_checkShrunkSequence(shrunkSequence, stepType: 'partial')) {
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

  TraversalSequence<State, System> _checkReducedSequences(
    TraversalSequence<State, System> baseSequence,
  ) {
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
          !_checkShrunkSequence(shrunkSequence, stepType: 'reduced')) {
        if (shrunkSequence.steps.length < minShrunkSequence.steps.length) {
          minShrunkSequence = shrunkSequence;
        }
      }
    }

    return minShrunkSequence;
  }

  bool _checkShrunkSequence(TraversalSequence<State, System> sequence,
      {required String stepType}) {
    behavior.setUp();
    final (initPrecond, state) = property._initialState();
    if (!initPrecond) {
      return false;
    }
    final system = behavior.createSystem(state);
    final stateContext =
        StateContext(state, system, property, propertyContext.test);
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      printVerbose('Shrink $stepType step ${i + 1}: '
          '${step.command.description}');
      try {
        step.commandContext.useCache = true;
        step.commandContext.nextValue();
        stateContext.runCommand(step.commandContext);
      } on Exception catch (e) {
        printVerbose('  Error: $e');
        if (i + 1 < sequence.steps.length) {
          sequence.truncateSteps(i + 1);
        }
        lastException = e;

        property._destroyBehavior(behavior, system);
        return false;
      }
    }
    property._destroyBehavior(behavior, system);
    return true;
  }

  StateContext<State, System>? _checkValues(
    TraversalSequence<State, System> sequence,
  ) {
    var allShrinkDone = false;
    StateContext<State, System>? shrunkContext;
    while (_hasShrinkCycle && !allShrinkDone) {
      printVerbose('Shrink cycle ${_shrinkCycle + 1}');
      final (initPrecond, state) = property._initialState();
      if (!initPrecond) {
        printVerbose('  Error: initial precondition is not satisfied');
        return shrunkContext;
      }

      final system = propertyContext.behavior.createSystem(state);
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
          stateContext.runCommand(step.commandContext);
        } on Exception catch (e) {
          printVerbose('  Error: $e');
          lastException = e;
          step.commandContext.failShrink();
          shrunkContext = stateContext;
          break;
        }
      }
      property._destroyBehavior(behavior, system);
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
