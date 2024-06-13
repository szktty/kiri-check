import 'package:collection/collection.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

final class SequenceTestState {
  final events = <int>[];

  void add(int event) {
    events.add(event);
  }
}

final class SequenceTestBehavior extends Behavior<SequenceTestState, Null> {
  @override
  SequenceTestState initialState() {
    return SequenceTestState();
  }

  @override
  Null createSystem(SequenceTestState s) {
    return null;
  }

  @override
  List<Command<SequenceTestState, Null>> generateCommands(SequenceTestState s) {
    return [
      Initialize('first sequence', _sequence(1, 3)),
      _sequence(4, 6),
      Finalize('last sequence', _sequence(7, 9)),
    ];
  }

  Sequence<SequenceTestState, Null> _sequence(int start, int end) {
    return Sequence('sequence', [
      for (var i = start; i <= end; i++)
        Action0(
          'add $i',
          (s, system) {
            s.add(i);
          },
        ),
    ]);
  }
}

void main() {
  property('with initializer and finalizer which contain sequence', () {
    runBehavior(
      SequenceTestBehavior(),
      onDispose: (behavior, state, system) {
        final equals = const DeepCollectionEquality().equals;
        final events = state.events;
        expect(events.sublist(0, 3), predicate((e) => equals(e, [1, 2, 3])));
        expect(
          events.sublist(events.length - 3, events.length),
          predicate((e) => equals(e, [7, 8, 9])),
        );
        for (var i = 0; i < events.length - 6; i++) {
          expect(events[i + 3], [4, 5, 6][i % 3]);
        }
      },
    );
  });
}
