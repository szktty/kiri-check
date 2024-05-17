import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/src/exception.dart';
import 'package:kiri_check/src/state/command.dart';
import 'package:kiri_check/src/state/property.dart';
import 'package:kiri_check/src/state/state.dart';
import 'package:kiri_check/src/top.dart';
import 'package:test/test.dart';

final class CallbackTestState extends State {
  bool didSetUp = false;
  bool didTearDown = false;

  @override
  void setUp() {
    didSetUp = true;
  }

  @override
  void tearDown() {
    didTearDown = true;
  }
}

final class CallbackTestBehavior extends Behavior<CallbackTestState> {
  @override
  CallbackTestState createState() => CallbackTestState();

  @override
  List<Command<CallbackTestState>> generateCommands(CallbackTestState s) {
    return [
      Action<CallbackTestState>('no op', (s) {}),
    ];
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('callbacks', () {
    property('set up and tear down', () {
      forAllStates(
        CallbackTestBehavior(),
        (s) {
          expect(s.didSetUp, isTrue);
          expect(s.didTearDown, isTrue);
        },
      );
    });
  });
}
