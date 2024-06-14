import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum Marker {
  a,
  b,
  c,
  d,
}

final class FinalizeState {}

final class FinalizeBehavior extends Behavior<FinalizeState, Null> {
  @override
  FinalizeState initialState() {
    history.clear();
    return FinalizeState();
  }

  @override
  Null createSystem(FinalizeState s) => null;

  final List<Marker> history = [];

  @override
  List<Command<FinalizeState, Null>> generateCommands(FinalizeState s) {
    return [
      Finalize(
        Action0(
          'a',
          nextState: (s) {
            history.add(Marker.a);
          },
          run: (system) {},
        ),
      ),
      Finalize(
        Action0(
          'b',
          nextState: (s) {
            history.add(Marker.b);
          },
          run: (system) {},
        ),
      ),
      Action0(
        'c',
        nextState: (s) {
          history.add(Marker.c);
        },
        run: (system) {},
      ),
      Action0(
        'd',
        nextState: (s) {
          history.add(Marker.d);
        },
        run: (system) {},
      ),
    ];
  }

  @override
  void tearDown() {
    if (history.length > 1) {
      expect(history.removeLast(), equals(Marker.b));
      expect(history.removeLast(), equals(Marker.a));
    }
    for (final e in history) {
      expect(e, isNot(Marker.a));
      expect(e, isNot(Marker.b));
    }
  }

  @override
  void destroy(Null system) {}
}

void main() {
  property('basic', () {
    runBehavior(
      FinalizeBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });
}
