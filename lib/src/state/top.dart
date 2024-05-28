import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:meta/meta.dart';

void forAllStates<State, System>(
  Behavior<State, System> behavior,
  void Function(State, System) body, {
  int? maxExamples,
  int? maxTries,
  int? maxShrinkingTries,
  RandomContext? random,
  int? seed,
  GenerationPolicy? generationPolicy,
  ShrinkingPolicy? shrinkingPolicy,
  EdgeCasePolicy? edgeCasePolicy,
  int? maxStatefulCycles,
  int? maxStatefulSteps,
  void Function()? setUp,
  void Function()? tearDown,
  void Function(State, System)? onGenerate,
  void Function(State, System)? onShrink,
  void Function(State, System)? onFalsify,
  bool? ignoreFalsify,
  @internal void Function(void Function())? onCheck,
}) {
  final property = StatefulProperty(
    behavior,
    body,
    settings: PropertySettings<State, System>(
      maxExamples: maxExamples,
      maxTries: maxTries,
      maxShrinkingTries: maxShrinkingTries,
      random: random,
      seed: seed,
      generationPolicy: generationPolicy,
      shrinkingPolicy: shrinkingPolicy,
      edgeCasePolicy: edgeCasePolicy,
      maxStatefulCycles: maxStatefulCycles,
      maxStatefulSteps: maxStatefulSteps,
      onGenerate: onGenerate,
      onShrink: onShrink,
      onFalsify: onFalsify,
      ignoreFalsify: ignoreFalsify,
    ),
    setUp: setUp,
    tearDown: tearDown,
    onCheck: onCheck,
  );
  PropertyTestManager.addProperty(property);
}
