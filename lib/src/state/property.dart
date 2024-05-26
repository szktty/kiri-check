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
    _checkSequences(test);
    tearDown?.call();
  }

  void _checkSequences(PropertyTest test) {
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
        final sequence = traversal.generateSequence();

        state.setUp();

        for (var i = 0; i < sequence.steps.length; i++) {
          final step = sequence.steps[i];
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
              TraversalSequence(sequence.steps.sublist(0, i + 1)),
            );
            final result = shrinker.shrink();

            print('Falsified example sequence:');
            for (var i = 0; i < result.sequence.steps.length; i++) {
              final step = result.sequence.steps[i];
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
    this.originalSequence,
  );

  final StatefulPropertyContext<T> propertyContext;
  final StateContext<T> stateContext;
  final TraversalSequence<T> originalSequence;

  StatefulProperty<T> get property => propertyContext.property;

  StatefulShrinkingResult<T> shrink() {
    final partial = _checkPartialSequences(originalSequence);
    final reduced = _checkReducedSequences(partial);
    _checkValues(reduced);
    return StatefulShrinkingResult(stateContext.state, reduced);
  }

  int get _shrinkCycle => propertyContext.shrinkCycle;

  bool get _hasShrinkCycle =>
      _shrinkCycle < propertyContext.property.maxShrinkingCycles;

  TraversalSequence<T> _checkPartialSequences(
      TraversalSequence<T> baseSequence) {
    propertyContext.shrinkCycle = 0;
    var previousSequences = <TraversalSequence<T>>[];
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
  TraversalSequence<T> _checkReducedSequences(
      TraversalSequence<T> baseSequence) {
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

      final shrunkSequence = TraversalSequence<T>();
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

  bool _checkShrunkSequence(TraversalSequence<T> sequence) {
    print('Check shrunk sequence: ${sequence.steps.length} steps');
    final state = propertyContext.behavior.createState()
      ..random = property.random;
    final stateContext = StateContext(state, property, propertyContext.test);
    for (var i = 0; i < sequence.steps.length; i++) {
      final step = sequence.steps[i];
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

  void _checkValues(TraversalSequence<T> sequence) {
    var allShrinkDone = false;
    while (_hasShrinkCycle && !allShrinkDone) {
      print('Shrink cycle ${_shrinkCycle + 1}');
      final state = propertyContext.behavior.createState()
        ..random = property.random;
      final stateContext = StateContext(state, property, propertyContext.test);
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
  StatefulShrinkingResult(this.state, this.sequence);

  final T state;
  final TraversalSequence<T> sequence;
}
