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
- また、ステートフルテストはモデル検査とは異なる。仕様の妥当性を検査するものではなく、実装に対するテストである
</note>

- 以下保留
- kiri-checkにおけるステートフルテストは、有限状態機械(FSM)に対する検証である
- 他のライブラリでは、ステートフルテストはモデルベースやルールベースとも呼ばれることがある
- kiri-checkのステートフルテストはモデル検査とは異なる。モデルのロジックの妥当性を検証するものではなく、状態変化処理が正しく実装されているかどうかを検証する。モデルの妥当性を検証したいのであれば、形式仕様記述言語などの他の方法を推奨する

## Model and commands

- 状態はコマンドの実行によって自身の内容を変更する。遷移するとも言う
- ステートフルテストは、ランダムに選択されたコマンド実行前後の状態に対して検証を行う
- 図: ステートフルテストのフローチャート

<code-block lang="mermaid">
    stateDiagram-v2
      direction TB
      [*] --> SelectingCommands
      SelectingCommands --> ExecuteCommands
      ExecuteCommands --> Shrinking: Failed
      ExecuteCommands --> [*]
      Shrinking --> [*]

      state SelectingCommands {
         direction TB
         Random --> PRECOND1
         PRECOND1 --> Adopt: Satisfied
         PRECOND1 --> Random: NotSatisfied
      }

      state ExecuteCommands {
         direction TB
        EachExec --> ExecuteCommand
        ExecuteCommand --> EachExec: Next

        state ExecuteCommand {
         direction TB
          PRECOND2 --> Execute
          PRECOND2 --> Shrinking: Failed
          Execute --> POSTCOND2
          POSTCOND2 --> Shrinking: Failed
        }
      }

      state Shrinking {
         direction TB
        EachShrink --> ShrinkCommand
        ShrinkCommand --> EachShrink: Next
        state ShrinkCommand {
          PRECOND3 --> Execute
          Execute --> POSTCOND3
        }
      }

      PRECOND1: Precondition
      PRECOND2: Precondition
      PRECOND3: Precondition
      POSTCOND1: Postcondition
      POSTCOND2: Postcondition
      POSTCOND3: Postcondition
</code-block>

## Execution model

- 3段階のフェーズ
- コマンド選択フェーズ
  - 実行対象のコマンドを生成する
  - 事前条件が偽でも失敗にはならず、コマンドは実行対象にならない
- コマンド実行フェーズ
  - 事前条件が偽の場合、失敗扱いになる
  - シュリンクを開始する




## Shrinking

- エラーが発生した場合、コマンド列を縮小する
- 部分列、削除、値の縮小
- 縮小されたコマンド列が最小のエラーを示す
