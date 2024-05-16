import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:test/test.dart';

enum Marker {
  a,
  b,
  c,
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
          'first',
          Action<InitializeState>('a', (s) {
            s.history.add(Marker.a);
          })),
      Action<InitializeState>('b', (s) {
        s.history.add(Marker.b);
      }),
      Action<InitializeState>('c', (s) {
        s.history.add(Marker.c);
      }),
    ];
  }
}

void main() {
  property('basic', () {
    forAllStates(InitializeBehavior(), (s) {
      expect(s.history.first, Marker.a);
      expect(s.history.where((e) => e == Marker.a).length, 1);
    });
  });
}
