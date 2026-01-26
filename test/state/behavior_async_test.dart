import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

final class AsyncCounterBehavior extends Behavior<CounterState, CounterSystem> {
  @override
  Future<CounterState> initialState() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return CounterState();
  }

  @override
  Future<CounterSystem> createSystem(CounterState s) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return CounterSystem(s.count);
  }

  @override
  Future<void> destroySystem(CounterSystem system) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<List<Command<CounterState, CounterSystem>>> generateCommands(
    CounterState s,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return [
      Action(
        'set',
        integer(),
        nextState: (s, value) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          s.count = value;
        },
        run: (system, value) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return system.count = value;
        },
        postcondition: (s, value, result) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return value == result;
        },
      ),
      Action0(
        'increment',
        nextState: (s) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          s.count++;
        },
        run: (system) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return ++system.count;
        },
        postcondition: (s, count) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return s.count + 1 == count;
        },
      ),
      Action0(
        'decrement',
        nextState: (s) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          s.count--;
        },
        run: (system) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return --system.count;
        },
        postcondition: (s, count) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return s.count - 1 == count;
        },
      ),
    ];
  }
}

final class CounterState {
  int count = 0;
}

final class CounterSystem {
  CounterSystem(this.count);

  int count;
}

final class AsyncTestCallbacksBehavior
    extends Behavior<TestCallbacksState, Null> {
  int setUpCount = 0;
  int setUpAllCount = 0;
  int tearDownCount = 0;
  int tearDownAllCount = 0;
  int destroyCount = 0;

  @override
  Future<TestCallbacksState> initialState() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return TestCallbacksState();
  }

  @override
  Future<Null> createSystem(TestCallbacksState s) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return null;
  }

  @override
  Future<List<Command<TestCallbacksState, Null>>> generateCommands(
    TestCallbacksState state,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return [
      Action0('no op', nextState: (s) async {}, run: (system) async {}),
    ];
  }

  @override
  Future<void> destroySystem(Null system) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    destroyCount++;
  }

  @override
  Future<void> setUp() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    setUpCount++;
  }

  @override
  Future<void> setUpAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    setUpAllCount++;
  }

  @override
  Future<void> tearDown() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    tearDownCount++;
  }

  @override
  Future<void> tearDownAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    tearDownAllCount++;
  }
}

final class TestCallbacksState {}

void main() {
  group('AsyncStatefulProperty', () {
    property('async basic', () async {
      runBehavior(
        AsyncCounterBehavior(),
        maxCycles: 10,
        maxSteps: 10,
      );
    });

    property('async test callbacks', () async {
      final behavior = AsyncTestCallbacksBehavior();
      runBehavior(
        behavior,
        maxCycles: 10,
        maxSteps: 10,
        tearDown: () async {
          expect(behavior.setUpCount, 10);
          expect(behavior.setUpAllCount, 1);
          expect(behavior.destroyCount, 10);
          expect(behavior.tearDownCount, 10);
          expect(behavior.tearDownAllCount, 1);
        },
      );
    });

    property('async nextState await bug reproduction', () async {
      runBehavior(
        AsyncNextStateProblemBehavior(),
        maxCycles: 10,
        maxSteps: 5,
      );
    });
  });
}

final class TestState {
  int count = 0;
  bool isUpdating = false;
}

final class TestSystem {
  int count = 0;
}

final class AsyncNextStateProblemBehavior
    extends Behavior<TestState, TestSystem> {
  @override
  Future<TestState> initialState() async {
    return TestState();
  }

  @override
  Future<TestSystem> createSystem(TestState s) async {
    return TestSystem();
  }

  @override
  Future<List<Command<TestState, TestSystem>>> generateCommands(
    TestState s,
  ) async {
    return [
      Action(
        'Update count asynchronously',
        integer(),
        nextState: (s, value) async {
          s.isUpdating = true;
          // Simulate async operation that takes time
          await Future<void>.delayed(const Duration(milliseconds: 200));
          s.count = value;
          s.isUpdating = false;
        },
        run: (system, value) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          system.count = value;
          return null;
        },
        postcondition: (s, value, result) async {
          // Postcondition is checked *before* nextState is called
          // So, s.count should still be the old value, and isUpdating should be false initially
          // This postcondition doesn't directly expose the bug in Action.nextState
          return true;
        },
      ),
      Action0(
        'Assert not updating',
        nextState: (s) async {},
        run: (system) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          // System side also does nothing here, just for modeling check
          return null;
        },
        precondition: (s) async {
          // This is the key: if nextState (from previous command) isn't awaited,
          // s.isUpdating might still be true here, causing this precondition to fail.
          // Expect true if nextState is properly awaited.
          expect(
            s.isUpdating,
            isFalse,
            reason:
                'nextState should be completed before the next precondition is checked.',
          );
          return !s.isUpdating;
        },
      ),
    ];
  }

  @override
  Future<void> destroySystem(TestSystem system) async {}
}
