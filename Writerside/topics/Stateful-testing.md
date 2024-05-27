# Stateful testing

- kiri-checkにおけるステートフルテストは、有限状態機械(FSM)に対する検証である
- 他のライブラリでは、ステートフルテストはモデルベースやルールベースとも呼ばれることがある
- kiri-checkのステートフルテストはモデル検査とは異なる。モデルのロジックの妥当性を検証するものではなく、状態変化処理が正しく実装されているかどうかを検証する。モデルの妥当性を検証したいのであれば、形式仕様記述言語などの他の方法を推奨する

- 以下、FSMを単に「状態」と呼ぶ

- 状態はコマンドの実行によって自身の内容を変更する。遷移するとも言う
- ステートフルテストは、ランダムに選択されたコマンド実行前後の状態に対して検証を行う
- 図: ステートフルテストのフローチャート

- 例として、シンプルなカウンターを考える
- 実際のテストコードはQuickstartを参照
- カウンターは0から始まり、インクリメント、デクリメント、リセットの3つのコマンドを受け付ける
- テストを実行すると、これらのコマンドがランダムに選択され、一定の回数が実行される。
- フローチャート
- 様々なコマンドがテストされることで、特定のコマンドの組み合わせや実行順序に関係するバグを発見できる
- エラーがあると、シュリンクによってコマンド列が切り詰められ、最小のエラーを見つける
 

## Write stateful properties

- import stateful_test
- forAllStates

```java
void forAllStates<T extends State>(
  Behavior<T> behavior,
  void body(T),
  {
    int? maxExamples,
    int? maxTries,
    int? maxShrinkingTries,
    RandomContext? random,
    int? seed,
    GenerationPolicy? generationPolicy,
    ShrinkingPolicy? shrinkingPolicy,
    EdgeCasePolicy? edgeCasePolicy,
    int? maxStatefulCycles,
    int? maxStatefulSteps,
    void setUp()?,
    void tearDown()?,
    void onGenerate(T)?,
    void onShrink(T)?,
    void onFalsify(T)?,
    bool? ignoreFalsify,
    @internal void onCheck(void ())?
  }
)
```

- Behaviorを指定する
- BehaviorとState
- generateCommands
- 使用可能なコマンドはコマンドリファレンスを参照

- Behaviorの定義
- Behavior<T extends State>
createState() → T
generateCommands(T state) → List<Command<T>>

- nextState
- nextStateを定義してimmutableな状態を扱うと、状態をクリーンに保てる。意図しないコマンドの副作用を防げる

- Stateの定義
- setUp() → void
  tearDown() → void

- コマンド
- コールバック
- 事前条件、事後条件、アクション
- アサーションは事後条件で表すべき

- シュリンク
- パスと値
