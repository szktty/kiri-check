# Write stateful properties

## Writing process

- 手順
  - 抽象モデルと実システムのコードを用意する
  - Behaviorを定義する
    - テスト内容を指定
    - モデルと実システムの生成
    - ランダムに実行するコマンドを定義
  - Behaviorを実行する (runBehavior)
  - フローチャート


## Behavior lifecycle

- Behaviorのライフサイクル
- Behaviorオブジェクト自体は消えない
- setUp, createState, createSystem, generateCommands, 実行, dispose, tearDown
- disposeでリソースを解放する
- デフォルトではsetUp,dispose,tearDownの実装は空

- Behaviorを指定する
- BehaviorとState
- generateCommands
- 使用可能なコマンドはコマンドリファレンスを参照
- setUp, tearDown

- Behaviorの定義
- Behavior<T extends State>
  createState() → T
  generateCommands(T state) → List<Command<T>>

- Stateの定義

- コマンド
- コールバック
- 事前条件、事後条件、アクション
- アサーションは事後条件で表すべき


## Run the behavior

- テストファイル _test.dart を用意する
- import stateful_test
- runBehavior

```java
runBehavior(behavior);

void runBehavior<State, System>(
  Behavior<State, System> behavior, {
  int? maxShrinkingTries,
  int? seed,
  int? maxCycles,
  int? maxSteps,
  int? maxCommandTries,
  int? maxShrinkingCycles,
  Timeout? cycleTimeout,
  void Function()? setUp,
  void Function()? tearDown,
  void Function(Behavior<State, System>, State, System)? onDispose,
  void Function(StatefulFalsifyingExample<State, System>)? onFalsify,
  bool? ignoreFalsify,
);
```
