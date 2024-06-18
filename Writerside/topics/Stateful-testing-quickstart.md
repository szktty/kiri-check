# Quickstart

- シンプルなカウンター
- 抽象モデルと実システムを用意する
- ここでは、実システムはJSONに変換可能なオブジェクトで値を保持する

- 抽象モデルの定義
- increase, decrease, reset
- preconditionは0以上の値とする
- preconditionはモデルのみ
- postcondition で実システムと比較する

- 以下はQuickstartを参照してもらう
- 例として、シンプルなカウンターを考える
- ライブラリの使い方の例示なので、今回は実システムは用意しない。コマンドの実行前後のモデルの状態を比較するだけとする
- 実システムはNullとする
- 実際のテストコードはQuickstartを参照
- カウンターは0から始まり、インクリメント、デクリメント、リセットの3つのコマンドを受け付ける
- テストを実行すると、これらのコマンドがランダムに選択され、一定の回数が実行される。
- フローチャート
- 様々なコマンドがテストされることで、特定のコマンドの組み合わせや実行順序に関係するバグを発見できる
- エラーがあると、シュリンクによってコマンド列が切り詰められ、最小のエラーを見つける

## Complete code

```java
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

// Abstract model representing accurate specifications
// with concise implementation.
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

// Real system compared with the behavior of the model.
final class CounterSystem {
  // Assume that it is operated in JSON object.
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

// Definition of stateful test content.
final class CounterBehavior extends Behavior<CounterModel, CounterSystem> {
  @override
  CounterModel initialState() {
    return CounterModel();
  }

  @override
  CounterSystem createSystem(CounterModel s) {
    return CounterSystem();
  }

  @override
  List<Command<CounterModel, CounterSystem>> generateCommands(CounterModel s) {
    return [
      Action0(
        'reset',
        nextState: (s) => s.reset(),
        run: (system) {
          system.reset();
          return system.count;
        },
        postcondition: (s, count) => count == 0,
      ),
      Action0(
        'increment',
        nextState: (s) => s.increment(),
        run: (system) {
          system.increment();
          return system.count;
        },
        postcondition: (s, count) => s.count + 1 == count,
      ),
      Action0(
        'decrement',
        nextState: (s) => s.decrement(),
        run: (system) {
          system.decrement();
          return system.count;
        },
        postcondition: (s, count) => s.count - 1 == count,
      ),
    ];
  }

  @override
  void destroySystem(CounterSystem system) {}
}

void main() {
  property('counter', () {
    // Run a stateful test.
    runBehavior(CounterBehavior());
  });
}
```

## Where to next?
