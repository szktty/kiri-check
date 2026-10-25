import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

/// Adds even numbers only, so its property never fails.
final class EvenBehavior extends Behavior<List<int>, List<int>> {
  @override
  List<int> initialState() => [];

  @override
  List<int> createSystem(List<int> state) => [];

  @override
  void destroySystem(List<int> system) {}

  @override
  List<Command<List<int>, List<int>>> generateCommands(List<int> state) {
    return [
      Action<List<int>, List<int>, int, int>(
        'add',
        integer(min: 0, max: 1000),
        precondition: (state, value) => value.isEven,
        run: (system, value) {
          system.add(value);
          return value;
        },
        postcondition: (state, value, result) => result.isEven,
        nextState: (state, value) => state.add(value),
      ),
    ];
  }
}

void main() {
  property('runs the values checked by preconditions', () {
    runBehavior(EvenBehavior(), seed: 1, maxCycles: 10, maxSteps: 20);
  });
}
