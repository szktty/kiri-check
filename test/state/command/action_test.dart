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
  void destroySystem(ConditionalTestSystem system) {
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

final class Action2TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action2(
        'Action',
        integer(),
        integer(),
        nextState: (s, v1, v2) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2) {
          system.run = true;
          return (v1, v2);
        },
        precondition: (s, v1, v2) {
          s.result = (v1, v2);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, result) {
          return s.precondition && s.result == result && result == (v1, v2);
        },
      ),
    ];
  }
}

final class Action3TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action3(
        'Action',
        integer(),
        integer(),
        integer(),
        nextState: (s, v1, v2, v3) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2, v3) {
          system.run = true;
          return (v1, v2, v3);
        },
        precondition: (s, v1, v2, v3) {
          s.result = (v1, v2, v3);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, v3, result) {
          return s.precondition && s.result == result && result == (v1, v2, v3);
        },
      ),
    ];
  }
}

final class Action4TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action4(
        'Action',
        integer(),
        integer(),
        integer(),
        integer(),
        nextState: (s, v1, v2, v3, v4) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2, v3, v4) {
          system.run = true;
          return (v1, v2, v3, v4);
        },
        precondition: (s, v1, v2, v3, v4) {
          s.result = (v1, v2, v3, v4);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, v3, v4, result) {
          return s.precondition &&
              s.result == result &&
              result == (v1, v2, v3, v4);
        },
      ),
    ];
  }
}

final class Action5TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action5(
        'Action',
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        nextState: (s, v1, v2, v3, v4, v5) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2, v3, v4, v5) {
          system.run = true;
          return (v1, v2, v3, v4, v5);
        },
        precondition: (s, v1, v2, v3, v4, v5) {
          s.result = (v1, v2, v3, v4, v5);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, v3, v4, v5, result) {
          return s.precondition &&
              s.result == result &&
              result == (v1, v2, v3, v4, v5);
        },
      ),
    ];
  }
}

final class Action6TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action6(
        'Action',
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        nextState: (s, v1, v2, v3, v4, v5, v6) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2, v3, v4, v5, v6) {
          system.run = true;
          return (v1, v2, v3, v4, v5, v6);
        },
        precondition: (s, v1, v2, v3, v4, v5, v6) {
          s.result = (v1, v2, v3, v4, v5, v6);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, v3, v4, v5, v6, result) {
          return s.precondition &&
              s.result == result &&
              result == (v1, v2, v3, v4, v5, v6);
        },
      ),
    ];
  }
}

final class Action7TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action7(
        'Action',
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        nextState: (s, v1, v2, v3, v4, v5, v6, v7) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2, v3, v4, v5, v6, v7) {
          system.run = true;
          return (v1, v2, v3, v4, v5, v6, v7);
        },
        precondition: (s, v1, v2, v3, v4, v5, v6, v7) {
          s.result = (v1, v2, v3, v4, v5, v6, v7);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, v3, v4, v5, v6, v7, result) {
          return s.precondition &&
              s.result == result &&
              result == (v1, v2, v3, v4, v5, v6, v7);
        },
      ),
    ];
  }
}

final class Action8TestBehavior extends ActionTestBehaviorBase {
  @override
  List<Command<ConditionalTestState, ConditionalTestSystem>> generateCommands(
    ConditionalTestState s,
  ) {
    return [
      Action8(
        'Action',
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        nextState: (s, v1, v2, v3, v4, v5, v6, v7, v8) {
          expect(s.precondition, isTrue);
          s.nextState = true;
        },
        run: (system, v1, v2, v3, v4, v5, v6, v7, v8) {
          system.run = true;
          return (v1, v2, v3, v4, v5, v6, v7, v8);
        },
        precondition: (s, v1, v2, v3, v4, v5, v6, v7, v8) {
          s.result = (v1, v2, v3, v4, v5, v6, v7, v8);
          return s.precondition = true;
        },
        postcondition: (s, v1, v2, v3, v4, v5, v6, v7, v8, result) {
          return s.precondition &&
              s.result == result &&
              result == (v1, v2, v3, v4, v5, v6, v7, v8);
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

  property('Action2', () {
    runBehavior(
      Action2TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action3', () {
    runBehavior(
      Action3TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action4', () {
    runBehavior(
      Action4TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action5', () {
    runBehavior(
      Action5TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action6', () {
    runBehavior(
      Action6TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action7', () {
    runBehavior(
      Action7TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });

  property('Action8', () {
    runBehavior(
      Action8TestBehavior(),
      maxCycles: 10,
      maxSteps: 10,
    );
  });
}
