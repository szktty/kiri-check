import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/property.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/statistics.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// Executes a property-based test, acting as a wrapper around the `test` function
/// from the `test` package.
///
/// To perform property testing, use `forAll` within the body of `check` to specify
/// properties that your code must satisfy. `forAll` generates inputs based on provided
/// constraints and repeatedly executes the test body with those inputs to verify the
/// specified properties across a wide range of cases.
///
/// Parameters:
///
///   - `description`: A description of the test, which can help identify the test
///     when it's run or when it fails.
///   - `body`: The test body as a function, where property tests are defined using
///     `forAll`.
///   - `testOn`: Specifies which platforms the test should run on.
///   - `timeout`: Sets a timeout for the test. If the test runs longer, it will be
///     marked as failed.
///   - `skip`: Allows skipping the test. Can be a boolean or a string explaining why
///     the test is skipped.
///   - `tags`: Used to tag the test with one or more labels, facilitating selective
///     test runs.
///   - `onPlatform`: Specifies overrides for `timeout` or `skip` on a per-platform
///     basis.
@isTest
void property(
  Object? description,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  Object? skip,
  Object? tags,
  Map<String, dynamic>? onPlatform,
}) {
  final test = PropertyTest(
    description,
    body,
    testOn: testOn,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
  );
  PropertyTestManager.addTest(test);
}

/// Executes a test for all generated inputs that meet the specified properties,
/// leveraging an arbitrary to produce a wide range of inputs.
///
/// Parameters:
///   - `arbitrary`: An arbitrary instance used to generate test cases. This is where
///     the type of input and how it's generated are defined.
///   - `block`: The test block to execute with each generated input. This function
///     is where you define the assertions or checks to validate the properties of your code.
///   - `maxExamples`: The maximum number of examples to generate and test.
///   - `maxTries`: The maximum number of attempts to find a valid example if the
///     first try doesn't meet the property requirements.
///   - `maxShrinkingTries`: The maximum number of attempts to shrink a failing example
///     to its simplest form.
///   - `random`: A custom random for generating examples.
///   - `seed`: A seed value for the random to ensure reproducibility of tests.
///   - `generationPolicy`: The policy for generating examples.
///   - `shrinkingPolicy`: The policy for shrinking failing examples.
///   - `edgeCasePolicy`: The policy for including or excluding edge cases in the
///     generated examples.
///   - `setUp`: A function to run before each test case.
///   - `tearDown`: A function to run after each test case.
///   - `onGenerate`: A callback function that is called after each example is generated,
///     allowing inspection of the generated input.
///   - `onShrink`: A callback function that is called after each shrink operation,
///     useful for logging or analysis.
///   - `onFalsify`: A callback function that is called when a counterexample is found,
///     before any shrinking has occurred.
///   - `ignoreFalsify`: If set to true, the test will not be marked as failed even if
///     a counterexample that falsifies the property is found. This allows the test to
///     continue executing and attempting to verify the property with other examples,
///     useful for logging or analysis purposes.
void forAll<T>(
  Arbitrary<T> arbitrary,
  void Function(T) block, {
  int? maxExamples,
  int? maxTries,
  int? maxShrinkingTries,
  RandomContext? random,
  int? seed,
  GenerationPolicy? generationPolicy,
  ShrinkingPolicy? shrinkingPolicy,
  EdgeCasePolicy? edgeCasePolicy,
  void Function()? setUp,
  void Function()? tearDown,
  void Function(T)? onGenerate,
  void Function(T)? onShrink,
  void Function(T)? onFalsify,
  bool? ignoreFalsify,
}) {
  final property = StatelessProperty(
    arbitrary: arbitrary as ArbitraryInternal<T>,
    settings: PropertySettings<T>(
      maxExamples: maxExamples,
      maxTries: maxTries,
      maxShrinkingTries: maxShrinkingTries,
      random: random,
      seed: seed,
      generationPolicy: generationPolicy,
      shrinkingPolicy: shrinkingPolicy,
      edgeCasePolicy: edgeCasePolicy,
      onGenerate: onGenerate,
      onShrink: onShrink,
      onFalsify: onFalsify,
      ignoreFalsify: ignoreFalsify,
    ),
    block: block,
    setUp: setUp,
    tearDown: tearDown,
  );
  PropertyTestManager.addProperty(property);
}

/// Collects the given test data.
///
/// The aggregated result will be displayed at the end of the test.
void collect(
  Object value, [
  Object? value1,
  Object? value2,
  Object? value3,
  Object? value4,
  Object? value5,
  Object? value6,
  Object? value7,
  Object? value8,
]) {
  Statistics.collect([
    value,
    if (value1 != null) value1,
    if (value2 != null) value2,
    if (value3 != null) value3,
    if (value4 != null) value4,
    if (value5 != null) value5,
    if (value6 != null) value6,
    if (value7 != null) value7,
    if (value8 != null) value8,
  ]);
}
