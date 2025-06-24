# Configure tests

## Customize test settings

Test settings such as timeouts can be configured in the `property` function. Since `property` accepts the same arguments
as `test`, the same configurations are possible.

Settings that affect globally can be modified through static properties of `KiriCheck`.

## Customize number of examples and attempts

The maximum number of values passed to the test block can be specified using `KiriCheck.maxExamples` or `maxExamples`
in `forAll`. The default is 100. If generated values are discarded using filters such as `filter`, you can repeat the
generation up to the maximum number of attempts specified by `KiriCheck.maxTries` or `maxTries` in `forAll`.

## Customize number of shrinking attempts

The number of attempts for shrinking can be specified using `KiriCheck.maxShrinkingTries` or `maxShrinkingTries`
in `forAll`. The default is 100.

If you want to disable or make shrinking unlimited, specify `ShrinkingPolicy` using `KiriCheck.shrinkingPolicy`
or `shrinkingPolicy` in `forAll`. To disable, specify `ShrinkingPolicy.off`; to make it unlimited,
specify `ShrinkingPolicy.full`.

## Fix random seed {id="fix-random-seed"}

You can specify a random seed using `KiriCheck.seed` or `seed` in `forAll`. Fixing the random seed ensures that the same
errors and shrinking results occur every time an error happens.

## Skip failed tests

By setting `ignoreFalsify` to true in `forAll`, testing will continue even if a test fails.

## Show generated values and shrunk values verbosely {id="verbose"}

Setting `KiriCheck.verbosity` to `Verbosity.verbose` allows you to display the details of generated and shrunk values.

Example:

```java
KiriCheck.verbosity = Verbosity.verbose;
```
