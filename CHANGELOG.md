## develop

- [CHANGE] Replace the PRNG with new implemented PRNG which enables to reproduce random values using internal state
- [CHANGE] Remove the dependency on package:mt19937
- [CHANGE] Downgrade the dependencies for Flutter dependencies (#8)
- [UPDATE] Add tests for asynchronous properties

## 1.1.0

- [ADD] Support Web platform
- [ADD] Support stateful testing
- [UPDATE] `integer` arbitrary generates integers in the safe integer range of -2^53 to 2^53-1 on web by default.

## 1.0.0

- Initial version.
