# Quickstart

## An example

シンプルなカウンターのステートフルテストを実装してみよう。
このカウンターはカウント数を持ち、次の操作を行える。

- カウントを1増やす
- カウントを1減らす
- リセット. カウントを0にする

ステートフルテストでは、これらの操作の組み合わせや実行順序に関係するバグを発見できる。

実システムのコードは以下の通り。
説明の都合により、カウント数はJSONで保持するとする。
実用的な設計ではないかもしれないが、実システムの実装は多かれ少なかれ複雑になるものだ。

```java
final class CounterSystem {
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
```

このカウンターのステートフルテストを実装するには、モデルとなる実装を用意する必要がある。
モデルは参照実装として実システムと比較される。そのため、できるだけ単純な実装が望ましい。

今回のテストではデータ保持と出力に関してはテストを行わないので、モデルはカウント数をどのように保持しても問題ない。
先の実システムではカウント数をJSONで保持するが、モデルでは単純に整数で保持することにする。

モデルのコードは以下の通り:

```java
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


## Behavior and commands

ここからはテスト内容を記述していく。
kiri-checkのステートフルテストでは、モデルと実システムに対してランダムな操作を複数回実行し、実行後の状態を照らし合わせて、実システムの実装に問題がないかどうかを検査する。
この操作をコマンドと呼び、具体的なコマンドはユーザーが定義する。
本章の例では、「カウント増」「カウント減」「リセット」の3つのコマンドを用意する。

コマンドの定義を含むテスト内容は、`Behavior`のサブクラスで定義する。まずはコードを以下に示す。

```Java
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';

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
```

ステートフルテストを行うには、 `kiri_check/kiri_check.dart` に加えて `kiri_check/stateful_test.dart` をインポートする。

`Behavior`を継承した`CounterBehavior`が今回のカウンターのテスト内容となる。
`Behavior`はモデルと実システムの2つの型パラメーターを持つので、今回の実装では先に定義した`CounterModel`と`CounterSystem`を指定する。

`Behavior`のサブクラスで実装しなければならないメソッドは、`initialState`, `createSystem`, `destroySystem`, `generateCommands` の4つ。

`initialState`はモデルを生成し、`createSystem`はそのモデルを利用して実システムを生成する。今回はそれぞれのオブジェクトを単純に生成するだけ。これらのオブジェクトが最初の状態になる。

`destroySystem`は実システムの終了処理を記述する。テスト終了時に呼ばれる。

`generateCommands`は、ランダムに実行されるコマンドのリストを生成する。リスト中のコマンドの順序はテストに影響しない。


## `Action` commands

コマンドはいくつか種類があるが、主に使うのは`Action`である。
`Action`はモデルと実システムに対して実行する関数を指定する。
アービトラリーを指定すると、ランダムに生成された値も利用できる。
今回使っている`Action0`はアービトラリーを使わないコマンドである。
`Action`コマンドは他に`Action2`から`Action8`まであり、それぞれ2つから8つまでのアービトラリーを使うことができる。

カウント増加コマンドの内容を見てみよう。

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

`Action0`の最初の引数はコマンド名で、ログの表示で使われる。`nextState`はモデル (state)の次の状態に遷移する関数を指定する。`run`は実システムを操作する関数を指定する。`postcondition`は事後条件を表し、真であればコマンド実行結果を成功とみなす。偽であれば失敗とみなし、シュリンクを開始する。

これらの関数は`run`, `postcondition`, `nextState`の順に呼ばれる。
注意すべきは、`run`の次に呼ばれるのは`nextState`ではなく`postcondition`ということだ。
`run`を呼んで実システムに変更を加えたあと、`run`の任意の戻り値とモデルが`postcondition`に渡される。
このときのモデルの状態は、変更前の実システムに対応する。`run`の戻り値は、実システムの変更前後の差分を反映したデータが望ましい。
`postcondition`では、モデルの変更後の状態に対する`run`の戻り値が妥当かどうかを検査する。`postcondition`の引数がシステムではなくモデルであることに困惑するかもしれないが、ステートフルテストの主体はモデルである。

もう少し具体的な挙動は以下の通り。

1. `run` が呼ばれる。実システムのカウントを増やし、増加後のカウントを返す。増加前のカウントが0であれば、増加後のカウントは1であり、戻り値も1になる。このとき、モデルが保持するカウントは0のままである。
2. `postcondition`が呼ばれる。カウント増加前のモデルと、`run`の戻り値である1(実システムの現在のカウント )が引数に渡される。モデルのカウントに1を足した結果が、`run`の戻り値である1と同じであれば、事後条件は成功となる。このとき、モデルに破壊的変更を加えるべきではない。
3. `nextState`が呼ばれる。モデルのカウントを増加し、次のコマンドの実行に移る。


## Run the test

`property`のブロック内で`runBehavior`を呼ぶ。
`runBehavior`は先に定義した`Behavior`を引数に受け取る。

```java
void main() {
property('counter', () {
runBehavior(CounterBehavior());
});
}
```

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

- [execution model](Stateful-testing.md#stateful-test-execution-model)を読み、ステートフルテストの挙動について知っておくとよい。
- `KiriCheck.verbosity` に `Verbosity.verbose` を指定し、ランダムに実行されるコマンドを確認してみよう。
- わざとエラーを埋め込んで、シュリンクの挙動を確認してみよう。
