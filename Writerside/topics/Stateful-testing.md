# Stateful testing

## What should be tested

- 何をテストするのか
- kiri-checkのステートフルテストでは、抽象モデルと実システムの状態変化を照合する
- 抽象モデルとは、実システムのあるべき振る舞いを表現したもの
- ランダムなコマンドにより抽象モデルと実システムの状態を変化させ、実システムの状態がモデルと比較して妥当であるかを検証する
- そのため、抽象モデルの実装は正確かつシンプルにすべき

<note>
- 注釈
- これらをモデルベースと呼ばれることがあるが、kiri-checkでは名称に特にこだわらない
- 便宜的にモデルと呼んでいるだけで、テストの実体はFSMに対する検証である。抽象モデルも実システムも、必ずしも完全なモデルを表す必要はない
- また、kiri-checkのステートフルテストはモデル検査とは異なる。仕様の妥当性を検査するものではなく、実装に対するテストである
</note>

## Model and commands

- 状態はコマンドの実行によって自身の内容を変更する。遷移するとも言う
- ステートフルテストは、ランダムに選択されたコマンド実行前後の状態に対して検証を行う


## Execution model

- 3段階のフェーズ
- コマンド選択フェーズ
  - 実行対象のコマンドを生成する
  - 事前条件が偽でも失敗にはならず、コマンドは実行対象にならない
- コマンド実行フェーズ
  - 事前条件が偽の場合、失敗扱いになる
  - シュリンクを開始する

### Command generation phase

- コマンド生成フェーズでは抽象モデルのみ扱う。実システムは扱わない

<code-block lang="mermaid">
    stateDiagram-v2
      direction TB

         state if_init_precond <<choice>>

         [*] --> CreateState
         CreateState --> InitializePrecondition
         InitializePrecondition --> if_init_precond
         if_init_precond --> GenerateCommands: true
         if_init_precond --> Fail: false
          GenerateCommands --> GenerationLoop
          GenerationLoop --> [*]

         state GenerationLoop {
         state if_precond <<choice>>
         SelectCommand --> Precondition
         Precondition --> if_precond
         if_precond --> NextState: true
         if_precond --> Skip: false
        }

      SelectCommand: Randomly select
      Precondition: Command.precondition(State)
      CreateState: Behavior.createState()
      InitializePrecondition: Behavior.initializePrecondition(State)
      GenerateCommands: Behavior.generateCommands(State)
      GenerationLoop: Command selection loop
      NextState: Command.nextState(State)
</code-block>

- Behavior.craeteState()で抽象モデルを生成する
  - createState()はユーザーが定義すべきメソッド
- 生成したインスタンスはBehavior.initializePrecondition(State)で初期化時の事前条件をチェックする
  - 戻り値がfalseであればテストは失敗になる。
  - initializePrecondition()はユーザーが定義可能なメソッド。デフォルトの実装ではtrueを返す
  - 破壊的な変更を行うべきではない
- Behavior.generateCommands(State)で、実行すべきコマンドのリストを生成する
  - コマンドのリストのうち使用されるコマンドは、次のループで決定される
  - 生成時は抽象モデルのオブジェクトを参照可能
  - ユーザーが定義すべきメソッド
- 以降、生成したコマンドのリストから選択するループ。実行するコマンドのリストを抽出する
- ランダムにコマンドを一つ選び、そのコマンドに対してCommand.precondition(State)を実行する
  - 戻り値がfalseであればスキップして次のコマンド選択へ
  - 抽象モデルを参照可能
  - 破壊的な変更を行うべきではない
- Command.nextState(State)を実行し、抽象モデルの状態を変化させる。内容はコマンドに依存する
- 選択したコマンドが指定の数に達したら終了

### Execution phase

<code-block lang="mermaid">
    stateDiagram-v2
         direction TB

         state if_init_precond <<choice>>

          [*] --> CreateState
         CreateState --> InitializePrecondition
         InitializePrecondition --> if_init_precond
        if_init_precond --> CreateSystem: true
        if_init_precond --> Fail: false
        CreateSystem --> ExecutionLoop
        ExecutionLoop --> Dispose
        Dispose --> [*]

        state ExecutionLoop {
         direction TB
         state if_precond <<choice>>
         state if_postcond <<choice>>
          Precondition --> if_precond
          if_precond --> Run: true
          if_precond --> Shrinking: false
          Run --> Postcondition: Pass the return value
          Postcondition --> if_postcond
          if_postcond --> NextState: true
          if_postcond --> Shrinking: false
        }

      Precondition: Command.precondition(State)
      Postcondition: Command.postcondition(State, Result)
      CreateState: Behavior.createState()
      CreateSystem: Behavior.createSystem(State)
      InitializePrecondition: Behavior.initializePrecondition(State)
       ExecutionLoop: Execution loop
      NextState: Command.nextState(State)
      Run: Command.run(System)
      Dispose: Behavior.dispose(System)
</code-block>

- Behavior.initializePrecondition(State)までの処理はコマンド生成フェーズと同じ
- Behavior.createSystem(State)で実システムを生成する
- 以降では、コマンド生成フェーズで生成したコマンドのリストを順に実行する
- まず、Command.precondition(State)でコマンドの事前条件をチェックする
  - コマンド生成フェーズと異なり、結果がfalseであればシュリンクを開始する
  - コマンド生成フェーズの事前条件チェックとは状況が異なるので、ここで失敗する可能性もある
  - 破壊的な変更を行うべきではない
- Command.run(System) を実行し、実システムを操作する
  - アービトラリーを使うコマンドであれば、生成した値も使える
  - 何らかの例外が発生するとシュリンクを開始する
  - 任意の戻り値が次の処理(事後条件のチェック)で使われる
- Command.postconditionを実行し、事後条件をチェックする
  - falseであればシュリンク
  - コマンド実行後にあるべき状態の抽象モデルを生成し、実システムと比較するか、あるいは両者の変更の差分を比較する。問題がなければtrueを返し、あればfalseを返してシュリンクを開始する
  - 抽象モデルと、runの戻り値を使って事後条件をチェックする
  - アービトラリーを使うコマンドであれば、runで使ったのと同じ値を参照できる
  - nextStateが呼ばれる前に事後条件をチェックするので注意。この時点での抽象モデルの状態は、実システムのコマンド実行前と同じ
  - 抽象モデルに破壊的な変更を行うべきではない。このあとにnextStateが呼ばれる
- Command.nextStateで抽象モデルの状態を進める
- すべてのコマンドを実行するか、シュリンクが終了したら終了

## Shrinking

- エラーが発生した場合、コマンド列を縮小する
- 部分列、削除、値の縮小
- 縮小されたコマンド列が最小のエラーを示す
