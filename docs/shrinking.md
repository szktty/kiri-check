# Shrinking

Shrinking is a crucial process in property-based testing that finds the smallest value that causes an error. This
process simplifies test cases, enabling efficient debugging and error analysis. However, the minimum value found by
shrinking is only an approximation, and it's being the absolute minimum is not guaranteed. Particularly with continuous
values, it's relatively easier to find the nearest minimum approximation, but this is not necessarily the case with
discrete values.

The shrinking process involves reducing values towards a baseline, which varies depending on the arbitrary used.
Generally, values are reduced towards zero or empty. The shrunk values generated are not random but are produced
according to specific rules, ensuring the same shrunk value is generated for the same error value each time.

Mostly, there is no need to deeply consider the details of shrinking. Each arbitrary is designed to perform shrinking as
efficiently as possible. Although there is a limit to the number of shrinking attempts by default, if you wish to
perform more shrinking, you can specify the number in settings or set it to unlimited under the shrinking policy.
Nonetheless, for most cases, the default setting is adequate. Rather than increasing the number of shrinking attempts,
it is more important to specify an appropriate range for generating data.

## Shrinking policy {id="shrinking-policy"}

The shrinking policy can be specified in `forAll` with `ShrinkingPolicy`.

- `ShrinkingPolicy.off` disables shrinking.
- `ShrinkingPolicy.bounded` limits the number of shrinking attempts. This is the default behavior.
- `ShrinkingPolicy.full` allows for unlimited shrinking.

For further details, refer to the [API reference](https://pub.dev/documentation/kiri_check/latest/).
