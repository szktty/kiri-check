import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum Marker {
  a,
  b,
  c,
  d,
}

final class FinalizeState {
  final List<Marker> history = [];
}

final class FinalizeBehavior extends Behavior<FinalizeState, Null> {
  @override
  FinalizeState createState() => FinalizeState();

  @override
  Null createSystem(FinalizeState s) => null;

  @override
  List<Command<FinalizeState, Null>> generateCommands(FinalizeState s) {
    return [
      Finalize(
        'final a',
        Action0<FinalizeState, Null>('a', (s, system) {
          s.history.add(Marker.a);
        }),
      ),
      Finalize(
        'final b',
        Action0<FinalizeState, Null>('b', (s, system) {
          s.history.add(Marker.b);
        }),
      ),
      Action0<FinalizeState, Null>('c', (s, system) {
        s.history.add(Marker.c);
      }),
      Action0<FinalizeState, Null>('d', (s, system) {
        s.history.add(Marker.d);
      }),
    ];
  }

  @override
  void dispose(FinalizeState s, Null system) {
    expect(s.history[s.history.length - 2], Marker.a);
    expect(s.history.last, Marker.b);
    expect(s.history.where((e) => e == Marker.a).length, 1);
    expect(s.history.where((e) => e == Marker.b).length, 1);
  }
}

void main() {
  property('basic', () {
    runBehavior(FinalizeBehavior());
  });
}
