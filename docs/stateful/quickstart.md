# Quickstart

## An example

We will implement a simple stateful test for a counter.
This counter holds a count number and can perform the following operations:

- Increase the count by 1
- Decrease the count by 1
- Reset the count to 0

In stateful testing, we can find bugs related to combinations and execution order of these operations.

The code for the real system is as follows.
For simplicity, let's assume that the count number is stored in JSON. This assumption helps to illustrate the concept, even though it might not be the most practical design in a real-world scenario.


```java
final class CounterSystem {
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
```

To implement a stateful test for this counter, we need a model that serves as a reference implementation.
The model is compared with the real system as a reference implementation. Therefore, the simpler the implementation, the better.

In this test, we do not focus on data retention and output, so it doesn't matter how the model stores the count number.
In the previous real system, the count number is held in JSON, but in the model, we will simply hold it as an integer.

The code for the model is as follows:

```java
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
```


## Behavior and commands

From here, we will describe the test content.
In kiri-check's stateful testing, we perform random operations on the model and the real system multiple times, and after execution, we compare the states to check if there are any problems with the implementation of the real system.
We call this operation a command, and the specific commands are defined by the user.
In this example, we prepare three commands: "Increase count", "Decrease count", and "Reset".

The test content, including the definition of commands, is defined in a subclass of `Behavior`. First, here is the code:

```Java
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

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
```


To perform stateful testing, in addition to importing `kiri_check/kiri_check.dart`, you need to import `kiri_check/stateful_test.dart`.

`CounterBehavior`, which extends `Behavior`, defines the test content for the counter.
`Behavior` takes two type parameters: the model and the real system. In this implementation, we use the previously defined `CounterModel` and `CounterSystem`.

The methods that must be implemented in a subclass of `Behavior` are `initialState`, `createSystem`, `destroySystem`, and `generateCommands`.

`initialState` generates the model, and `createSystem` generates the real system using the model. In this case, each object is simply instantiated. These objects represent the initial state.

`destroySystem` describes the termination process for the real system. It is called at the end of the test.

`generateCommands` generates a list of commands that will be executed randomly. The order of commands in the list does not affect the test.

## `Action` commands

There are several types of commands, but the most commonly used is `Action`.
`Action` specifies functions to execute on the model and the real system.
By specifying arbitraries, you can also use randomly generated values.
In this example, we use `Action0`, which does not use any arbitraries.
There are also `Action2` to `Action8` commands, which can use two to eight arbitraries, respectively.

Let's look at the content of the increment command:

```java
Action0(
    'increment',
    nextState: (s) => s.increment(),
    run: (system) {
        system.increment();
        return system.count;
    },
    postcondition: (s, count) => s.count + 1 == count,
),
```

The first argument of `Action0` is the command name, which is used for logging. `nextState` specifies the function to transition the model (state) to the next state. `run` specifies the function to manipulate the real system. `postcondition` represents the postcondition, which, if true, considers the command execution successful. If false, it considers it a failure and starts shrinking.

These functions are called in the order of `run`, `postcondition`, `nextState`.
It is important to note that `nextState` is called after `postcondition`, not after `run`.
After calling `run` to make changes to the real system, the return value of `run` and the model are passed to `postcondition`.
At this point, the state of the model corresponds to the real system before the change. The return value of `run` should ideally reflect the difference between the real system before and after the change.
In `postcondition`, it checks whether the return value of `run` is valid for the state of the model after the change. It might be confusing that the argument for `postcondition` is the model instead of the system, but the focus of stateful testing is on the model.

The specific behavior is as follows:

1. `run` is called. It increments the count in the real system and returns the count after the increment. If the count before the increment is 0, the count after the increment will be 1, and the return value will also be 1. At this point, the count held by the model remains 0.
2. `postcondition` is called. The model before the increment and the return value of `run`, which is 1 (the current count of the real system), are passed as arguments. If the result of adding 1 to the count of the model is the same as the return value of `run`, the postcondition is successful. At this point, no destructive changes should be made to the model.
3. `nextState` is called. It increments the count of the model and moves on to the execution of the next command.


## Run the test

Call `runBehavior` within the `property` block.
`runBehavior` takes the previously defined `Behavior` as an argument.

```java
void main() {
  property('counter', () {
    runBehavior(CounterBehavior());
  });
}
```

## Where to next?

- Read the [execution model](/stateful/#stateful-test-execution-model) to understand the behavior of stateful testing.
- Set `KiriCheck.verbosity` to `Verbosity.verbose` to observe the randomly executed commands.
- Intentionally introduce errors to observe the behavior of shrinking.
