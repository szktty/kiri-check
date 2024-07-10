import 'package:kiri_check/kiri_check.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

@isTest
void testForAll<T>(
  Arbitrary<T> arbitrary,
  void Function(T) block, {
  int? maxExamples,
  int? maxTries,
  int? maxShrinkingTries,
  int? seed,
  GenerationPolicy? generationPolicy,
  ShrinkingPolicy? shrinkingPolicy,
  EdgeCasePolicy? edgeCasePolicy,
  void Function()? setUp,
  void Function()? tearDown,
  void Function()? setUpAll,
  void Function(List<T>)? tearDownAll,
  void Function(T)? onGenerate,
  void Function(T)? onShrink,
  void Function(T)? onFalsify,
  bool? ignoreFalsify,
  double? variousRatio = 0.7,
}) {
  final examples = <T>[];
  var hasShrink = false;

  void testTearDownAll() {
    if (variousRatio != null) {
      final examplesSet = examples.toSet();
      final expected = (variousRatio * 100).toInt();
      final actual = ((examplesSet.length / examples.length) * 100).toInt();
      expect(
        examples.toSet().length > examples.length * variousRatio,
        isTrue,
        reason:
            'generated ${examples.length} examples are not various ${examplesSet.length} '
            '(actual $actual%, expected $expected%)',
      );
    }
    tearDownAll?.call(examples);
  }

  forAll(
    arbitrary,
    (example) {
      if (!hasShrink) {
        examples.add(example);
      }
      return block(example);
    },
    maxExamples: maxExamples,
    maxTries: maxTries,
    maxShrinkingTries: maxShrinkingTries,
    seed: seed,
    generationPolicy: generationPolicy,
    shrinkingPolicy: shrinkingPolicy,
    edgeCasePolicy: edgeCasePolicy,
    setUp: setUp,
    tearDown: tearDown,
    setUpAll: setUpAll,
    tearDownAll: testTearDownAll,
    onGenerate: onGenerate,
    onShrink: (example) {
      hasShrink = true;
      onShrink?.call(example);
    },
    onFalsify: onFalsify,
    ignoreFalsify: ignoreFalsify,
  );
}
