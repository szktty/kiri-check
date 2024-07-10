import 'package:test/test.dart';
import 'package:kiri_check/kiri_check.dart';

void main() {
  var n = 0;
  var setUpForAllCalls = 0;
  var tearDownForAllCalls = 0;
  var setUpAllOfForAllCalls = 0;
  var tearDownAllOfForAllCalls = 0;

  // TODO: addTearDownCurrentForAll

  setUpForAll(() {
    setUpForAllCalls++;
  });

  tearDownForAll(() {
    expect(setUpForAllCalls, tearDownForAllCalls + 1);
    tearDownForAllCalls++;
  });

  tearDownAll(() {
    print('setUpForAllCalls: $setUpForAllCalls');
    print('tearDownForAllCalls: $tearDownForAllCalls');
    expect(setUpForAllCalls, n);
    expect(tearDownForAllCalls, n);
  });

  property('setUp and tearDown', () {
    var setUpCurrentForAllCalls = 0;
    var tearDownCurrentForAllCalls = 0;

    forAll(
      null_(),
      (value) {
        n++;
      },
      maxExamples: 100,
      setUp: () {
        setUpCurrentForAllCalls++;
      },
      tearDown: () {
        expect(setUpCurrentForAllCalls, tearDownCurrentForAllCalls + 1);
        tearDownCurrentForAllCalls++;
      },
      setUpAll: () {
        expect(setUpCurrentForAllCalls, 0);
        expect(tearDownCurrentForAllCalls, 0);
        setUpAllOfForAllCalls++;
      },
      tearDownAll: () {
        expect(setUpCurrentForAllCalls, n);
        expect(tearDownCurrentForAllCalls, n);
        expect(setUpAllOfForAllCalls, tearDownAllOfForAllCalls + 1);
        tearDownAllOfForAllCalls++;
      },
    );
  });
}
