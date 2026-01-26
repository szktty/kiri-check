# AGENTS.md

This file provides guidance to AI code assistants when working with code in this repository.

## 1. Project Overview

kiri-check is a property-based testing library for Dart and Flutter that integrates with `package:test`. Inspired by functional programming concepts, it provides two main testing approaches:

1.  **Property-based testing (Stateless)**: Generate random test data and verify that specific properties hold true across a wide range of inputs.
2.  **Stateful testing (Model-based)**: Test systems that change state over time by comparing the behavior of a real system against a simplified abstract model.

## 2. Development Environment

To set up the local development environment, run the following command to fetch dependencies:

```bash
dart pub get
```

## 3. Key Development Commands

### Testing

-   `dart test`: Run all tests on the Dart VM.
-   `dart test -p chrome`: Run all tests on the Chrome web platform.
-   `dart test <path_to_file>`: Run a specific test file.

### Code Quality & Formatting

-   `dart analyze`: Run static analysis to find potential errors and style issues.
-   `dart format .`: Format all code in the project.
-   `dart fix --apply`: Apply automatic fixes for linting issues.
-   `make fix`: A convenient shorthand that applies fixes and formats the code. **Prefer this command.**

### Documentation

-   `dart doc`: Generate API documentation locally.
-   `make dhttpd`: Serve the generated documentation on a local web server.

### Pub.dev Analysis

-   `pana .`: Run the `pana` tool to analyze the project for pub.dev scoring.

## 4. Project Architecture

### Core Modules

-   **`lib/src/arbitrary/`**: The data generation system.
    -   `core/`: Basic generators (integers, strings, lists, etc.).
    -   `combinator/`: Tools for combining generators (`build`, `combine`, `oneOf`, `frequency`).
    -   `manipulation/`: Tools for transforming generators (`map`, `filter`, `flatMap`).
-   **`lib/src/property/`**: The engine for property-based (stateless) testing.
    -   Executes tests defined with the `forAll()` function.
    -   Manages data generation, shrinking of failing examples, and statistics collection.
-   **`lib/src/state/`**: The framework for stateful testing.
    -   Uses a model-based approach with the `Behavior` abstract class.
    -   Employs the Command pattern (`Action0`, `Action1`, etc.) to define system operations.
-   **`lib/src/helpers/`**: Internal utilities, including Unicode data and DateTime helpers.

### Key Design Patterns

-   **Builder Pattern**: Used for a fluent API to configure arbitraries (e.g., `integer(min: 0, max: 100)`).
-   **Command Pattern**: Stateful tests use `Action` classes to represent operations on the system and model.
-   **Template Method Pattern**: The `Behavior` class defines the skeleton of the stateful testing lifecycle, allowing users to override specific steps.

## 5. Branching & Commit Strategy

### Branching

Follow this naming convention for branches:
-   `feature/<description>`: For new features.
-   `fix/<description>`: For bug fixes.
-   `docs/<description>`: For documentation changes.
-   `chore/<description>`: For maintenance tasks (e.g., dependency updates).
-   `release/vX.X.X`: For preparing a new release.

### Commits

Use the [Conventional Commits](https://www.conventionalcommits.org/) specification. The commit type must be one of the following: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

Example:
```
fix(stateful): Await async nextState in Action command
```

## 6. Release Process

1.  Create a `release/vX.X.X` branch from `develop`.
2.  Update the version number in `pubspec.yaml`.
3.  Update `CHANGELOG.md`: Move changes from `## develop` to a new `## vX.X.X` section.
4.  Update version numbers in documentation, such as `README.md`.
5.  Commit the changes with the message `release: vX.X.X`.
6.  Merge the release branch into `main` and then into `develop`.
7.  On the `main` branch, create a Git tag: `git tag vX.X.X`.
8.  Push all branches and the new tag to the remote: `git push origin main develop vX.X.X`.
9.  The `publish.yml` GitHub Actions workflow will automatically publish the new version to `pub.dev` when a tag is pushed.

## 7. Testing Philosophy

The library is extensively tested using its own property-based testing capabilities. When contributing:

-   Add or update tests for any new features or bug fixes.
-   Use property-based tests (`forAll`) to validate invariants across many random inputs.
-   Use stateful tests (`runBehavior`) to compare abstract models with concrete implementations, especially for stateful components.
-   Ensure that shrinking effectively minimizes failing test cases.
