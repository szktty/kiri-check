<show-structure for="chapter,procedure" depth="2"/>

# Commands

## Generate values and perform actions

### `Action` {id="stateful-test-command-action"}

```java
Action<T extends State, U>(
  String description, 
  Arbitrary<U> arbitrary,
  void action(T), 
  {
    bool precondition(T)?, 
    bool postcondition(T)?, 
    T nextState(T)?,
  }
)
```

## Initialize and finalize

- 初期化と終了処理をコマンドにする必要がなければ、forAllStatesのsetUpとtearDownを使うとよい

### `Initialize` {id="stateful-test-command-initialize"}

```java
Initialize<T extends State>(
  String description, 
  Command<T> command, 
  {
    bool precondition(T)?, 
    bool postcondition(T)?, 
    T nextState(T)?,
  }
)
```

- Initializeで囲んだコマンドは必ず最初に実行される
- Initializeで囲んだコマンドは、2ステップ目以降は実行されない
- Initializeが複数ある場合、定義した順に実行される

### `Finalize` {id="stateful-test-command-finalize"}

```java
Finalize<T extends State>(
  String description,
  Command<T> command,
  {
    bool precondition(T)?,
    bool postcondition(T)?,
    T nextState(T)?,
  }
)
```

- Finalizeで囲んだコマンドは必ず最後に実行される
- Finalizeで囲んだコマンドは、最後のステップ以外は実行されない
- Finalizeが複数ある場合、定義した順に実行される