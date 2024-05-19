import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum Marker {
  a,
  b,
  c,
  d,
}

final class InitializeState extends State {
  final List<Marker> history = [];
}

final class InitializeBehavior extends Behavior<InitializeState> {
  @override
  InitializeState createState() => InitializeState();

  @override
  List<Command<InitializeState>> generateCommands(InitializeState s) {
    return [
      Initialize(
          'first a',
          Action<InitializeState>('a', (s) {
            s.history.add(Marker.a);
          })),
      Initialize(
          'first b',
          Action<InitializeState>('b', (s) {
            s.history.add(Marker.b);
          })),
      Action<InitializeState>('c', (s) {
        s.history.add(Marker.c);
      }),
      Action<InitializeState>('d', (s) {
        s.history.add(Marker.d);
      }),
    ];
  }
}

void main() {
  property('basic', () {
    forAllStates(InitializeBehavior(), (s) {
      expect(s.history.first, Marker.a);
      expect(s.history[1], Marker.b);
      expect(s.history.where((e) => e == Marker.a).length, 1);
      expect(s.history.where((e) => e == Marker.b).length, 1);
    });
  });
}
