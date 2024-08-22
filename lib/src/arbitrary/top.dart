import 'package:kiri_check/src/arbitrary.dart';
import 'package:kiri_check/src/arbitrary/combinator/build.dart';
import 'package:kiri_check/src/arbitrary/combinator/combine.dart';
import 'package:kiri_check/src/arbitrary/combinator/deck.dart';
import 'package:kiri_check/src/arbitrary/combinator/frequency.dart';
import 'package:kiri_check/src/arbitrary/combinator/one_of.dart';
import 'package:kiri_check/src/arbitrary/combinator/recursive.dart';
import 'package:kiri_check/src/arbitrary/core/binary.dart';
import 'package:kiri_check/src/arbitrary/core/constant.dart';
import 'package:kiri_check/src/arbitrary/core/constant_from.dart';
import 'package:kiri_check/src/arbitrary/core/datetime.dart';
import 'package:kiri_check/src/arbitrary/core/float.dart';
import 'package:kiri_check/src/arbitrary/core/integer.dart';
import 'package:kiri_check/src/arbitrary/core/list.dart';
import 'package:kiri_check/src/arbitrary/core/map.dart';
import 'package:kiri_check/src/arbitrary/core/runes.dart';
import 'package:kiri_check/src/arbitrary/core/set.dart';
import 'package:kiri_check/src/arbitrary/core/string.dart';
import 'package:kiri_check/src/util/character/character_set.dart';
import 'package:kiri_check/src/util/datetime.dart';
import 'package:timezone/timezone.dart' as tz;

/// Returns an arbitrary that generates a boolean value.
Arbitrary<bool> boolean() => ConstantFromArbitrary([true, false]);

/// Returns an arbitrary that generates a null value.
Arbitrary<Null> null_() => ConstantArbitrary(null);

/// Returns an arbitrary that generates a constant value.
Arbitrary<T> constant<T>(T value) => ConstantArbitrary(value);

/// Returns an arbitrary that generates a constant value from a list of values.
Arbitrary<T> constantFrom<T>(List<T> values) => ConstantFromArbitrary(values);

/// Returns an arbitrary that generates an integer value.
///
/// Parameters:
///  - `min`: The minimum value to generate.
///  - `max`: The maximum value to generate.
Arbitrary<int> integer({int? min, int? max}) =>
    IntArbitrary(min: min, max: max);

/// Returns an arbitrary that generates a double value.
///
/// Parameters:
/// - `min`: The minimum value to generate.
/// - `max`: The maximum value to generate.
/// - `minExcluded`: Whether the minimum value is excluded from the range.
/// - `maxExcluded`: Whether the maximum value is excluded from the range.
/// - `nan`: Whether to include NaN values.
/// - `infinity`: Whether to include infinity values.
Arbitrary<double> float({
  double? min,
  double? max,
  bool? minExcluded,
  bool? maxExcluded,
  bool? nan,
  bool? infinity,
}) =>
    FloatArbitrary(
      FloatStrategy(
        min: min,
        max: max,
        minExcluded: minExcluded,
        maxExcluded: maxExcluded,
        nan: nan,
        infinity: infinity,
      ),
    );

/// Returns an arbitrary that generates a string value.
///
/// Parameters:
/// - `minLength`: The minimum length of the string.
/// - `maxLength`: The maximum length of the string.
/// - `characterSet`: The character set to use when generating the string.
Arbitrary<String> string({
  int? minLength,
  int? maxLength,
  CharacterSet? characterSet,
}) =>
    StringArbitraries.string(
      minLength: minLength,
      maxLength: maxLength,
      characterSet: characterSet,
    );

/// Returns an arbitrary that generates a runes value.
///
/// Parameters:
/// - `minLength`: The minimum length of the runes.
/// - `maxLength`: The maximum length of the runes.
/// - `characterSet`: The character set to use when generating the runes.
Arbitrary<Runes> runes({
  int? minLength,
  int? maxLength,
  CharacterSet? characterSet,
}) =>
    RunesArbitraries.runes(
      minLength: minLength,
      maxLength: maxLength,
      characterSet: characterSet,
    );

/// Returns an arbitrary that generates a datetime value.
///
/// Parameters:
/// - `min`: The minimum value to generate. Timezone is ignored.
/// - `max`: The maximum value to generate. Timezone is ignored.
/// - `location`: The location to use when generating the DateTime.
Arbitrary<tz.TZDateTime> dateTime({
  DateTime? min,
  DateTime? max,
  String? location,
}) =>
    DateTimeArbitraries.dateTime(
      min: min,
      max: max,
      location: location,
    );

/// Returns an arbitrary that generates a nominal datetime value.
///
/// The arbitrary generates a datetime containing imaginary dates.
/// Imaginary dates are dates that don't exist in the real world, such as:
///
/// - February 29th in a non-leap year
/// - February 30th and 31st
/// - The 31st day of April, June, September, and November
///
/// Parameters:
/// - `min`: The minimum value to generate. Timezone is ignored.
/// - `max`: The maximum value to generate. Timezone is ignored.
/// - `location`: The location to use when generating the DateTime.
/// - `imaginary`: Whether to include imaginary dates.
Arbitrary<NominalDateTime> nominalDateTime({
  DateTime? min,
  DateTime? max,
  String? location,
  bool? imaginary,
}) =>
    DateTimeArbitraries.nominalDateTime(
      min: min,
      max: max,
      location: location,
      imaginary: imaginary,
    );

/// Returns an arbitrary that generates a binary value.
///
/// Parameters:
/// - `minLength`: The minimum length of the binary.
/// - `maxLength`: The maximum length of the binary.
Arbitrary<List<int>> binary({
  int? minLength,
  int? maxLength,
}) =>
    BinaryArbitraries.binary(
      minLength: minLength,
      maxLength: maxLength,
    );

/// Returns an arbitrary that generates a list value.
///
/// To disallow duplicates, specify `unique` or `uniqueBy`.
/// `unique` uses the `==` operator to determine if elements are equal.
/// To use any other method of comparison, specify `uniqueBy`.
///
/// Parameters:
/// - `element`: The arbitrary to use to generate the elements of the list.
/// - `minLength`: The minimum length of the list.
/// - `maxLength`: The maximum length of the list.
/// - `unique`: Whether the list should contain unique elements.
/// - `uniqueBy`: A function to determine uniqueness of elements.
Arbitrary<List<T>> list<T>(
  Arbitrary<T> element, {
  int? minLength,
  int? maxLength,
  bool? unique,
  bool Function(T, T)? uniqueBy,
}) =>
    ListArbitraries.list(
      element,
      minLength: minLength,
      maxLength: maxLength,
      unique: unique,
      uniqueBy: uniqueBy,
    );

/// Returns an arbitrary that generates a map value.
///
/// Parameters:
/// - `key`: The arbitrary to use to generate the keys of the map.
/// - `value`: The arbitrary to use to generate the values of the map.
/// - `minLength`: The minimum length of the map.
/// - `maxLength`: The maximum length of the map.
Arbitrary<Map<K, V>> map<K, V>(
  Arbitrary<K> key,
  Arbitrary<V> value, {
  int? minLength,
  int? maxLength,
}) =>
    MapArbitraries.map(
      key,
      value,
      minLength: minLength,
      maxLength: maxLength,
    );

/// Returns an arbitrary that generates a set value.
///
/// Parameters:
/// - `element`: The arbitrary to use to generate the elements of the set.
/// - `minLength`: The minimum length of the set.
/// - `maxLength`: The maximum length of the set.
Arbitrary<Set<T>> set<T>(
  Arbitrary<T> element, {
  int? minLength,
  int? maxLength,
}) =>
    SetArbitraries.set(
      element,
      minLength: minLength,
      maxLength: maxLength,
    );

/// Returns an arbitrary that generates a deck.
Arbitrary<Deck> deck() => DeckArbitraries.deck();

/// Returns an arbitrary that generates a value using the provided builder.
Arbitrary<T> build<T>(T Function() builder) =>
    BuildArbitraries.build<T>(builder);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
Arbitrary<(E1, E2)> combine2<E1, E2>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
) =>
    CombineArbitraries.combine2(a1, a2);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
/// - `a3`: The third arbitrary to combine.
Arbitrary<(E1, E2, E3)> combine3<E1, E2, E3>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
  Arbitrary<E3> a3,
) =>
    CombineArbitraries.combine3(a1, a2, a3);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
/// - `a3`: The third arbitrary to combine.
/// - `a4`: The fourth arbitrary to combine.
Arbitrary<(E1, E2, E3, E4)> combine4<E1, E2, E3, E4>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
  Arbitrary<E3> a3,
  Arbitrary<E4> a4,
) =>
    CombineArbitraries.combine4(a1, a2, a3, a4);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
/// - `a3`: The third arbitrary to combine.
/// - `a4`: The fourth arbitrary to combine.
/// - `a5`: The fifth arbitrary to combine.
Arbitrary<(E1, E2, E3, E4, E5)> combine5<E1, E2, E3, E4, E5>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
  Arbitrary<E3> a3,
  Arbitrary<E4> a4,
  Arbitrary<E5> a5,
) =>
    CombineArbitraries.combine5(a1, a2, a3, a4, a5);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
/// - `a3`: The third arbitrary to combine.
/// - `a4`: The fourth arbitrary to combine.
/// - `a5`: The fifth arbitrary to combine.
/// - `a6`: The sixth arbitrary to combine.
Arbitrary<(E1, E2, E3, E4, E5, E6)> combine6<E1, E2, E3, E4, E5, E6>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
  Arbitrary<E3> a3,
  Arbitrary<E4> a4,
  Arbitrary<E5> a5,
  Arbitrary<E6> a6,
) =>
    CombineArbitraries.combine6(a1, a2, a3, a4, a5, a6);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
/// - `a3`: The third arbitrary to combine.
/// - `a4`: The fourth arbitrary to combine.
/// - `a5`: The fifth arbitrary to combine.
/// - `a6`: The sixth arbitrary to combine.
/// - `a7`: The seventh arbitrary to combine.
Arbitrary<(E1, E2, E3, E4, E5, E6, E7)> combine7<E1, E2, E3, E4, E5, E6, E7>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
  Arbitrary<E3> a3,
  Arbitrary<E4> a4,
  Arbitrary<E5> a5,
  Arbitrary<E6> a6,
  Arbitrary<E7> a7,
) =>
    CombineArbitraries.combine7(a1, a2, a3, a4, a5, a6, a7);

/// Returns an arbitrary that combines two arbitraries.
///
/// Parameters:
/// - `a1`: The first arbitrary to combine.
/// - `a2`: The second arbitrary to combine.
/// - `a3`: The third arbitrary to combine.
/// - `a4`: The fourth arbitrary to combine.
/// - `a5`: The fifth arbitrary to combine.
/// - `a6`: The sixth arbitrary to combine.
/// - `a7`: The seventh arbitrary to combine.
/// - `a8`: The eighth arbitrary to combine.
Arbitrary<(E1, E2, E3, E4, E5, E6, E7, E8)>
    combine8<E1, E2, E3, E4, E5, E6, E7, E8>(
  Arbitrary<E1> a1,
  Arbitrary<E2> a2,
  Arbitrary<E3> a3,
  Arbitrary<E4> a4,
  Arbitrary<E5> a5,
  Arbitrary<E6> a6,
  Arbitrary<E7> a7,
  Arbitrary<E8> a8,
) =>
        CombineArbitraries.combine8(a1, a2, a3, a4, a5, a6, a7, a8);

/// Returns an arbitrary that generates a value from
/// one of the provided arbitraries.
///
/// Parameters:
/// - `arbitraries`: The list of arbitraries to choose from.
Arbitrary<dynamic> oneOf(List<Arbitrary<dynamic>> arbitraries) =>
    OneOfArbitraries.oneOf(arbitraries);

/// Returns an arbitrary that generates values based on weighted probabilities.
///
/// The probability of selecting each arbitrary is proportional to its weight
/// relative to the total weight.
///
/// Parameters:
/// - `arbitraries`: The list of pairs of weights and arbitraries.
Arbitrary<dynamic> frequency(List<(int, Arbitrary<dynamic>)> arbitraries) =>
    FrequencyArbitraries.frequency(arbitraries);

/// Returns an arbitrary that generates values for recursive data structures
/// using the provided `base` and `extend` functions.
///
/// The `extend` function is called with the result of the `base` function or
/// the last `extend` invocation, allowing for progressive construction
/// of complex data structures.
///
/// Parameters:
/// - `base`: A function that returns an arbitrary used for generating
///           the initial values at the base level.
/// - `extend`: A function that takes an arbitrary and returns a new arbitrary
///             based on it, used to extend the recursion.
/// - `maxDepth`: The maximum depth of recursion (default is 5).
///               Increasing this value can significantly increase the time
///               required for data generation.
Arbitrary<T> recursive<T>(
  Arbitrary<T> Function() base,
  Arbitrary<T> Function() Function(Arbitrary<T> Function()) extend, {
  int? maxDepth,
}) =>
    RecursiveArbitraries.recursive(
      base,
      extend,
      maxDepth: maxDepth,
    );
