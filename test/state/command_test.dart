import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

final class ConditionalTestState {
  bool precondition = false;
  bool postcondition = false;
}

final class ConditionalTestBehavior
    extends Behavior<ConditionalTestState, Null> {
  @override
  ConditionalTestState createState() => ConditionalTestState();

  @override
  Null createSystem(ConditionalTestState s) => null;

  @override
  List<Command<ConditionalTestState, Null>> generateCommands(
      ConditionalTestState s) {
    return [
      Action0<ConditionalTestState, Null>(
        'no op',
        (s, system) {},
        precondition: (s, system) {
          s.precondition = true;
          return true;
        },
        postcondition: (s, system) {
          s.postcondition = true;
          return true;
        },
      ),
    ];
  }

  @override
  void tearDown(ConditionalTestState s, Null system) {
    expect(s.precondition, isTrue);
    expect(s.postcondition, isTrue);
  }
}

void main() {
  property('conditional', () {
    forAllStates(ConditionalTestBehavior());
  });
}
