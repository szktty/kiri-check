<show-structure for="chapter,procedure" depth="2"/>

# Behavior and commands

## Run stateful tests

### `runBehavior` {id="stateful-test-run-behavior"}

```Java
void runBehavior<State, System>(
  Behavior<State, System> behavior, {
  int? seed,
  int? maxCycles,
  int? maxSteps,
  Timeout? cycleTimeout,
  void Function()? setUp,
  void Function()? tearDown,
  void Function(Behavior<State, System>, System)? onDestroy,
  void Function(StatefulFalsifyingExample<State, System>)? onFalsify,
  bool? ignoreFalsify,
})
```


## Behavior

Describes behavior of a stateful test.

### abstract `initializeState`

```java
@factory
State initialState()
```

Creates a new state.


### abstract `initialPrecondition`

```Java
bool initialPrecondition(State state)
```

Returns true if the given state satisfies the initial precondition.


### abstract `createSystem`

```java
@factory
System createSystem(State state)
```

Creates a new system with the given state.


### abstract `destroySystem`

```java
void destroySystem(System system)
```

Destroy the given system.


### abstract `generateCommands`

```Java
List<Command<State, System>> generateCommands(State state)
```

Generates a list of commands to run on the given state.

### optional `setUp`

```Java
void setUp()
```

Called before the cycle is run.
Default implementation does nothing.

### optional `setUpAll`

```Java
void setUpAll()
```

Called once before all cycles are run.
Default implementation does nothing.

### optional `tearDown`

```Java
void tearDown()
```

Called after the cycle is run.
Default implementation does nothing.

### optional `tearDownAll`

```java
void tearDownAll()
```

Called once after all cycles are run.
Default implementation does nothing.


## Generate values and perform actions

### `Action` {id="stateful-test-command-action"}

```java
Action<State, System, T, R>(
  String description,
  Arbitrary<T>? arbitrary, {
  required void nextState(State, T),
  required R run(System, T),
  bool Function(State, T)? precondition,
  bool Function(State, T, R)? postcondition,
})
```

A command that performs actions with generated values.

Depending on the number of arbitraries, there are `Action0` through `Action8`. `Action1` is type alias of `Action`.


## Initialize and finalize

### `Initialize` {id="stateful-test-command-initialize"}

```java
Initialize<State, System>(Command<State, System> cmd)
```

A command that initializes the state and system with another command.

The command enclosed with `Initialize` are always executed first and are not called in subsequent steps. If there are multiple `Initialize` commands, they are executed in the order they were defined.

### `Finalize` {id="stateful-test-command-finalize"}

```java
Finalize<State, System>(Command<State, System> command)
```

A command that finalizes the state and system with another command.

The command enclosed with `Finalize` is always executed last and is not called in previous steps. The `Finalize` command is not executed in any step other than the last one.