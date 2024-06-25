# Write stateful properties

## Import the library

To perform stateful testing, in addition to importing `kiri_check/kiri_check.dart`, you need to import `kiri_check/stateful_test.dart`.

Example:

```Java
import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
```

## Write process

The stateful testing process is divided into three steps: preparing the model and the real system, defining the `Behavior` class, and executing it.

1. **Implement the model and the real system**

   To perform stateful testing, first prepare the code for the model and the real system. The model serves as a reference for comparison with the real system. There are no specific classes that need to be inherited, so feel free to implement them as you like.

2. **Define the Behavior**

   Define a `Behavior` class and specify the test content. Specifically, include the following three elements:

   - **Generate the model and the real system**: The `initialState` method generates the abstract model, and the `createSystem` method generates the real system using that model. These objects represent the initial state of the test.
   - **Terminate the real system**: Override the `destroySystem` method to describe the termination process of the real system at the end of the test.
   - **Define the commands to be executed randomly**: The `generateCommands` method generates a list of commands that will be executed randomly during the test.

3. **Execute the Behavior**

   Execute the defined `Behavior`. Use the `runBehavior` function to start the test.

For specific examples, refer to the [Quickstart](Stateful-testing-quickstart.md).
