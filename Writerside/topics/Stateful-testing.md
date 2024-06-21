<show-structure for="chapter,procedure" depth="2"/>

# Stateful testing

<note>
The implementation of stateful testing is in beta, and the API may change in the future.
</note>

## What should be tested

In stateful testing, the validity of the behavior of a stateful system is examined.
Random operations, called commands, are repeatedly executed on the real system, and the states before and after these operations are compared with those of a separately implemented model.

If an error occurs during execution or the comparison with the model is invalid, shrinking is performed similarly to stateless testing.
Shrinking in stateful testing aims to find the minimal combination of commands and values that cause the failure.


## Execution model {id="stateful-test-execution-model"}

In stateful testing, tests are divided into multiple cycles. Each cycle consists of initializing the state and system, performing steps of random commands, and verifying the postconditions of commands.

Each cycle is executed in two phases. The first phase involves generating the commands to be executed, and the second phase involves executing these commands. In the second phases, if an error occurs or a check fails, shrinking begins.


### Command generation phase

In the command generation phase, commands to be executed are randomly generated. This phase only involves the model, and the real system is not yet created.

The following diagram illustrates the command generation phase:

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
      CreateState: Behavior.initializeState()
      InitializePrecondition: Behavior.initializePrecondition(State)
      GenerateCommands: Behavior.generateCommands(State)
      GenerationLoop: Command selection loop
      NextState: Command.nextState(State)
</code-block>

The process begins with `Behavior.createState()`, which generates the model. This method, `initializeState()`, should be defined by the user. The generated instance is then checked for initialization preconditions using `Behavior.initializePrecondition(State)`. If the return value is false, the test fails. `initializePrecondition()` is a method that can be defined by the user and by default returns true. It is important that no destructive changes are made during this check.

Next, `Behavior.generateCommands(State)` generates a list of commands to be executed. This method allows the model object to be referenced during generation and should be defined by the user. The commands to be used are determined in the subsequent loop.

The command selection loop begins, where commands are selected from the generated list. A command is randomly chosen, and `Command.precondition(State)` is executed for that command. If the return value is false, the process skips to the next command selection. The model can be referenced during this check, and no destructive changes should be made.

If the precondition check passes, `Command.nextState(State)` is executed to change the state of the model according to the command. This loop continues until the specified number of commands has been selected and executed.


### Execution phase

In the execution phase, the generated commands are applied to the real system for testing.

The following diagram illustrates the execution phase:

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
      CreateState: Behavior.initializeState()
      CreateSystem: Behavior.createSystem(State)
      InitializePrecondition: Behavior.initializePrecondition(State)
       ExecutionLoop: Execution loop
      NextState: Command.nextState(State)
      Run: Command.run(System)
      Dispose: Behavior.destroy(System)
</code-block>

The process up to `Behavior.initializePrecondition(State)` is the same as in the command generation phase. `Behavior.createSystem(State)` then generates the real system. Next, the list of commands generated in the command generation phase is executed in sequence.

First, `Command.precondition(State)` checks the precondition of the command. Unlike the command generation phase, if the result is false, shrinking begins. Since the situation is different from the command generation phase, it is possible for a command to fail here. No destructive changes should be made.

`Command.run(System)` is executed to manipulate the real system. If the command uses arbitraries, the generated values are also used. If any exception occurs, shrinking begins. The return value is used in the next step (postcondition check).

`Command.postcondition(State, Result)` is executed to check the postcondition. If the result is false, shrinking begins. The postcondition verifies the expected state of the model against the real system after the command execution, or compares the differences between the two. If there are no issues, it returns true; otherwise, it returns false and shrinking begins. The model and the return value of `run` are used to check the postcondition.

If the command uses arbitraries, the same values used in `run` are referenced. Note that the postcondition is checked before `nextState` is called. At this point, the state of the model is the same as before the command execution in the real system. No destructive changes should be made to the model. `nextState` will be called afterward.

Finally, `Command.nextState(State)` progresses the state of the model. The process ends when all commands are executed or shrinking completes.


## Shrinking

When an error occurs, the test initiates a process called shrinking. The goal of shrinking is to identify the minimal sequence of commands that causes the failure. This process is divided into three phases.

First, the sequence of commands that caused the error is split into several partial sequences. This allows us to determine which partial sequence still causes the error. In the diagram below, the original sequence of commands is divided into three partial sequences. Each partial sequence is tested to see if the error can be reproduced, and the partial sequence that reproduces the error is carried forward to the next phase.

Next, the selected partial sequence is further reduced by removing unnecessary commands to identify the minimal sequence that causes the error. In this phase, commands within the partial sequence are removed one by one to see which combinations still cause the error. The diagram shows how the sequence is minimized to identify the smallest sequence that still causes the error.

Finally, the arguments or generated values of the commands are shrunk. In this phase, the values used in the commands are reduced or simplified to see if the error still occurs. This helps identify the minimal combination of values that causes the error. The example in the diagram shows the final shrunk values.

The following diagram illustrates the process from error occurrence to shrinking, ultimately identifying the minimal sequence of commands that causes the error:

<code-block lang="mermaid">
flowchart TB
  phase0 -->|Split into sequences| phase1
  phase1 -->|Fail: 2 4 4 6| phase2
  phase2 -->|Minimum sequence: 2 6| phase3
  phase3 -->|Minimum values: 0 1| result

  subgraph phase0 [Failed sequence]
  direction LR
  p0c1[1] ~~~ p0c2[5] ~~~ p0c3[7] ~~~ p0c4[3] ~~~ p0c5[2] ~~~ p0c6[4] ~~~ p0c7[4] ~~~ p0c8[6] ~~~ p0c9[2] ~~~ p0c10[8] ~~~ p0c11[1] ~~~ p0c12[7]
  end

  subgraph phase1 [Phase 1: Partial sequences]
  direction LR
  phase1a ~~~ phase1b ~~~ phase1c
  subgraph phase1a [ ]
  direction LR
  p2s1[1] ~~~ p2s2[5] ~~~ p2s3[7] ~~~ p2s4[3]
  end
  subgraph phase1b [ ]
  direction LR
  p2s5[2] ~~~ p2s6[4] ~~~ p2s7[4] ~~~ p2s8[6]
  end
  subgraph phase1c [ ]
  direction LR
  p2s9[2] ~~~ p2s10[8] ~~~ p2s11[1] ~~~ p2s12[7]
  end
  end

  subgraph phase2 [Phase 2: Reduced sequences]
  phase2a ~~~ phase2b ~~~ phase2c
  subgraph phase2a [Reduced: 2]
  direction LR
  p2a1[4] ~~~ p2a2[4] ~~~ p2a3[6]
  end
  subgraph phase2b [Reduced: 4]
  direction LR
  p2b1[2] ~~~ p2b2[6]
  end
  subgraph phase2c [Reduced: 6]
  direction LR
  p2c1[2] ~~~ p2c2[4] ~~~ p2c3[4]
  end
  end

  subgraph phase3 [Phase 3: Shrinking values]
  direction TB
  phase3a --> phase3b
  phase3b --> phase3c[Repeat]
  subgraph phase3a [ ]
  direction LR
  p3a1[2] ~~~ p3a2[6]
  end
  subgraph phase3b [ ]
  direction LR
  p3b1[1] ~~~ p3b2[3]
  end
  end

  subgraph result [Falsifying sequence]
  direction LR
  r1[0] ~~~ r2[1]
  end
</code-block>
