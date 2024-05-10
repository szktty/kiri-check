import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class MyState extends State {
  final count = Bundle<int>('count');
  final previous = Bundle<int>('previous');

  // TODO: List<Command> get commands にすべき？
  @override
  List<Command> get commandPool => [
        Action(
          'increment',
          () {
            previous.value = count.value;
            count.value++;
          },
          bundles: [count, previous],
          postcondition: () {
            expect(count.value, previous.value + 2);
          },
        ),
        Action(
          'decrement',
          () {
            previous.value = count.value;
            count.value--;
          },
          bundles: [count, previous],
          postcondition: () {
            expect(count.value, previous.value - 1);
          },
        ),
        Action(
          'reset',
          () {
            previous.value = count.value;
            count.value = 0;
          },
          bundles: [count, previous],
          postcondition: () {
            expect(count.value, 0);
          },
        ),
      ];

  // TODO: List<Command> get initializer にすべき？
  @override
  List<Command> get initializeCommands => [
        Update('update count', count, constant(0)),
      ];
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('StatefulProperty', () {
    property('basic', () {
      forAllStates(MyState());
    });
  });
}
