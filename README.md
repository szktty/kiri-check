# kiri-check

kiri-check is a property-based testing library for Dart.

## Features

- Integrated with [package:test](https://pub.dev/packages/test), it can be used in the same way as regular tests.
  Additionally, property-based tests can be added without modifying existing test code.
- Customization of the exploration method is easy. You can specify data ranges, increase or decrease the number of
  trials, and prioritize edge cases.

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
  kiri_check: ^1.0.0
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

## Roadmap

- Stateful tests
- Optimize random number generation
- Web support

## Author

[SUZUKI Tetsuya](https://github.com/szktty)

## License

Apache License, Version 2.0