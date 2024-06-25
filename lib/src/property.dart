import 'dart:collection';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/arbitrary/manipulation/filter.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/home.dart';
import 'package:kiri_check/src/property_settings.dart';
import 'package:kiri_check/src/random.dart';
import 'package:kiri_check/src/statistics.dart';
import 'package:test/test.dart';

abstract class Property<T> {
  Property({required this.settings, this.setUp, this.tearDown}) {
    random = settings.random ??
        RandomContextImpl(settings.seed ?? Settings.shared.seed);
    timeout = settings.timeout ?? Settings.shared.timeout;
    maxExamples = settings.maxExamples ?? Settings.shared.maxExamples;
    maxTries =
        math.max(settings.maxTries ?? Settings.shared.maxTries, maxExamples);
  }

  final PropertySettings<T> settings;
  late final RandomContext random;

  late final int maxTries;
  late final Timeout? timeout;
  late final int maxExamples;

  final void Function()? setUp;
  final void Function()? tearDown;

  void check(PropertyTest test);
}

// forAll()
final class StatelessProperty<T> extends Property<T> {
  StatelessProperty({
    required this.arbitrary,
    required this.block,
    required super.settings,
    super.setUp,
    super.tearDown,
  }) {
    _generationContext = null;
  }

  final ArbitraryInternal<T> arbitrary;

  final void Function(T) block;

  GenerationContextImpl<T>? _generationContext;
  final List<T> _generated = [];

  @override
  void check(PropertyTest test) {
    _generationContext = GenerationContextImpl(
      arbitrary: arbitrary,
      maxExamples: maxExamples,
      maxTries: maxTries,
      random: random,
      policy: settings.generationPolicy,
      edgeCasePolicy: settings.edgeCasePolicy,
    );
    _generated.clear();

    printVerbose('Generation policy: ${_generationContext!.policy}');
    printVerbose('Edge case policy: ${_generationContext!.edgeCasePolicy}');
    printVerbose('Shrinking policy: ${settings.shrinkingPolicy}');

    this.setUp?.call();

    _generationContext!.generate();

    T? falsified;
    for (var i = 0; i < _generationContext!.examples.length; i++) {
      final example = _generationContext!.examples[i];
      final description = arbitrary.describeExample(example);

      try {
        if (i == 0) {
          printVerbose('Trying first example: $description');
        } else {
          printVerbose('Trying example: $description');
        }
        settings.onGenerate?.call(example);
        block(example);
      } on Exception catch (e) {
        printVerbose('Falsifying example: $description');
        final context = ShrinkingContext(this);
        falsified = context.shrink(example, e);
        break;
      }
    }

    FalsifiedException<T>? exception;
    if (falsified != null) {
      settings.onFalsify?.call(falsified);
      final description = arbitrary.describeExample(falsified);
      if (settings.ignoreFalsify == false) {
        exception = FalsifiedException(
          example: falsified,
          description: description,
          seed: random.seed,
        );
      }
      printVerbose('Minimal failing example: $description');
    } else {
      printVerbose(
        'No falsifying examples found (${_generationContext!.examples.length} tests passed)',
      );
    }

    this.tearDown?.call();
    if (exception != null) {
      throw exception;
    }
  }
}

abstract class GenerationContext<T> {
  static const defaultGenerationPolicy = GenerationPolicy.auto;
  static const defaultEdgeCasePolicy = EdgeCasePolicy.mixin;

  RandomContext get random;

  GenerationPolicy get policy;

  EdgeCasePolicy get edgeCasePolicy;

  int get maxExamples;

  int get tries;

  int get maxTries;

  List<T> get examples;
}

final class GenerationContextImpl<T> extends GenerationContext<T> {
  GenerationContextImpl({
    required this.arbitrary,
    required this.maxExamples,
    required this.maxTries,
    required this.random,
    int? tries,
    GenerationPolicy? policy,
    EdgeCasePolicy? edgeCasePolicy,
  }) {
    _tries = tries ?? 0;
    this.policy = policy ?? GenerationContext.defaultGenerationPolicy;
    this.edgeCasePolicy =
        edgeCasePolicy ?? GenerationContext.defaultEdgeCasePolicy;
  }

  @override
  late final GenerationPolicy policy;

  @override
  late final EdgeCasePolicy edgeCasePolicy;

  @override
  final int maxExamples;

  @override
  late final RandomContext random;

  @override
  late final int maxTries;

  @override
  List<T> examples = [];

  @override
  int get tries => _tries;

  int _tries = 0;

  final ArbitraryInternal<T> arbitrary;

  void generate() {
    final needsEdgeCase = edgeCasePolicy != EdgeCasePolicy.none;
    final canExhaustive =
        arbitrary.isExhaustive && (arbitrary.enumerableCount <= maxExamples);

    final enumerations = <T>[];
    if ((policy == GenerationPolicy.auto && canExhaustive) ||
        policy == GenerationPolicy.exhaustive) {
      if (policy == GenerationPolicy.exhaustive) {
        if (!arbitrary.isExhaustive) {
          throw PropertyFailure('${arbitrary.runtimeType} is not exhaustive');
        }
        if (arbitrary.enumerableCount > maxExamples) {
          throw PropertyFailure(
            'max examples to generate is greater than unique examples of $arbitrary',
          );
        }
      }

      enumerations.addAll(arbitrary.generateExhaustive());
    }

    final edgeCases = arbitrary.edgeCases ?? [];
    _tries = enumerations.length + edgeCases.length;
    T? first;
    try {
      first = arbitrary.getFirst(random);
      _tries++;
    } on FilterException {
      first = null;
    }
    final fixed = _tries;

    final others = <T>[];
    if (policy != GenerationPolicy.exhaustive) {
      while (_tries < maxTries && fixed + others.length < maxExamples) {
        try {
          T value;
          if (policy == GenerationPolicy.random) {
            value = arbitrary.generateRandom(random);
          } else {
            value = arbitrary.generate(random);
          }

          if (!needsEdgeCase && edgeCases.contains(value)) {
            continue;
          } else {
            others.add(value);
          }
        } on FilterException {
          continue;
        }
        _tries++;
      }
    }

    if (first != null) {
      examples.add(first);
    }
    if (edgeCasePolicy == EdgeCasePolicy.first) {
      examples.addAll(edgeCases);
    }
    examples.addAll(enumerations);
    if (edgeCasePolicy == EdgeCasePolicy.mixin) {
      final mixin = (edgeCases + others)..shuffle(random);
      examples.addAll(mixin);
    } else {
      examples.addAll(others);
    }
  }
}

final class ShrinkingContext<T> {
  ShrinkingContext(this.property) {
    this.policy = property.settings.shrinkingPolicy ?? defaultPolicy;
    this.maxTries = property.settings.maxShrinkingTries ??
        (this.policy == ShrinkingPolicy.bounded
            ? ShrinkingContext.defaultMaxTries
            : null);
  }

  static const defaultPolicy = ShrinkingPolicy.bounded;
  static const defaultMaxTries = 100;

  final StatelessProperty<T> property;

  ArbitraryInternal<T> get arbitrary => property.arbitrary;

  RandomContext get random => property.random;

  late final ShrinkingPolicy policy;

  int steps = 0;

  late final int? maxTries;

  final List<T> tried = [];

  bool get isFull => policy == ShrinkingPolicy.full;

  T? shrink(T original, Exception exception) {
    if (policy == ShrinkingPolicy.off) {
      return null;
    }

    var counter = original;
    final queue = Queue<T>();
    var previousShrunk = <T>[];
    steps = 1;

    for (var tries = 0; isFull || tries < maxTries!; tries++) {
      if (queue.isEmpty) {
        final distance = arbitrary.calculateDistance(counter);
        if (distance.isEmpty) {
          return counter;
        } else {
          printVerbose('Shrinking step $steps');
          distance.granularity = steps;
          final values = arbitrary.shrink(counter, distance);
          if (values.isEmpty ||
              const DeepCollectionEquality().equals(values, previousShrunk)) {
            return counter;
          }
          queue.addAll(values);
          previousShrunk = values;
          steps++;
        }
      }

      final example = queue.removeFirst();
      tried.add(example);
      property.settings.onShrink?.call(example);

      final description = arbitrary.describeExample(example);
      try {
        printVerbose('Shrunk example to: $description');
        property.block(example);
      } on Exception {
        counter = example;
      }
    }

    return counter;
  }
}

enum PropertyResultStatus {
  success,
  failure,
  timeout,
}

final class PropertyTest {
  PropertyTest(
    this.description,
    this.body, {
    this.testOn,
    this.timeout,
    this.skip,
    this.tags,
    this.onPlatform,
    this.retry,
  });

  final Object? description;
  final dynamic Function() body;
  final String? testOn;
  final Timeout? timeout;
  final Object? skip;
  final Object? tags;
  final Map<String, dynamic>? onPlatform;
  final int? retry;

  final List<Property<dynamic>> properties = [];

  void add(Property<dynamic> property) {
    properties.add(property);
  }

  void register() {
    void body() {
      PropertyTestManager.runTest(this);
    }

    test(
      description,
      body,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry,
    );
  }
}

final class PropertyTestManager {
  PropertyTestManager._();

  static final _instance = PropertyTestManager._();

  final List<PropertyTest> _tests = [];

  PropertyTestRunner? _running;

  static void addTest(PropertyTest test) {
    _instance._tests.add(test);
    test.register();
  }

  static void addProperty(Property<dynamic> property) {
    final runner = _instance._running;
    if (runner == null) {
      throw StateError('No test run');
    }
    runner.test.add(property);
  }

  static void runTest(PropertyTest test) {
    _instance._running = PropertyTestRunner(test);
    _instance._running!.run();
  }
}

final class PropertyTestRunner {
  PropertyTestRunner(this.test);

  final PropertyTest test;

  void run() {
    test.body();
    for (final property in test.properties) {
      printVerbose('Max tries: ${property.maxTries}');
      printVerbose('Max examples: ${property.maxExamples}');
      printVerbose('Random seed: ${property.random.seed}');

      Statistics.initialize();

      Exception? exception;
      try {
        property.check(test);
      } on KiriCheckException catch (e) {
        exception = e;
      } on Exception {
        rethrow;
      }

      _printStatistics();

      printNormal('');

      if (exception != null) {
        print('Error: $exception');
      }
    }
  }

  void _printStatistics() {
    final result = Statistics.getResult();

    final metrics = result.getMetrics();
    if (metrics.isNotEmpty) {
      print('Collected test data:');
      for (final entry in metrics) {
        print(
          '  ${(entry.ratio * 10000).toInt() / 100}% (${entry.count}) ${entry.values.join(', ')}',
        );
      }
    }
  }
}
