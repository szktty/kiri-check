import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';
import 'package:test/scaffolding.dart';

void runBehavior<State, System>(
  Behavior<State, System> behavior, {
  int? maxShrinkingTries,
  int? seed,
  int? maxCycles,
  int? maxSteps,
  int? maxCommandTries,
  int? maxShrinkingCycles,
  Timeout? cycleTimeout,
  void Function()? setUp,
  void Function()? tearDown,
  void Function(Behavior<State, System>, State, System)? onDispose,
  void Function(StatefulFalsifyingExample<State, System>)? onFalsify,
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
