# kiri-check

kiri-check is a property-based testing library for Dart.

## Features

- Integrated with [package:test](https://pub.dev/packages/test), it can be used in the same way as regular tests.
  Additionally, property-based tests can be added without modifying existing test code.
- Customization of the exploration method is easy. You can specify data ranges, increase or decrease the number of
  trials, and prioritize edge cases.
- Supports stateful testing. You can test the behavior of a system that changes state over time.
- Supports testing asynchronous code against interleavings. A scheduler runs the code in various orders to find
  race conditions, and shrinks a failing order to a minimal one.

## Install

Install the library from [pub.dev](https://pub.dev/packages/kiri_check) using the following command:

With Dart:

```shell
dart pub add dev:kiri_check
```

With Flutter:

```shell
flutter pub add dev:kiri_check
```

Alternatively, add the library to your `pubspec.yaml` and run `dart pub get` or `flutter pub get`.

```yaml
dev_dependencies:
  kiri_check: ^1.4.0
```

## Documentation

Please refer to the [Documentation](https://szktty.github.io/kiri-check/).

## Basic usage

Properties can be implemented as tests using `package:test`. Assertions use functions from `package:test`.

1. Import the `kiri-check` library.
   ```dart
   import 'package:kiri_check/kiri_check.dart';
   ```
2. Implement properties using the `property` function. This function takes the title of the test and the function to
   execute the test as arguments.
3. Implement the test to validate test data using the `forAll`
   function. This function takes an arbitrary that generates random test data as an argument.

Example:

```dart
import 'package:kiri_check/kiri_check.dart';

dynamic fizzbuzz(int n) {
  // Implement me!
}

void main() {
  property('FizzBuzz', () {
    forAll(
      integer(min: 0, max: 100),
          (n) {
        final result = fizzbuzz(n);
        if (n % 15 == 0) {
          expect(result, 'FizzBuzz');
        } else if (n % 3 == 0) {
          expect(result, 'Fizz');
        } else if (n % 5 == 0) {
          expect(result, 'Buzz');
        } else {
          expect(result, n.toString());
        }
      },
    );
  });
}
```

## Testing interleavings of asynchronous code

Dart runs asynchronous code on a single thread, but code running concurrently interleaves wherever it waits for a
future, which may cause race conditions. The `scheduler` arbitrary generates a scheduler which runs microtasks, such
as the continuations after `await`, in an order of its own instead of the order Dart itself uses. Timers run on
virtual time, so `Future.delayed` completes without waiting.

```dart
class Counter {
  int value = 0;

  Future<void> increment() async {
    final current = value;
    await Future<void>.delayed(const Duration(milliseconds: 10)); // Saves the value
    value = current + 1;
  }
}

void main() {
  property('concurrent increments are not lost', () {
    forAll(scheduler(), (s) async {
      final counter = Counter();
      await s.run(() => Future.wait([counter.increment(), counter.increment()]));
      expect(counter.value, 2);
    });
  });
}
```

When the property fails, the order is shrunk towards the order Dart uses, and the falsifying example shows the
choices made by the scheduler, such as `Scheduler(choices: [1, 1], steps: 3)`. Each choice is the index of the
microtask that ran next among the ready ones, where `0` is the oldest one. The scheduler can be combined with other
arbitraries, such as `combine2(list(integer()), scheduler())`.

The scheduler controls only Dart code. I/O and other code outside of Dart complete in their own order.

## Stateful testing

Stateful testing allows you to test the behavior of a system that changes state over time.
This is particularly useful for testing stateful systems like databases,
user interfaces, or any system with a complex state machine.

To perform stateful testing, in addition to importing `kiri_check/kiri_check.dart`, you need to
import `kiri_check/stateful_test.dart`.

Example:

```dart
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

// Abstract model representing accurate specifications
// with concise implementation.
final class CounterModel {
  int count = 0;

  void reset() {
    count = 0;
  }

  void increment() {
    count++;
  }

  void decrement() {
    count--;
  }
}

// Real system compared with the behavior of the model.
final class CounterSystem {
  // Assume that it is operated in JSON object.
  Map<String, int> data = {'count': 0};

  int get count => data['count']!;

  set count(int value) {
    data['count'] = value;
  }

  void reset() {
    data['count'] = 0;
  }

  void increment() {
    data['count'] = data['count']! + 1;
  }

  void decrement() {
    data['count'] = data['count']! - 1;
  }
}

// Definition of stateful test content.
final class CounterBehavior extends Behavior<CounterModel, CounterSystem> {
  @override
  CounterModel initialState() {
    return CounterModel();
  }

  @override
  CounterSystem createSystem(CounterModel s) {
    return CounterSystem();
  }

  @override
  List<Command<CounterModel, CounterSystem>> generateCommands(CounterModel s) {
    return [
      Action0(
        'reset',
        nextState: (s) => s.reset(),
        run: (system) {
          system.reset();
          return system.count;
        },
        postcondition: (s, count) => count == 0,
      ),
      Action0(
        'increment',
        nextState: (s) => s.increment(),
        run: (system) {
          system.increment();
          return system.count;
        },
        postcondition: (s, count) => s.count + 1 == count,
      ),
      Action0(
        'decrement',
        nextState: (s) => s.decrement(),
        run: (system) {
          system.decrement();
          return system.count;
        },
        postcondition: (s, count) => s.count - 1 == count,
      ),
    ];
  }

  @override
  void destroySystem(CounterSystem system) {}
}

void main() {
  property('counter', () {
    // Run a stateful test.
    runBehavior(CounterBehavior());
  });
}
```

For more detailed information on stateful testing, including advanced usage and customization options, please refer
to [Stateful Testing](https://szktty.github.io/kiri-check/stateful-testing.html).

## Known issues

- [#13](https://github.com/szktty/kiri-check/issues/13) Test results in IntelliJ IDEA do not reflect `tearDownAll`

## TODO

- Example database

## Author

[SUZUKI Tetsuya](https://github.com/szktty) (tetsuya.suzuki@gmail.com)

## License

Apache License, Version 2.0