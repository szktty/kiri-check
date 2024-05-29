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

final class InitializeState {
  final List<Marker> history = [];
}

final class InitializeBehavior extends Behavior<InitializeState, Null> {
  @override
  InitializeState createState() => InitializeState();

  @override
  Null createSystem(InitializeState s) => null;

  @override
  List<Command<InitializeState, Null>> generateCommands(InitializeState s) {
    return [
      Initialize(
          'first a',
          Action0<InitializeState, Null>('a', (s, system) {
            s.history.add(Marker.a);
          })),
      Initialize(
          'first b',
          Action0<InitializeState, Null>('b', (s, system) {
            s.history.add(Marker.b);
          })),
      Action0<InitializeState, Null>('c', (s, system) {
        s.history.add(Marker.c);
      }),
      Action0<InitializeState, Null>('d', (s, system) {
        s.history.add(Marker.d);
      }),
    ];
  }

  @override
  void tearDown(InitializeState s, Null system) {
    expect(s.history.first, Marker.a);
    expect(s.history[1], Marker.b);
    expect(s.history.where((e) => e == Marker.a).length, 1);
    expect(s.history.where((e) => e == Marker.b).length, 1);
  }
}

void main() {
  property('basic', () {
    runBehavior(InitializeBehavior());
  });
}
