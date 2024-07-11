import 'package:kiri_check/src/property_settings.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// Global test settings.
abstract class KiriCheck {
  /// The maximum number of examples to generate and test.
  static int get maxExamples => Settings.shared.maxExamples;

  static set maxExamples(int value) => Settings.shared.maxExamples = value;

  /// The maximum number of attempts to find a valid example if the first try doesn't meet the property requirements.
  static int get maxTries => Settings.shared.maxTries;

  static set maxTries(int value) => Settings.shared.maxTries = value;

  /// The maximum number of attempts to shrink a failing example to its simplest form.
  static int get maxShrinkingTries => Settings.shared.maxShrinkingTries;

  static set maxShrinkingTries(int value) =>
      Settings.shared.maxShrinkingTries = value;

  /// The seed value for the random to ensure reproducibility of tests.
  static int? get seed => Settings.shared.seed;

  static set seed(int? value) => Settings.shared.seed = value;

  /// The policy for generating examples.
  static GenerationPolicy get generationPolicy =>
      Settings.shared.generationPolicy;

  static set generationPolicy(GenerationPolicy value) =>
      Settings.shared.generationPolicy = value;

  /// The policy for shrinking failing examples.
  static ShrinkingPolicy get shrinkingPolicy => Settings.shared.shrinkingPolicy;

  static set shrinkingPolicy(ShrinkingPolicy value) =>
      Settings.shared.shrinkingPolicy = value;

  /// The policy for including or excluding edge cases in the generated examples.
  static EdgeCasePolicy get edgeCasePolicy => Settings.shared.edgeCasePolicy;

  static set edgeCasePolicy(EdgeCasePolicy value) =>
      Settings.shared.edgeCasePolicy = value;

  /// The maximum number of cycles to run for stateful properties.
  static int get maxStatefulCycles => Settings.shared.maxStatefulCycles;

  static set maxStatefulCycles(int value) =>
      Settings.shared.maxStatefulCycles = value;

  /// The maximum number of steps to run for stateful properties.
  static int get maxStatefulSteps => Settings.shared.maxStatefulSteps;

  static set maxStatefulSteps(int value) =>
      Settings.shared.maxStatefulSteps = value;

  /// The maximum number of attempts to find a valid command for stateful properties.
  static int get maxStatefulCommandTries =>
      Settings.shared.maxStatefulCommandTries;

  static set maxStatefulCommandTries(int value) =>
      Settings.shared.maxStatefulCommandTries = value;

  /// The maximum number of attempts to shrink a failing stateful example to its simplest form.
  static int get maxStatefulShrinkingCycles =>
      Settings.shared.maxStatefulShrinkingCycles;

  /// The timeout for each stateful cycle.
  static Timeout get statefulCycleTimeout =>
      Settings.shared.statefulCycleTimeout;

  static set statefulCycleTimeout(Timeout value) =>
      Settings.shared.statefulCycleTimeout = value;

  /// Sets a timeout for the test. If the test runs longer, it will be marked as failed.
  static Timeout? get timeout => Settings.shared.timeout;

  static set timeout(Timeout? value) => Settings.shared.timeout = value;

  /// The verbosity level for the test output.
  static Verbosity get verbosity => Settings.shared.verbosity;

  static set verbosity(Verbosity value) => Settings.shared.verbosity = value;
}

/// The verbosity level for the test progress.
enum Verbosity {
  /// No output.
  quiet,

  /// Print information.
  normal,

  /// Print verbose information about the test progress.
  /// This includes generated examples and shrinking steps.
  verbose,

  /// Print debug information.
  debug;

  @internal
  int get value {
    switch (this) {
      case Verbosity.quiet:
        return 0;
      case Verbosity.normal:
        return 1;
      case Verbosity.verbose:
        return 2;
      case Verbosity.debug:
        return 3;
    }
  }

  int compareTo(Verbosity other) => value.compareTo(other.value);
}

final class Settings {
  Settings({
    int? maxTries,
    int? maxShrinkingTries,
    int? maxExamples,
    this.seed,
    GenerationPolicy? generationPolicy,
    ShrinkingPolicy? shrinkingPolicy,
    EdgeCasePolicy? edgeCasePolicy,
    int? maxStatefulCycles,
    int? maxStatefulSteps,
    int? maxStatefulCommandTries,
    int? maxStatefulShrinkingCycles,
    Timeout? statefulCycleTimeout,
    this.timeout,
    Verbosity? verbosity,
  }) {
    this.maxTries = maxTries ?? 100;
    this.maxShrinkingTries = maxShrinkingTries ?? 100;
    this.maxExamples = maxExamples ?? 100;
    this.generationPolicy = generationPolicy ?? GenerationPolicy.auto;
    this.shrinkingPolicy = shrinkingPolicy ?? ShrinkingPolicy.bounded;
    this.edgeCasePolicy = edgeCasePolicy ?? EdgeCasePolicy.mixin;
    this.maxStatefulCycles = maxStatefulCycles ?? 100;
    this.maxStatefulSteps = maxStatefulSteps ?? 100;
    this.maxStatefulCommandTries = maxStatefulCommandTries ?? 100;
    this.maxStatefulShrinkingCycles = maxStatefulShrinkingCycles ?? 100;
    this.statefulCycleTimeout =
        statefulCycleTimeout ?? const Timeout(Duration(seconds: 30));
    this.verbosity = verbosity ?? Verbosity.normal;
  }

  late int maxTries;
  late int maxShrinkingTries;
  late int maxExamples;
  int? seed;
  late GenerationPolicy generationPolicy;
  late ShrinkingPolicy shrinkingPolicy;
  late EdgeCasePolicy edgeCasePolicy;
  late int maxStatefulCycles;
  late int maxStatefulSteps;
  late int maxStatefulCommandTries;
  late int maxStatefulShrinkingCycles;
  late Timeout statefulCycleTimeout;
  Timeout? timeout;
  late Verbosity verbosity;

  static Settings shared = Settings();
}

void _printVerbosity(Verbosity verbosity, Object message) {
  if (Settings.shared.verbosity.compareTo(verbosity) >= 0) {
    if (message is Function) {
      print((message as dynamic Function()).call());
    } else {
      print(message);
    }
  }
}

void printNormal(Object message) {
  _printVerbosity(Verbosity.normal, message);
}

void printVerbose(Object message) {
  _printVerbosity(Verbosity.verbose, message);
}

void printDebug(Object message) {
  _printVerbosity(Verbosity.debug, message);
}
