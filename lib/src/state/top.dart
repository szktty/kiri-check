import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';
import 'package:test/scaffolding.dart';

void forAllStates<State, System>(
  Behavior<State, System> behavior, {
  int? maxExamples,
  int? maxTries,
  int? maxShrinkingTries,
  int? seed,
  int? maxCycles,
  int? maxSteps,
  Timeout? cycleTimeout,
  void Function()? setUp,
  void Function()? tearDown,
  bool? ignoreFalsify,
  @internal void Function(void Function())? onCheck,
}) {
  final property = StatefulProperty(
    behavior,
    settings: PropertySettings<State>(
      maxExamples: maxExamples,
      maxTries: maxTries,
      maxShrinkingTries: maxShrinkingTries,
      seed: seed,
      maxStatefulCycles: maxCycles,
      maxStatefulSteps: maxSteps,
      statefulCycleTimeout: cycleTimeout,
      ignoreFalsify: ignoreFalsify,
    ),
    setUp: setUp,
    tearDown: tearDown,
    onCheck: onCheck,
  );
  PropertyTestManager.addProperty(property);
}
