# Statistics

Using the statistics API, you can collect metrics on the values generated during tests. These metrics consist of any
given value and its frequency.

If you want to know more about the values generated or the shrinking process, specifying `KiriCheck.verbosity` allows
you to obtain detailed information without using the statistics API.

To collect values, use `collect` within the test block. The signature of `collect` is as follows:

```java
void collect(
  Object value, [
  Object? value1,
  Object? value2,
  Object? value3,
  Object? value4,
  Object? value5,
  Object? value6,
  Object? value7,
  Object? value8,
])
```

`collect` can gather groups of up to eight values at once. At the end of the test, the number and proportion of
collected values are displayed.

Example:

```java
property('collect values', () {
  forAll(integer(),
      (n) {
        collect(n);
      },
  });
});
```