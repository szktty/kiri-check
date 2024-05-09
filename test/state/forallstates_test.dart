import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/arbitrary/top.dart';
import 'package:kiri_check/src/state/command/base.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class MyState extends State {
  final count = Bundle<int>('count');

  @override
  List<Command> build() => [
        Action(
          'increment',
          () {
            count.value++;
          },
          bundles: [count],
        ),
        Action(
          'decrement',
          () {
            count.value--;
          },
          bundles: [count],
        ),
      ];

  @override
  List<Command> initialize() => [
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
