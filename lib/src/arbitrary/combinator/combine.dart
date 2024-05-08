import 'package:collection/collection.dart';
import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/random.dart';

// ignore_for_file: null_check_on_nullable_type_parameter

final class CombinatorSet<R, E1, E2, E3, E4, E5, E6, E7, E8> {
  CombinatorSet(
    this.count,
    this.arbitrary1,
    this.arbitrary2,
    this.arbitrary3,
    this.arbitrary4,
    this.arbitrary5,
    this.arbitrary6,
    this.arbitrary7,
    this.arbitrary8,
    this.transformer2,
    this.transformer3,
    this.transformer4,
    this.transformer5,
    this.transformer6,
    this.transformer7,
    this.transformer8,
  ) {
    arbitraries = [
      arbitrary1,
      arbitrary2,
      if (arbitrary3 != null) arbitrary3!,
      if (arbitrary4 != null) arbitrary4!,
      if (arbitrary5 != null) arbitrary5!,
      if (arbitrary6 != null) arbitrary6!,
      if (arbitrary7 != null) arbitrary7!,
      if (arbitrary8 != null) arbitrary8!,
    ];
  }

  final int count;

  late final List<ArbitraryInternal<dynamic>> arbitraries;

  final ArbitraryInternal<E1> arbitrary1;
  final ArbitraryInternal<E2> arbitrary2;
  final ArbitraryInternal<E3>? arbitrary3;
  final ArbitraryInternal<E4>? arbitrary4;
  final ArbitraryInternal<E5>? arbitrary5;
  final ArbitraryInternal<E6>? arbitrary6;
  final ArbitraryInternal<E7>? arbitrary7;
  final ArbitraryInternal<E8>? arbitrary8;

  final R Function(E1, E2)? transformer2;
  final R Function(E1, E2, E3)? transformer3;
  final R Function(E1, E2, E3, E4)? transformer4;
  final R Function(E1, E2, E3, E4, E5)? transformer5;
  final R Function(E1, E2, E3, E4, E5, E6)? transformer6;
  final R Function(E1, E2, E3, E4, E5, E6, E7)? transformer7;
  final R Function(E1, E2, E3, E4, E5, E6, E7, E8)? transformer8;

  R transform(List<dynamic> values) {
    switch (count) {
      case 2:
        return transformer2!(values[0] as E1, values[1] as E2);
      case 3:
        return transformer3!(values[0] as E1, values[1] as E2, values[2] as E3);
      case 4:
        return transformer4!(
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
        );
      case 5:
        return transformer5!(
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
        );
      case 6:
        return transformer6!(
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
          values[5] as E6,
        );
      case 7:
        return transformer7!(
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
          values[5] as E6,
          values[6] as E7,
        );
      case 8:
        return transformer8!(
          values[0] as E1,
          values[1] as E2,
          values[2] as E3,
          values[3] as E4,
          values[4] as E5,
          values[5] as E6,
          values[6] as E7,
          values[7] as E8,
        );
      default:
        throw PropertyException('Invalid count: $count');
    }
  }
}

final class CombineArbitrary<R, E1, E2, E3, E4, E5, E6, E7, E8>
    extends ArbitraryBase<R> {
  CombineArbitrary(this._set);

  final CombinatorSet<R, E1, E2, E3, E4, E5, E6, E7, E8> _set;

  final Map<R, List<dynamic>> _formerMap = {};

  List<dynamic> _getFormer(R value) {
    final former = _formerMap[value];
    if (former == null) {
      throw ArgumentError('former value of $value is not found');
    }
    return former;
  }

  R _transform(List<dynamic> former) {
    final r = _set.transform(former);
    _formerMap[r] = former;
    return r;
  }

  @override
  int get enumerableCount => 0;

  @override
  List<R>? get edgeCases => null;

  @override
  bool get isExhaustive => false;

  @override
  String describeExample(R example) {
    final former = _getFormer(example);
    final buffer = StringBuffer('$example combined from (')
      ..write(
        _set.arbitraries
            .mapIndexed((i, g) => g.describeExample(former[i]))
            .join(', '),
      )
      ..write(')');
    return buffer.toString();
  }

  @override
  R getFirst(RandomContext random) =>
      _transform(_set.arbitraries.map((g) => g.getFirst(random)).toList());

  @override
  R generate(RandomContext random) =>
      _transform(_set.arbitraries.map((g) => g.generate(random)).toList());

  @override
  R generateRandom(RandomContext random) => _transform(
      _set.arbitraries.map((g) => g.generateRandom(random)).toList(),);

  @override
  ShrinkingDistance calculateDistance(R value) {
    final former = _getFormer(value);
    final distance = ShrinkingDistance(0);
    _set.arbitraries.forEachIndexed((i, g) {
      distance.addDimension(g.calculateDistance(former[i]));
    });
    return distance;
  }

  @override
  List<R> shrink(R value, ShrinkingDistance distance) {
    final n = (distance.granularity - 1) % _set.count;
    final depth = (distance.granularity - 1) ~/ _set.count + 1;
    final targetArbitrary = _set.arbitraries[n];
    final targetDistance = ShrinkingDistance(distance.dimensions[n].baseSize)
      ..granularity = depth;
    final former = _getFormer(value);
    final targetShrunk = targetArbitrary.shrink(former[n], targetDistance);
    final shrunk = targetShrunk.map((e) {
      final nextFormer = List.of(former);
      nextFormer[n] = e;
      return _transform(nextFormer);
    }).toList();
    return shrunk;
  }
}

abstract class CombineArbitraries {
  static Arbitrary<R> combine2<R, E1, E2>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    R Function(E1, E2) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, dynamic, dynamic, dynamic, dynamic, dynamic,
          dynamic>(
        CombinatorSet(
          2,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
          null,
          null,
          null,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<R> combine3<R, E1, E2, E3>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    R Function(E1, E2, E3) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, E3, dynamic, dynamic, dynamic, dynamic,
          dynamic>(
        CombinatorSet(
          3,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
          null,
          null,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<R> combine4<R, E1, E2, E3, E4>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    R Function(E1, E2, E3, E4) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, E3, E4, dynamic, dynamic, dynamic, dynamic>(
        CombinatorSet(
          4,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
          null,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<R> combine5<R, E1, E2, E3, E4, E5>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    R Function(E1, E2, E3, E4, E5) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, E3, E4, E5, dynamic, dynamic, dynamic>(
        CombinatorSet(
          5,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          a5 as ArbitraryInternal<E5>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
          null,
          null,
          null,
        ),
      );

  static Arbitrary<R> combine6<R, E1, E2, E3, E4, E5, E6>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    Arbitrary<E6> a6,
    R Function(E1, E2, E3, E4, E5, E6) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, E3, E4, E5, E6, dynamic, dynamic>(
        CombinatorSet(
          6,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          a5 as ArbitraryInternal<E5>,
          a6 as ArbitraryInternal<E6>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
          null,
          null,
        ),
      );

  static Arbitrary<R> combine7<R, E1, E2, E3, E4, E5, E6, E7>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    Arbitrary<E6> a6,
    Arbitrary<E7> a7,
    R Function(E1, E2, E3, E4, E5, E6, E7) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, E3, E4, E5, E6, E7, dynamic>(
        CombinatorSet(
          7,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          a5 as ArbitraryInternal<E5>,
          a6 as ArbitraryInternal<E6>,
          a7 as ArbitraryInternal<E7>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
          null,
        ),
      );

  static Arbitrary<R> combine8<R, E1, E2, E3, E4, E5, E6, E7, E8>(
    Arbitrary<E1> a1,
    Arbitrary<E2> a2,
    Arbitrary<E3> a3,
    Arbitrary<E4> a4,
    Arbitrary<E5> a5,
    Arbitrary<E6> a6,
    Arbitrary<E7> a7,
    Arbitrary<E8> a8,
    R Function(E1, E2, E3, E4, E5, E6, E7, E8) transformer,
  ) =>
      CombineArbitrary<R, E1, E2, E3, E4, E5, E6, E7, E8>(
        CombinatorSet(
          8,
          a1 as ArbitraryInternal<E1>,
          a2 as ArbitraryInternal<E2>,
          a3 as ArbitraryInternal<E3>,
          a4 as ArbitraryInternal<E4>,
          a5 as ArbitraryInternal<E5>,
          a6 as ArbitraryInternal<E6>,
          a7 as ArbitraryInternal<E7>,
          a8 as ArbitraryInternal<E8>,
          null,
          null,
          null,
          null,
          null,
          null,
          transformer,
        ),
      );
}
