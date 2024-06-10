import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/state/behavior.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:test/scaffolding.dart';

/// Runs a stateful test.
///
/// Parameters:
///
///   - `behavior`: The behavior to test.
///   - `seed`: The seed to use for the random number generator.
///      examples.
///   - `maxCycles`: The maximum number of cycles to check.
///   - `maxSteps`: The maximum number of steps of each cycle.
///   - `maxCommandTries`: The maximum number of attempts to generate commands.
///   - `maxShrinkingTries`: The maximum number of attempts to shrink failing
///     examples.
///   - `maxShrinkingCycles`: The maximum number of shrinking cycles.
///   - `cycleTimeout`: The timeout for each cycle.
///   - `setUp`: A function to run before each test case.
///   - `tearDown`: A function to run after each test case.
///   - `onDispose`: A callback function that is called when state is disposed.
///   - `onFalsify`: A callback function that is called when a falsifying
///     example is found.
///   - `ignoreFalsify`: If set to true, the test will not be marked as failed even if
///     a counterexample that falsifies the property is found. This allows the test to
///     continue executing and attempting to verify the property with other examples,
///     useful for logging or analysis purposes.
void runBehavior<State, System, R>(
  Behavior<State, System, R> behavior, {
  int? seed,
  int? maxCycles,
  int? maxSteps,
  int? maxCommandTries,
  int? maxShrinkingTries,
  int? maxShrinkingCycles,
  Timeout? cycleTimeout,
  void Function()? setUp,
  void Function()? tearDown,
  void Function(Behavior<State, System, R>, State, System)? onDispose,
  void Function(StatefulFalsifyingExample<State, System, R>)? onFalsify,
  bool? ignoreFalsify,
}) {
  final property = StatefulProperty(
    behavior,
    settings: PropertySettings<State>(
      seed: seed,
      maxStatefulCycles: maxCycles,
      maxStatefulSteps: maxSteps,
      maxStatefulCommandTries: maxCommandTries,
      maxStatefulShrinkingCycles: maxShrinkingCycles,
      statefulCycleTimeout: cycleTimeout,
      ignoreFalsify: ignoreFalsify,
    ),
    setUp: setUp,
    tearDown: tearDown,
    onDispose: onDispose,
    onFalsify: onFalsify,
  );
  PropertyTestManager.addProperty(property);
}
