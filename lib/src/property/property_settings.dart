import 'dart:async';

import 'package:kiri_check/src/property/home.dart';
import 'package:kiri_check/src/property/random.dart';
import 'package:kiri_check/src/property/top.dart';

import 'package:test/test.dart';

final class PropertySettings<T> {
  PropertySettings({
    this.maxExamples,
    this.maxTries,
    this.maxShrinkingTries,
    this.timeout,
    this.random,
    this.seed,
    this.generationPolicy,
    this.shrinkingPolicy,
    this.edgeCasePolicy,
    this.maxStatefulCycles,
    this.maxStatefulSteps,
    this.maxStatefulCommandTries,
    this.maxStatefulShrinkingCycles,
    this.statefulCycleTimeout,
    this.onGenerate,
    this.onShrink,
    this.onFalsify,
    bool? ignoreFalsify,
  }) {
    this.ignoreFalsify = ignoreFalsify ?? false;
  }

  final int? maxExamples;
  final int? maxTries;
  final int? maxShrinkingTries;
  final Timeout? timeout;
  final RandomContext? random;
  final int? seed;
  final GenerationPolicy? generationPolicy;
  final ShrinkingPolicy? shrinkingPolicy;
  final EdgeCasePolicy? edgeCasePolicy;
  final int? maxStatefulCycles;
  final int? maxStatefulSteps;
  final int? maxStatefulCommandTries;
  final int? maxStatefulShrinkingCycles;
  final Timeout? statefulCycleTimeout;
  final FutureOr<void> Function(T)? onGenerate;
  final FutureOr<void> Function(T)? onShrink;
  final FutureOr<void> Function(T)? onFalsify;
  late final bool ignoreFalsify;
}

/// An enum that represents the policy for generating values.
enum GenerationPolicy {
  /// Generates values exhaustively
  /// the range of data is smaller than the number of tries,
  /// and otherwise relies on the arbitrary.
  auto,

  /// Generates values exhaustively.
  exhaustive,

  /// Generates values randomly.
  random;
}

/// An enum that represents the policy for controlling the number of times
/// an example is attempted to be shrunk by the shrinker.
/// This policy dictates how the shrinker operates in terms of attempting to
/// find simpler failing examples.
enum ShrinkingPolicy {
  /// No shrinking will be performed.
  off,

  /// The shrinker will attempt to shrink an example a fixed number of times,
  /// as specified by the `maxShrinkingTries` of [KiriCheck] and [forAll].
  /// This provides  a bounded shrinking process, where the number of shrinking
  /// attempts is limited to prevent excessive computation time.
  /// The default value for attempts is 100.
  bounded,

  /// The shrinker will attempt to shrink an example until
  /// a specified timeout is reached, allowing for an exhaustive search for
  /// the simplest failing example within the time constraint.
  /// This mode enables the shrinker to continuously try reducing
  /// the example as much as possible, potentially leading to more insightful
  /// simplifications at the cost of longer execution time.
  full;
}

/// An enum that represents the policy for generating edge cases.
enum EdgeCasePolicy {
  /// No edge cases will be generated.
  none,

  /// Edge cases will be generated by mixing them with the regular examples.
  mixin,

  /// Only the first example will be considered as an edge case.
  first;
}