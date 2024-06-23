import 'package:kiri_check/kiri_check.dart';
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
  InitializeState initialState() => InitializeState();

  @override
  Null createSystem(InitializeState s) => null;

  @override
  List<Command<InitializeState, Null>> generateCommands(InitializeState s) {
    return [
      Initialize(
        Action0(
          'a',
          nextState: (s) {
            s.history.add(Marker.a);
          },
          run: (system) {},
        ),
      ),
      Initialize(
        Action0(
          'b',
          nextState: (s) {
            s.history.add(Marker.b);
          },
          run: (system) {},
        ),
      ),
      Action0(
        'c',
        nextState: (s) {
          s.history.add(Marker.c);
        },
        run: (system) {},
        precondition: checkState,
      ),
      Action0(
        'd',
        nextState: (s) {
          s.history.add(Marker.d);
        },
        run: (system) {},
        precondition: checkState,
      ),
    ];
  }

  bool checkState(InitializeState s) {
    expect(s.history.first, Marker.a);
    expect(s.history[1], Marker.b);
    expect(s.history.where((e) => e == Marker.a).length, 1);
    expect(s.history.where((e) => e == Marker.b).length, 1);
    return true;
  }

  @override
  void destroySystem(Null system) {}
}

void main() {
  property('basic', () {
    runBehavior(
      InitializeBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });
}
