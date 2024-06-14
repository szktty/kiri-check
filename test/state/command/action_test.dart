import 'dart:math';

import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

abstract class ConditionalTestStateBase {
  bool nextState = false;
  bool run = false;
  bool precondition = false;
  dynamic result;

  @override
  String toString() {
    return '{nextState: $nextState, run: $run, precondition: $precondition, result: $result}';
  }
}

final class ConditionalTestState extends ConditionalTestStateBase {
  ConditionalTestState([dynamic result]) {
    this.result = result ?? Random().nextInt(10000);
  }
}

final class ConditionalTestSystem extends ConditionalTestStateBase {
  ConditionalTestSystem(dynamic result) {
    this.result = result;
  }
}

abstract class ActionTestBehaviorBase
    extends Behavior<ConditionalTestState, ConditionalTestSystem> {
  @override
  ConditionalTestState initialState() => ConditionalTestState();

  @override
  ConditionalTestSystem createSystem(ConditionalTestState s) =>
      ConditionalTestSystem(s.result);

  @override
  void destroy(ConditionalTestSystem system) {
    expect(system.run, isTrue);
  }
}

final class Action0TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action0(
        'Action',
        nextState: (s) {
          expect(s.precondition, isTrue);
        },
        run: (system) {
          system.run = true;
          return system.result;
        },
        precondition: (s) {
          return s.precondition = true;
        },
        postcondition: (s, result) {
          return s.precondition && s.result == result;
        },
      ),
    ];
  }
}

final class Action1TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action(
        'Action',
        integer(),
        nextState: (s, value) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, value) {
          system.run = true;
          return value;
        },
        precondition: (s, value) {
          s.result = value;
          return s.precondition = true;
        },
        postcondition: (s, value, result) {
          return s.precondition && s.result == result;
        },
      ),
    ];
  }
}

void main() {
  property('Action0', () {
    runBehavior(
      Action0TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action1', () {
    runBehavior(
      Action1TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });
}
