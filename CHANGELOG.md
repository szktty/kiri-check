## develop

- [CHANGE] Replace the PRNG with new implemented PRNG which enables to reproduce random values using internal state
- [CHANGE] Remove the dependency on package:mt19937
- [CHANGE] Downgrade the dependencies for Flutter dependencies (#8)
- [CHANGE] Support asynchronous for stateless testing
- [CHANGE] Support asynchronous for stateful testing
- [CHANGE] Enable random value generation using arbitraries outside of tests (#18)
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
