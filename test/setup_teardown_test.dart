import 'package:test/test.dart';
import 'package:kiri_check/kiri_check.dart';

void main() {
  const n = 100;
  var setUpForAllCalls = 0;
  var tearDownForAllCalls = 0;
  var setUpAllOfForAllCalls = 0;
  var tearDownAllOfForAllCalls = 0;

  // TODO: addTearDownCurrentForAll

  setUpForAll(() {
    setUpForAllCalls++;
  });

  tearDownForAll(() {
    expect(setUpForAllCalls, equals(tearDownForAllCalls + 1));
    tearDownForAllCalls++;
  });

  tearDownAll(() {
    expect(setUpForAllCalls, n);
    expect(tearDownForAllCalls, n);
    print('setUpForAllCalls: $setUpForAllCalls');
    print('tearDownForAllCalls: $tearDownForAllCalls');
    print('setUpAllOfForAllCalls: $setUpAllOfForAllCalls');
    print('tearDownAllOfForAllCalls: $tearDownAllOfForAllCalls');
  });

  property('setUp and tearDown', () {
    var setUpCurrentForAllCalls = 0;
    var tearDownCurrentForAllCalls = 0;

    forAll(
      null_(),
      (value) {},
      maxExamples: n,
      setUp: () {
        setUpCurrentForAllCalls++;
      },
      tearDown: () {
        expect(setUpCurrentForAllCalls, equals(tearDownCurrentForAllCalls + 1));
        tearDownCurrentForAllCalls++;
      },
      setUpAll: () {
        setUpAllOfForAllCalls++;
      },
      tearDownAll: () {
        expect(setUpCurrentForAllCalls, equals(n));
        expect(tearDownCurrentForAllCalls, equals(n));
        expect(setUpAllOfForAllCalls, equals(tearDownAllOfForAllCalls + 1));
        tearDownAllOfForAllCalls++;
      },
    );
  });
}
