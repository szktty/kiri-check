# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

kiri-check is a property-based testing library for Dart that integrates with `package:test`. It provides two main testing approaches:

1. **Property-based testing**: Generate random test data and verify properties hold across many inputs
2. **Stateful testing**: Test systems that change state over time using model-based testing

## Development Commands

### Testing
- `dart test` - Run all tests
- `dart test -p chrome` - Run tests on web platform
- `dart test test/specific_test.dart` - Run a specific test file

### Code Quality
- `dart fix --apply lib test` - Auto-fix linting issues
- `dart format lib test` - Format code
- `make fix` - Apply fixes and format (combines above)

### Documentation
- `dart doc` - Generate API documentation
- `make dhttpd` - Serve documentation locally

### Analysis
- `pana .` - Run pub points analysis

## Architecture

### Core Modules

**lib/src/arbitrary/**: Data generation system
- `core/` - Basic generators (integers, strings, lists, etc.)
- `combinator/` - Combining generators (build, combine, oneOf, frequency)
- `manipulation/` - Transform generators (map, filter, flatMap)

**lib/src/property/**: Property-based testing engine
- Executes property tests with `forAll()` function
- Handles test data generation, shrinking, and statistics

**lib/src/state/**: Stateful testing framework
- Model-based testing using `Behavior` abstract class
- Command/Action pattern for system operations
- Supports async operations and lifecycle management

**lib/src/helpers/**: Utilities
- Unicode character sets and data
- DateTime helpers
- Internal utilities

### Key Patterns

- **Builder Pattern**: Fluent API for configuring arbitraries (e.g., `integer(min: 0, max: 100)`)
- **Command Pattern**: Stateful tests use `Action0`, `Action1`, etc. for system operations
- **Template Method**: `Behavior` class defines the testing lifecycle

### Testing Integration

- Wraps `package:test` functions - use `property()` instead of `test()`
- Property tests use `forAll()` with arbitrary generators
- Stateful tests use `runBehavior()` with custom `Behavior` implementations
- Standard `expect()` assertions work within property tests

## Important Files

- `lib/kiri_check.dart` - Main API for property-based testing
- `lib/stateful_test.dart` - Additional API for stateful testing
- `test/` structure mirrors `lib/src/` for comprehensive coverage
- `example/` contains basic usage examples

## Testing Philosophy

The library extensively tests itself using property-based testing. When working on the codebase:
- Property tests should validate invariants across many random inputs
- Stateful tests should compare abstract models with concrete implementations
- Edge cases are automatically generated and tested
- Shrinking helps find minimal failing cases