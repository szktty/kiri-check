import 'package:collection/collection.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/home.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/state/behavior.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/command/action.dart';
import 'package:kiri_check/src/state/top.dart';
import 'package:kiri_check/src/state/traversal.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

final class StatefulFalsifiedException<State, System, R> implements Exception {
  StatefulFalsifiedException(this.result);

  final StatefulShrinkingResult<State, System, R> result;
}

final class StateContext<State, System, R> {
  StateContext(this.state, this.system, this.property, this.test);

  final State state;
  final System system;
  final StatefulProperty<State, System, R> property;
  final PropertyTest test;

  Behavior<State, System, R> get behavior => property.behavior;

  bool runCommand(CommandContext<State, System, R> commandContext) {
    return property._runCommand(this, commandContext);
  }
}

final class StatefulPropertyContext<State, System, R> {
  StatefulPropertyContext(this.property, this.test);

  final StatefulProperty<State, System, R> property;
  final PropertyTest test;
  int cycle = 0;
  int step = 0;
  int shrinkCycle = 0;

  bool get hasNextCycle => cycle < property.maxCycles;

  bool get hasNextShrinkCycle => shrinkCycle < property.maxShrinkingCycles;

  Behavior<State, System, R> get behavior => property.behavior;
}

final class StatefulProperty<State, System, R> extends Property<State> {
  StatefulProperty(
    this.behavior, {
    required super.settings,
    Timeout? cycleTimeout,
    super.setUp,
    super.tearDown,
    this.onDispose,
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

  final Behavior<State, System, R> behavior;

  final void Function(Behavior<State, System, R>, State, System)? onDispose;
  final void Function(StatefulFalsifyingExample<State, System, R>)? onFalsify;

  late final int maxCycles;
  late final int maxSteps;
  late final int maxShrinkingCycles;
  late final int maxCommandTries;
  late final Timeout cycleTimeout;

  @override
  void check(PropertyTest test) {
    final result = _check(test);

    if (result != null) {
      printVerbose('');
      printVerbose('Falsifying example sequence:');
      final sequence = result.falsifyingSequence;
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        final command = step.context.command;
        printVerbose('Step ${i + 1}: ${command.description}');
        if (step.context is ActionContext) {
          printVerbose('  Shrunk value: ${step.context.minValue}');
        }
      }

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
        throw StatefulFalsifiedException<State, System, R>(result);
      }
    }
  }

  StatefulShrinkingResult<State, System, R>? _check(PropertyTest test) {
    printVerbose('Check behavior: ${behavior.runtimeType}');
    this.setUp?.call();
    behavior.setUpAll();
    final result = _checkSequences(test);
    behavior.tearDownAll();
    this.tearDown?.call();
    return result;
  }

  StatefulShrinkingResult<State, System, R>? _checkSequences(
      PropertyTest test) {
    final propertyContext = StatefulPropertyContext(this, test);
    for (propertyContext.cycle = 0;
        propertyContext.cycle < maxCycles;
        propertyContext.cycle++) {
      printVerbose('--------------------------------------------');
      printVerbose('Cycle ${propertyContext.cycle + 1}');

      behavior.setUp();
      final commandState = behavior.createState();
      final commands = behavior.generateCommands(commandState);
      final traversal = Traversal(propertyContext, commands);
      final sequence = traversal.generateSequence(commandState);

      final state = behavior.createState();
      final system = behavior.createSystem(state);
      final stateContext = StateContext(state, system, this, test);

      printVerbose('Create state: ${state.runtimeType}');
      printVerbose('Create system: ${system.runtimeType}');

      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        printVerbose('Step ${i + 1}: ${step.context.command.description}');
        try {
          final result = stateContext.runCommand(step.context);
          if (!result) {
            i--;
          }
        } on Exception catch (e) {
          printVerbose('  Error: $e');
          _disposeBehavior(behavior, state, system);

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
      _disposeBehavior(behavior, state, system);
    }
    printVerbose('--------------------------------------------');
    return null;
  }

  void _disposeBehavior(
    Behavior<State, System, R> behavior,
    State state,
    System system,
  ) {
    if (onDispose != null) {
      onDispose?.call(behavior, state, system);
    }
    behavior
      ..dispose(state, system)
      ..tearDown();
  }

  bool _runCommand(
    StateContext<State, System, R> context,
    CommandContext<State, System, R> commandContext,
  ) {
    final state = context.state;
    final command = commandContext.command..initialize(random);
    if (command.requires(state)) {
      final result = commandContext.run(context.system);
      if (command.ensures(state, result)) {
        return true;
      } else {
        throw PropertyException('postcondition is not satisfied');
      }
    } else {
      throw PropertyException('precondition is not satisfied');
    }
  }
}

final class _StatefulPropertyShrinker<State, System, R> {
  _StatefulPropertyShrinker(
    this.propertyContext,
    this.originalState,
    this.originalSystem,
    this.originalSequence,
  );

  final StatefulPropertyContext<State, System, R> propertyContext;
  final State originalState;
  final System originalSystem;
  final TraversalSequence<State, System, R> originalSequence;
  Exception? lastException;

  StatefulProperty<State, System, R> get property => propertyContext.property;

  Behavior<State, System, R> get behavior => propertyContext.behavior;

  StatefulShrinkingResult<State, System, R> shrink() {
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

  TraversalSequence<State, System, R> _checkPartialSequences(
    TraversalSequence<State, System, R> baseSequence,
  ) {
    propertyContext.shrinkCycle = 0;
    var previousSequences = <TraversalSequence<State, System, R>>[];
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

  TraversalSequence<State, System, R> _checkReducedSequences(
    TraversalSequence<State, System, R> baseSequence,
  ) {
    final commandTypeSet = <String>{};
    for (final step in baseSequence.steps) {
      commandTypeSet.add(step.context.command.description);
    }

    var minShrunkSequence = baseSequence;
    for (final target in commandTypeSet) {
      if (!_hasShrinkCycle) {
        break;
      }

      final shrunkSequence = TraversalSequence<State, System, R>();
      for (var i = 0; i < minShrunkSequence.steps.length; i++) {
        final step = minShrunkSequence.steps[i];
        if (step.context.command.description != target) {
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

  bool _checkShrunkSequence(TraversalSequence<State, System, R> sequence,
      {required String stepType}) {
    behavior.setUp();
    final state = behavior.createState();
    final system = behavior.createSystem(state);
    final stateContext =
        StateContext(state, system, property, propertyContext.test);
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
      printVerbose('Shrink $stepType step ${i + 1}: '
          '${step.context.command.description}');
      try {
        step.context.useCache = true;
        stateContext.runCommand(step.context);
      } on Exception catch (e) {
        printVerbose('  Error: $e');
        if (i + 1 < sequence.steps.length) {
          sequence.truncateSteps(i + 1);
        }
        lastException = e;

        property._disposeBehavior(behavior, state, system);
        return false;
      }
    }
    property._disposeBehavior(behavior, state, system);
    return true;
  }

  StateContext<State, System, R>? _checkValues(
    TraversalSequence<State, System, R> sequence,
  ) {
    var allShrinkDone = false;
    StateContext<State, System, R>? shrunkContext;
    while (_hasShrinkCycle && !allShrinkDone) {
      printVerbose('Shrink cycle ${_shrinkCycle + 1}');
      behavior.setUp();
      final state = propertyContext.behavior.createState();
      final system = propertyContext.behavior.createSystem(state);
      final stateContext =
          StateContext(state, system, property, propertyContext.test);
      allShrinkDone = true;
      for (var i = 0; i < sequence.steps.length; i++) {
        final step = sequence.steps[i];
        final context = step.context;
        printVerbose(
            'Shrink value step ${i + 1}: ${context.command.description}');
        try {
          if (context.nextShrink()) {
            allShrinkDone = false;
          }
          stateContext.runCommand(context);
        } on Exception catch (e) {
          printVerbose('  Error: $e');
          lastException = e;
          context.failShrunk();
          shrunkContext = stateContext;
          break;
        }
      }
      property._disposeBehavior(behavior, state, system);
      propertyContext.shrinkCycle++;
    }
    return shrunkContext;
  }
}

final class StatefulShrinkingResult<State, System, R> {
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
  final TraversalSequence<State, System, R> originalSequence;
  final State falsifyingState;
  final System falsifyingSystem;
  final TraversalSequence<State, System, R> falsifyingSequence;
  final Exception? exception;
}

/// A falsifying example of a stateful property.
///
/// See also:
/// - [runBehavior], runs a stateful test according to the behavior.
/// - [StatefulExampleStep], a step in a stateful example.
final class StatefulFalsifyingExample<State, System, R> {
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
  final List<StatefulExampleStep<State, System, R>> originalSteps;

  /// The state in which the failure was found after shrinking.
  final State falsifyingState;

  /// The system in which the failure was found after shrinking.
  final System falsifyingSystem;

  /// The steps that led to the failure after shrinking.
  final List<StatefulExampleStep<State, System, R>> falsifyingSteps;

  /// The exception that occurred during the initial failure or shrinking.
  final Exception? exception;
}

/// A step in a stateful example.
///
/// See also:
/// - [StatefulFalsifyingExample], a falsifying example of a stateful property.
final class StatefulExampleStep<State, System, R> {
  /// @nodoc
  @protected
  StatefulExampleStep(this.number, this.command, this.value);

  /// @nodoc
  @protected
  @internal
  static List<StatefulExampleStep<State, System, R>>
      fromSequence<State, System, R>(
    TraversalSequence<State, System, R> sequence,
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

  /// The number of the step.
  final int number;

  /// The command that was run in this step.
  final Command<State, System, R> command;

  /// The value that was used in this step.
  final dynamic value;
}
