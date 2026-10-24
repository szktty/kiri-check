## develop

- [ADD] Add the `windows` option to `uri` to generate file URIs from Windows paths such as `C:\dir\file`
- [FIX] `uri` now generates the same file URIs on every platform; on Windows it threw "Illegal character in path"
- [CHANGE] **Breaking:** `StatefulFalsifyingExample.exception` is now `Object?` instead of `Exception?`, so that it can hold an `Error`
- [FIX] A property failing with an `Error` (a `RangeError`, a `StateError`, a failed `assert`, a `StackOverflowError` and so on) is now shrunk like one failing with an `Exception`, and its tear-down callbacks run. An `OutOfMemoryError` is rethrown without shrinking
- [FIX] In stateful tests, a command now runs with the value its precondition was checked with during generation, instead of a value generated again, which could fail the precondition and the property
- [ADD] Show the original falsifying example (or sequence in stateful tests) alongside the shrunk one in the failure report
- [FIX] `StatefulFalsifyingExample.originalSteps` now holds the values of the original failure, not the values changed by shrinking
- [FIX] Stateful shrinking no longer counts a step whose precondition is not satisfied as a failure, which reported sequences that could never fail. Such a step is dropped from the candidate sequence
- [FIX] Stateful shrinking now shrinks the value of one step at a time, from the smallest failing value, so values are actually made smaller
- [FIX] Stateful shrinking can now drop a single step from the middle of a sequence
- [FIX] The stateful failure report keeps the exception of the original failure when no smaller failing sequence is found
- [FIX] Stateful shrinking calls `Behavior.setUp` and `Behavior.tearDown` exactly once for each run
- [FIX] An async property block is now awaited while shrinking, so its failures are shrunk instead of being reported unshrunk with a separate error for each shrunk example
- [FIX] `setUp`, `tearDown` and the `forAll` callbacks are now called for each shrunk example, as for each generated example
- [FIX] `onGenerate` and `onShrink` callbacks returning a `Future` are now awaited
- [FIX] Correct the documentation of `onFalsify` in `forAll`: it is called after shrinking, with the shrunk example

## 1.3.2

- [CHANGE] Update `timezone` dependency to `^0.11.0` (@0rzech, [#30](https://github.com/szktty/kiri-check/pull/30))
- [CHANGE] Update dev dependencies (`lints`, `very_good_analysis`)

## 1.3.1

- [FIX] Ensure `Action.nextState` correctly awaits asynchronous operations, preventing race conditions in state model updates. (@ryanhanks-bestow, [#29](https://github.com/szktty/kiri-check/issues/29))

## 1.3.0

- [ADD] Add `duration` arbitrary for generating Duration values
- [ADD] Add `uri` arbitrary for generating URI values  
- [ADD] Add `nonEmpty` arbitrary manipulation for ensuring collections are not empty
- [ADD] Add `cast()` method to Arbitrary interface for type casting dynamic arbitraries
- [FIX] Unexpected error during shrinking with nested `combine` arbitraries ([#23](https://github.com/szktty/kiri-check/issues/23))

## 1.2.0

- [CHANGE] Replace the PRNG with new implemented PRNG which enables to reproduce random values using internal state
- [CHANGE] Remove the dependency on package:mt19937
- [CHANGE] Downgrade the dependencies for Flutter dependencies (#8)
- [CHANGE] Support asynchronous for stateless testing
- [CHANGE] Support asynchronous for stateful testing
- [CHANGE] Enable random value generation using arbitraries outside of tests (#18)
- [CHANGE] Add `build` arbitrary that accepts callable objects (#20)
- [CHANGE] Remove transformer argument from `combine` arbitraries (#22)
- [UPDATE] Show the exception and stack trace of falsifying examples

### API

- [CHANGE] Add `setUpForAll` and `tearDownForAll` global functions
- [CHANGE] Add `setUpAll` and `tearDownAll` parameters to `forAll`
- [CHANGE] Add `Arbitrary.example` to generate an example value outside of tests
- [FIX] Fix the function passed as the `setUp` parameter to `forAll` not being called before each test execution
  within `forAll`. Previously, the function was only called once.
- [FIX] Fix the function passed as the `tearDown` parameter to `forAll` not being called before each test execution
  within `forAll`. Previously, the function was only called once.

## 1.1.0

- [ADD] Support Web platform
- [ADD] Support stateful testing
- [UPDATE] `integer` arbitrary generates integers in the safe integer range of -2^53 to 2^53-1 on web by default.

## 1.0.0

- Initial version.
