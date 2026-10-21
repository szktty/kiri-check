import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

const _seed = 20261008;

final class Total {
  int value = 0;
}

/// A running total that fails once it reaches 10, by throwing an [Error] or
/// by its postcondition.
final class AddBehavior extends Behavior<Total, Total> {
  AddBehavior({required this.throwsError});

  final bool throwsError;

  int setUpCalls = 0;
  int tearDownCalls = 0;
  int tearDownAllCalls = 0;
  int unbalancedCalls = 0;
  bool _isSetUp = false;

  @override
  Total initialState() => Total();

  @override
  Total createSystem(Total state) => Total();

  @override
  void destroySystem(Total system) {}

  @override
  void setUp() {
    setUpCalls++;
    if (_isSetUp) {
      unbalancedCalls++;
    }
    _isSetUp = true;
  }

  @override
  Future<void> tearDown() async {
    tearDownCalls++;
    if (!_isSetUp) {
      unbalancedCalls++;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
    _isSetUp = false;
  }

  @override
  void tearDownAll() {
    tearDownAllCalls++;
  }

  @override
  List<Command<Total, Total>> generateCommands(Total state) {
    return [
      Action<Total, Total, int, int>(
        'add',
        integer(min: 1, max: 8),
        run: (system, value) {
          system.value += value;
          if (throwsError && system.value >= 10) {
            throw StateError('total reached ${system.value}');
          }
          return system.value;
        },
        postcondition: (state, value, result) => throwsError || result < 10,
        nextState: (state, value) => state.value += value,
      ),
    ];
  }
}

final class ThresholdBehavior extends Behavior<Null, Null> {
  @override
  Null initialState() => null;

  @override
  Null createSystem(Null state) => null;

  @override
  void destroySystem(Null system) {}

  @override
  List<Command<Null, Null>> generateCommands(Null state) {
    return [
      Action<Null, Null, int, int>(
        'put',
        integer(min: 0, max: 1000),
        run: (system, value) => value,
        postcondition: (state, value, result) => result < 55,
        nextState: (state, value) {},
      ),
    ];
  }
}

final class Till {
  bool open = false;
}

/// A sale requires the till to be opened first.
final class TillBehavior extends Behavior<Till, Till> {
  @override
  Till initialState() => Till();

  @override
  Till createSystem(Till state) => Till();

  @override
  void destroySystem(Till system) {}

  @override
  List<Command<Till, Till>> generateCommands(Till state) {
    return [
      Action0<Till, Till, bool>(
        'open',
        precondition: (state) => !state.open,
        run: (system) => system.open = true,
        nextState: (state) => state.open = true,
      ),
      Action<Till, Till, int, int>(
        'sell',
        integer(min: 1, max: 8),
        precondition: (state, value) => state.open,
        run: (system, value) => value,
        postcondition: (state, value, result) => result < 6,
        nextState: (state, value) {},
      ),
    ];
  }
}

/// A till opened, closed and opened again before the failing sale.
final class ReopenTillBehavior extends Behavior<Till, Till> {
  @override
  Till initialState() => Till();

  @override
  Till createSystem(Till state) => Till();

  @override
  void destroySystem(Till system) {}

  Command<Till, Till> _open() => Action0<Till, Till, bool>(
        'open',
        precondition: (state) => !state.open,
        run: (system) => system.open = true,
        nextState: (state) => state.open = true,
      );

  Command<Till, Till> _sell(int value) => Action<Till, Till, int, int>(
        'sell',
        integer(min: value, max: value),
        precondition: (state, value) => state.open,
        run: (system, value) => value,
        postcondition: (state, value, result) => result < 6,
        nextState: (state, value) {},
      );

  @override
  List<Command<Till, Till>> generateCommands(Till state) {
    return [
      Sequence('reopen', [
        _open(),
        _sell(2),
        Action0<Till, Till, bool>(
          'close',
          precondition: (state) => state.open,
          run: (system) => system.open = false,
          nextState: (state) => state.open = false,
        ),
        _open(),
        _sell(6),
      ]),
    ];
  }
}

List<String> _descriptions<State, System>(
  StatefulFalsifyingExample<State, System> example,
) {
  return example.falsifyingSteps.map((s) => s.command.description).toList();
}

int _sum<State, System>(StatefulFalsifyingExample<State, System> example) {
  return example.falsifyingSteps.fold(0, (sum, s) => sum + (s.value as int));
}

void main() {
  group('shrinking a failing behavior', () {
    property('shrinks a command throwing an Error', () {
      final behavior = AddBehavior(throwsError: true);
      StatefulFalsifyingExample<Total, Total>? falsified;
      runBehavior(
        behavior,
        seed: _seed,
        maxCycles: 30,
        maxSteps: 20,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(behavior.tearDownAllCalls, 1);
        expect(falsified, isNotNull);
        expect(falsified!.exception, isA<StateError>());
        expect(_sum(falsified!), 10);
      });
    });

    property('balances setUp and tearDown', () {
      final behavior = AddBehavior(throwsError: false);
      runBehavior(
        behavior,
        seed: _seed,
        maxCycles: 30,
        maxSteps: 20,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(behavior.tearDownCalls, behavior.setUpCalls);
        expect(behavior.unbalancedCalls, 0);
      });
    });

    property('reports the exception of the failure', () {
      StatefulFalsifyingExample<Total, Total>? falsified;
      runBehavior(
        AddBehavior(throwsError: false),
        seed: _seed,
        maxCycles: 30,
        maxSteps: 20,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, isNotNull);
        expect(
          falsified!.exception.toString(),
          'postcondition is not satisfied',
        );
      });
    });

    property('shrinks the values of a sequence', () {
      StatefulFalsifyingExample<Total, Total>? falsified;
      runBehavior(
        AddBehavior(throwsError: false),
        seed: _seed,
        maxCycles: 30,
        maxSteps: 20,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, isNotNull);
        // No value can be made smaller without the total dropping below 10.
        expect(_sum(falsified!), 10);
      });
    });

    property('shrinks a value to the smallest failing one', () {
      StatefulFalsifyingExample<Null, Null>? falsified;
      runBehavior(
        ThresholdBehavior(),
        seed: _seed,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, isNotNull);
        expect(falsified!.falsifyingSteps.map((s) => s.value), [55]);
      });
    });

    property('does not accept a sequence breaking a precondition', () {
      StatefulFalsifyingExample<Till, Till>? falsified;
      runBehavior(
        TillBehavior(),
        seed: _seed,
        maxCycles: 30,
        maxSteps: 20,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, isNotNull);
        expect(_descriptions(falsified!), ['open', 'sell']);
        expect(falsified!.falsifyingSteps.last.value, 6);
        expect(
          falsified!.exception.toString(),
          'postcondition is not satisfied',
        );
      });
    });

    property('reports the values of the original failure', () {
      StatefulFalsifyingExample<Total, Total>? falsified;
      runBehavior(
        AddBehavior(throwsError: false),
        seed: _seed,
        maxCycles: 30,
        maxSteps: 20,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, isNotNull);
        // The original sequence fails at its last step and not before.
        final values =
            falsified!.originalSteps.map((s) => s.value as int).toList();
        var total = 0;
        for (final value in values.take(values.length - 1)) {
          total += value;
          expect(total, lessThan(10));
        }
        expect(total + values.last, greaterThanOrEqualTo(10));
      });
    });

    property('drops steps whose precondition is no longer satisfied', () {
      StatefulFalsifyingExample<Till, Till>? falsified;
      runBehavior(
        ReopenTillBehavior(),
        seed: _seed,
        maxCycles: 1,
        maxSteps: 5,
        onFalsify: (example) => falsified = example,
        ignoreFalsify: true,
      );
      addTearDown(() {
        expect(falsified, isNotNull);
        expect(
          falsified!.originalSteps.map((s) => s.command.description),
          ['open', 'sell', 'close', 'open', 'sell'],
        );
        expect(_descriptions(falsified!), ['open', 'sell']);
        expect(falsified!.falsifyingSteps.last.value, 6);
        expect(
          falsified!.exception.toString(),
          'postcondition is not satisfied',
        );
      });
    });
  });
}
