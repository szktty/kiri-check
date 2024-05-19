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

final class FinalizeState extends State {
  final List<Marker> history = [];
}

final class FinalizeBehavior extends Behavior<FinalizeState> {
  @override
  FinalizeState createState() => FinalizeState();

  @override
  List<Command<FinalizeState>> generateCommands(FinalizeState s) {
    return [
      Finalize(
          'final a',
          Action<FinalizeState>('a', (s) {
            s.history.add(Marker.a);
          })),
      Finalize(
          'final b',
          Action<FinalizeState>('b', (s) {
            s.history.add(Marker.b);
          })),
      Action<FinalizeState>('c', (s) {
        s.history.add(Marker.c);
      }),
      Action<FinalizeState>('d', (s) {
        s.history.add(Marker.d);
      }),
    ];
  }
}

void main() {
  property('basic', () {
    forAllStates(FinalizeBehavior(), (s) {
      expect(s.history[s.history.length - 2], Marker.a);
      expect(s.history.last, Marker.b);
      expect(s.history.where((e) => e == Marker.a).length, 1);
      expect(s.history.where((e) => e == Marker.b).length, 1);
    });
  });
}
