# Quickstart

## Set up

### Create a new project

There is no need for a special project structure to introduce kiri-check. Simply create a regular project using
the `dart` command (or `flutter` command).

```shell
dart create kiri_check_quickstart
```

### Install

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
  kiri_check: ^1.2.0
```

## Write a simple property

Writing a property is straightforward. kiri-check is integrated with `package:test` and can be used alongside it. There
is no need to change existing unit test code; you can simply add properties.

Let’s write a very simple property. Create a file named `simple_test.dart` in the `test` directory and add the following
code:

`simple_test.dart`:

```java
property('generate integer', () {
  forAll(integer(), (value) {
    expect(value, isA<int>());
  });
});
```

This property uses the `integer` arbitrary to generate a random integer and verifies that the integer is of type `int`.
This property will always succeed (provided there are no bugs in kiri-check).

Properties are defined with the `property` function. `property` accepts the same arguments as the `test` function
from `package:test`. The `forAll` function used within the block passed to `property` takes an arbitrary that generates
random values and a block that receives these values. In that block, you can verify the values using the `expect`
function from unit tests.

## Run the test

Running the test is the same as with `package:test`. Execute it with the `dart test` command.

```shell
dart test
```

If a property fails, shrinking will occur to display the smallest value that causes the error.

## Where to next?

Whether you are familiar with property-based testing or not, it's a good idea to look through the list of arbitraries to
get to know the main ones. If you're new to property-based testing, reading a book on the subject is also a good idea.
Though it's intended for Erlang and Elixir, I
recommend [Property-Based Testing with PropEr, Erlang, and Elixir: Find Bugs Before Your Users Do](https://pragprog.com/titles/fhproper/property-based-testing-with-proper-erlang-and-elixir/) ([Japanese translation](https://www.lambdanote.com/collections/proper-erlang-elixir)).