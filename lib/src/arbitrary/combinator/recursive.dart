import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/home.dart';
import 'package:kiri_check/src/random.dart';

abstract class RecursiveArbitraries {
  static Arbitrary<T> recursive<T>(
    Arbitrary<T> Function() base,
    Arbitrary<T> Function() Function(Arbitrary<T> Function()) extend, {
    int? maxDepth,
  }) =>
      RecursiveArbitrary(
        base,
        extend,
        maxDepth: maxDepth,
      );
}

class RecursiveArbitrary<T> extends ArbitraryBase<T> {
  RecursiveArbitrary(
    this.base,
    this.extend, {
    int? maxDepth,
  }) {
    this.maxDepth = maxDepth ?? 5;
    _current = null;
    _random = null;
    _f = null;
  }

  final Arbitrary<T> Function() base;

  final Arbitrary<T> Function() Function(Arbitrary<T> Function()) extend;

  late final int maxDepth;

  ArbitraryInternal<T>? _current;
  final Map<dynamic, ArbitraryInternal<T>> _generated = {};
  int _depth = 0;
  RandomContext? _random;
  T Function(ArbitraryInternal<T>, RandomContext)? _f;

  @override
  int get enumerableCount => 0;

  @override
  bool get isExhaustive => false;

  @override
  List<T>? get edgeCases => null;

  @override
  T getFirst(RandomContext random) {
    return _generateValue(random, (a, r) => a.getFirst(r));
  }

  @override
  T generateRandom(RandomContext random) {
    return _generateValue(random, (a, r) => a.generateRandom(r));
  }

  @override
  T generate(RandomContext random) {
    return _generateValue(random, (a, r) => a.generate(r));
  }

  T _generateValue(
    RandomContext random,
    T Function(ArbitraryInternal<T>, RandomContext) f, {
    int? depth,
  }) {
    if (_current == null) {
      _depth = depth ?? random.nextInt(maxDepth);
      _current = _generateArbitrary(_depth);
    }
    _random = random;
    _f = f;
    final value = f(_current!, random);
    _generated[value] = _current!;
    return value;
  }

  ArbitraryInternal<T> _generateArbitrary(int depth) {
    printVerbose('Generating recursion depth: $depth');
    if (depth == 0) {
      return base() as ArbitraryInternal<T>;
    } else {
      var current = base;
      for (var i = 0; i <= _depth; i++) {
        current = extend(current);
      }
      return current() as ArbitraryInternal<T>;
    }
  }

  bool _shrinkDepth = true;

  @override
  ShrinkingDistance calculateDistance(T value) {
    return _generated[value]!.calculateDistance(value);
  }

  @override
  List<T> shrink(T value, ShrinkingDistance distance) {
    if (_shrinkDepth) {
      _depth--;
      _current = _generateArbitrary(_depth);
      _shrinkDepth = false;
      final values = <T>[];
      for (var i = 0; i < 10; i++) {
        final value = _f!(_current!, _random!);
        _generated[value] = _current!;
        values.add(value);
      }
      return values;
    } else {
      _shrinkDepth = true;
      _current = _generated[value];
      final shrunk = _current!.shrink(value, distance);
      for (final shrunkValue in shrunk) {
        _generated[shrunkValue] = _current!;
      }
      return shrunk;
    }
  }

  @override
  String describeExample(T example) {
    return _generated[example]!.describeExample(example);
  }
}
