import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

// 簡潔な実装で正確な仕様を表現する
final class CounterModel {
  int count = 0;

  void reset() {
    count = 0;
  }

  void increment() {
    count++;
  }

  void decrement() {
    count--;
  }
}

// 実運用される実装を使って仕様を表現する
// モデルの挙動と比較される
final class CounterSystem {
  // JSONオブジェクトで実運用すると仮定する
  Map<String, int> data = {'count': 0};

  int get count => data['count']!;

  set count(int value) {
    data['count'] = value;
  }

  void reset() {
    data['count'] = 0;
  }

  void increment() {
    data['count'] = data['count']! + 1;
  }

  void decrement() {
    data['count'] = data['count']! - 1;
  }
}

// ステートフルテスト内容を定義する
final class CounterBehavior extends Behavior<CounterModel, CounterSystem> {
  @override
  CounterModel createState() {
    return CounterModel();
  }

  @override
  CounterSystem createSystem(CounterModel s) {
    return CounterSystem();
  }

  @override
  List<Command<CounterModel, CounterSystem>> generateCommands(CounterModel s) {
    return [
      Action0('reset', (s, system) {
        s.reset();
        system.reset();
      }, postcondition: (s, system) {
        return s.count == system.count;
      }),
      Action0('increment', (s, system) {
        s.increment();
        system.increment();
      }, postcondition: (s, system) {
        return s.count == system.count;
      }),
      Action0('decrement', (s, system) {
        s.decrement();
        system.decrement();
      }, postcondition: (s, system) {
        return s.count == system.count;
      }),
      Action('set', integer(), (s, system, value) {
        s.count = value;
        system.count = value;
      }, postcondition: (s, system) {
        return s.count == system.count;
      }),
    ];
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  property('counter', () {
    runBehavior(CounterBehavior());
  });
}
