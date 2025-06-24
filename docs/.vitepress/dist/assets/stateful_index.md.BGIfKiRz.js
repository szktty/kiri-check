import{_ as p,C as e,c as h,o,G as a,j as n,ae as r,a as i,w as d}from"./chunks/framework.XMIap9gs.js";const b=JSON.parse('{"title":"Stateful testing","description":"","frontmatter":{},"headers":[],"relativePath":"stateful/index.md","filePath":"stateful/index.md"}'),c={name:"stateful/index.md"};function E(k,s,g,m,u,y){const t=e("show-structure"),l=e("note");return o(),h("div",null,[a(t,{for:"chapter,procedure",depth:"2"}),s[1]||(s[1]=n("h1",{id:"stateful-testing",tabindex:"-1"},[i("Stateful testing "),n("a",{class:"header-anchor",href:"#stateful-testing","aria-label":'Permalink to "Stateful testing"'},"​")],-1)),a(l,null,{default:d(()=>s[0]||(s[0]=[i(" The implementation of stateful testing is in beta, and the API may change in the future. ")])),_:1,__:[0]}),s[2]||(s[2]=r(`<h2 id="what-should-be-tested" tabindex="-1">What should be tested <a class="header-anchor" href="#what-should-be-tested" aria-label="Permalink to &quot;What should be tested&quot;">​</a></h2><p>In stateful testing, the validity of the behavior of a stateful system is examined. Random operations, called commands, are repeatedly executed on the real system, and the states before and after these operations are compared with those of a separately implemented model.</p><p>If an error occurs during execution or the comparison with the model is invalid, shrinking is performed similarly to stateless testing. Shrinking in stateful testing aims to find the minimal combination of commands and values that cause the failure.</p><h2 id="stateful-test-execution-model" tabindex="-1">Execution model <a class="header-anchor" href="#stateful-test-execution-model" aria-label="Permalink to &quot;Execution model {id=&quot;stateful-test-execution-model&quot;}&quot;">​</a></h2><p>In stateful testing, tests are divided into multiple cycles. Each cycle consists of initializing the state and system, performing steps of random commands, and verifying the postconditions of commands.</p><p>Each cycle is executed in two phases. The first phase involves generating the commands to be executed, and the second phase involves executing these commands. In the second phases, if an error occurs or a check fails, shrinking begins.</p><h3 id="command-generation-phase" tabindex="-1">Command generation phase <a class="header-anchor" href="#command-generation-phase" aria-label="Permalink to &quot;Command generation phase&quot;">​</a></h3><p>In the command generation phase, commands to be executed are randomly generated. This phase only involves the model, and the real system is not yet created.</p><p>The following diagram illustrates the command generation phase:</p><div class="language-mermaid vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">mermaid</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">stateDiagram-v2</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction TB</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  [*] --&gt; CreateState</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  CreateState --&gt; InitializePrecondition</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  InitializePrecondition --&gt; if_init_precond</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  state if_init_precond &lt;&lt;choice&gt;&gt;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  if_init_precond --&gt; GenerateCommands: true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  if_init_precond --&gt; Fail: false</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  GenerateCommands --&gt; GenerationLoop</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  GenerationLoop --&gt; [*]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  state GenerationLoop {</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    direction TB</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    SelectCommand --&gt; Precondition</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    state if_precond &lt;&lt;choice&gt;&gt;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    Precondition --&gt; if_precond</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    if_precond --&gt; NextState: true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    if_precond --&gt; Skip: false</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  }</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  SelectCommand: Randomly select</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  Precondition: Command.precondition(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  CreateState: Behavior.initializeState()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  InitializePrecondition: Behavior.initializePrecondition(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  GenerateCommands: Behavior.generateCommands(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  GenerationLoop: Command selection loop</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  NextState: Command.nextState(State)</span></span></code></pre></div><p>The process begins with <code>Behavior.initializeState()</code>, which generates the model. This method, <code>initializeState()</code>, should be defined by the user. The generated instance is then checked for initialization preconditions using <code>Behavior.initializePrecondition(State)</code>. If the return value is false, the test fails. <code>initializePrecondition()</code> is a method that can be defined by the user and by default returns true. It is important that no destructive changes are made during this check.</p><p>Next, <code>Behavior.generateCommands(State)</code> generates a list of commands to be executed. This method allows the model object to be referenced during generation and should be defined by the user. The commands to be used are determined in the subsequent loop.</p><p>The command selection loop begins, where commands are selected from the generated list. A command is randomly chosen, and <code>Command.precondition(State)</code> is executed for that command. If the return value is false, the process skips to the next command selection. The model can be referenced during this check, and no destructive changes should be made.</p><p>If the precondition check passes, <code>Command.nextState(State)</code> is executed to change the state of the model according to the command. This loop continues until the specified number of commands has been selected and executed.</p><h3 id="execution-phase" tabindex="-1">Execution phase <a class="header-anchor" href="#execution-phase" aria-label="Permalink to &quot;Execution phase&quot;">​</a></h3><p>In the execution phase, the generated commands are applied to the real system for testing.</p><p>The following diagram illustrates the execution phase:</p><div class="language-mermaid vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">mermaid</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    stateDiagram-v2</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         direction TB</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         state if_init_precond &lt;&lt;choice&gt;&gt;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          [*] --&gt; CreateState</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         CreateState --&gt; InitializePrecondition</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         InitializePrecondition --&gt; if_init_precond</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        if_init_precond --&gt; CreateSystem: true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        if_init_precond --&gt; Fail: false</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        CreateSystem --&gt; ExecutionLoop</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        ExecutionLoop --&gt; Dispose</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        Dispose --&gt; [*]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        state ExecutionLoop {</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         direction TB</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         state if_precond &lt;&lt;choice&gt;&gt;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">         state if_postcond &lt;&lt;choice&gt;&gt;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          Precondition --&gt; if_precond</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          if_precond --&gt; Run: true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          if_precond --&gt; Shrinking: false</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          Run --&gt; Postcondition: Pass the return value</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          Postcondition --&gt; if_postcond</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          if_postcond --&gt; NextState: true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          if_postcond --&gt; Shrinking: false</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        }</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      Precondition: Command.precondition(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      Postcondition: Command.postcondition(State, Result)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      CreateState: Behavior.initializeState()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      CreateSystem: Behavior.createSystem(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      InitializePrecondition: Behavior.initializePrecondition(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">       ExecutionLoop: Execution loop</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      NextState: Command.nextState(State)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      Run: Command.run(System)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">      Dispose: Behavior.destroy(System)</span></span></code></pre></div><p>The process up to <code>Behavior.initializePrecondition(State)</code> is the same as in the command generation phase. <code>Behavior.createSystem(State)</code> then generates the real system. Next, the list of commands generated in the command generation phase is executed in sequence.</p><p>First, <code>Command.precondition(State)</code> checks the precondition of the command. Unlike the command generation phase, if the result is false, shrinking begins. Since the situation is different from the command generation phase, it is possible for a command to fail here. No destructive changes should be made.</p><p><code>Command.run(System)</code> is executed to manipulate the real system. If the command uses arbitraries, the generated values are also used. If any exception occurs, shrinking begins. The return value is used in the next step (postcondition check).</p><p><code>Command.postcondition(State, Result)</code> is executed to check the postcondition. If the result is false, shrinking begins. The postcondition verifies the expected state of the model against the real system after the command execution, or compares the differences between the two. If there are no issues, it returns true; otherwise, it returns false and shrinking begins. The model and the return value of <code>run</code> are used to check the postcondition.</p><p>If the command uses arbitraries, the same values used in <code>run</code> are referenced. Note that the postcondition is checked before <code>nextState</code> is called. At this point, the state of the model is the same as before the command execution in the real system. No destructive changes should be made to the model. <code>nextState</code> will be called afterward.</p><p>Finally, <code>Command.nextState(State)</code> progresses the state of the model. The process ends when all commands are executed or shrinking completes.</p><h2 id="shrinking" tabindex="-1">Shrinking <a class="header-anchor" href="#shrinking" aria-label="Permalink to &quot;Shrinking&quot;">​</a></h2><p>When an error occurs, the test initiates a process called shrinking. The goal of shrinking is to identify the minimal sequence of commands that causes the failure. This process is divided into three phases.</p><p>First, the sequence of commands that caused the error is split into several partial sequences. This allows us to determine which partial sequence still causes the error. In the diagram below, the original sequence of commands is divided into three partial sequences. Each partial sequence is tested to see if the error can be reproduced, and the partial sequence that reproduces the error is carried forward to the next phase.</p><p>Next, the selected partial sequence is further reduced by removing unnecessary commands to identify the minimal sequence that causes the error. In this phase, commands within the partial sequence are removed one by one to see which combinations still cause the error. The diagram shows how the sequence is minimized to identify the smallest sequence that still causes the error.</p><p>Finally, the arguments or generated values of the commands are shrunk. In this phase, the values used in the commands are reduced or simplified to see if the error still occurs. This helps identify the minimal combination of values that causes the error. The example in the diagram shows the final shrunk values.</p><p>The following diagram illustrates the process from error occurrence to shrinking, ultimately identifying the minimal sequence of commands that causes the error:</p><div class="language-mermaid vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">mermaid</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">flowchart TB</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  phase0 --&gt;|Split into sequences| phase1</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  phase1 --&gt;|Fail: 2 4 4 6| phase2</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  phase2 --&gt;|Minimum sequence: 2 6| phase3</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  phase3 --&gt; result</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase0 [Failed sequence]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p0c1[1] ~~~ p0c2[5] ~~~ p0c3[7] ~~~ p0c4[3] ~~~ p0c5[2] ~~~ p0c6[4] ~~~ p0c7[4] ~~~ p0c8[6] ~~~ p0c9[2] ~~~ p0c10[8] ~~~ p0c11[1] ~~~ p0c12[7]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase1 [Phase 1: Partial sequences]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  phase1a ~~~ phase1b ~~~ phase1c</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase1a [ ]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p2s1[1] ~~~ p2s2[5] ~~~ p2s3[7] ~~~ p2s4[3]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase1b [ ]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p2s5[2] ~~~ p2s6[4] ~~~ p2s7[4] ~~~ p2s8[6]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase1c [ ]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p2s9[2] ~~~ p2s10[8] ~~~ p2s11[1] ~~~ p2s12[7]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase2 [Phase 2: Reduced sequences]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  phase2a ~~~ phase2b ~~~ phase2c</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase2a [Reduced: 2]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p2a1[4] ~~~ p2a2[4] ~~~ p2a3[6]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase2b [Reduced: 4]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p2b1[2] ~~~ p2b2[6]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase2c [Reduced: 6]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  p2c1[2] ~~~ p2c2[4] ~~~ p2c3[4]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph phase3 [Phase 3: Shrinking values]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  subgraph result [Falsifying sequence with minimum values]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  direction LR</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  r1[2] ~~~ r2[6]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">  end</span></span></code></pre></div>`,31))])}const x=p(c,[["render",E]]);export{b as __pageData,x as default};
