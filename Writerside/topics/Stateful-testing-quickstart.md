# Quickstart

シンプルなカウンターのステートフルテストを実装してみよう。
このカウンターはカウント数を持ち、次の操作を行える。

- カウントを1増やす
- カウントを1減らす
- リセット. カウントを0にする

このカウンターのステートフルテストを実装するには、モデルと実システムの2つの実装を用意する必要がある。
モデルとなる実装ではカウント数をメモリで保持し、実システムとなる実装では外部出力用に JSONに変換可能な値で保持するとしよう。
今回のテストでは、カウント操作が正しく行えるかを検査し、データ保持と出力に関してはテストを行わない。
そのため、モデルはカウント数をどのように保持しても問題ないとする。

モデルは参照実装として実システムと比較されるので、単純な実装が望ましい。コードは以下の通り:

```java
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

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
```

ステートフルテストを行うには、kiri_check/kiri_check.dartに加えてkiri_check/stateful_test.dart をimportする必要がある。

`CounterModel`がカウンターのモデル実装である。非常に単純で、単純にすべきである。



TODO: run,nextStateの順序について

```java
      Action0(
        'increment',
        nextState: (s) => s.increment(),
        run: (system) {
          system.increment();
          return system.count;
        },
        postcondition: (s, count) => s.count + 1 == count,
      ),
```

注意すべきは、`run`の次に呼ばれるのは`nextState`ではなく`postcondition`ということだ。
`run`を呼んで実システムに変更を加えたあと、`run`の任意の戻り値とモデルが`postcondition`に渡される。
このときのモデルの状態は、変更前の実システムに対応する。`run`の戻り値は、実システムの変更前後の差分を反映したデータが望ましい。
`postcondition`では、モデルの変更後の状態に対する`run`の戻り値が妥当かどうかを検査する。
まとめると、これらのメソッドは次の順序で実行される。

1. `run` が呼ばれる。実システムのカウントを増やし、増加後のカウントを返す。増加前のカウントが0であれば、増加後のカウントは1であり、戻り値も1になる。このとき、モデルが保持するカウントは0のままである。
2. `postcondition`が呼ばれる。カウント増加前のモデルと、`run`の戻り値である1(実システムの現在のカウント )が引数に渡される。モデルのカウントに1を足した結果が、`run`の戻り値である1と同じであれば、事後条件は成功となる。このとき、モデルに破壊的変更を加えるべきではない。
3. `nextState`が呼ばれる。モデルのカウントを増加し、次のコマンドの実行に移る。



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

- 最後にBehavior

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
