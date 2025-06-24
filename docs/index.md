---
layout: home

hero:
  name: "kiri-check"
  text: "Property-based testing for Dart/Flutter"
  tagline: "Generate test data automatically and shrink counterexamples"
  actions:
    - theme: brand
      text: Get Started
      link: /quickstart
    - theme: alt
      text: View on pub.dev
      link: https://pub.dev/packages/kiri_check

features:
  - title: Quick Start
    details: Learn how to set up and quickly write properties
    link: /quickstart
  - title: Arbitraries
    details: Arbitraries provide test data generation and shrink counterexamples
    link: /arbitraries

  - title: Write Properties
    details: Write property-based tests using arbitraries
    link: /properties/write-properties
  - title: Configure Tests
    details: Customize test settings
    link: /properties/configure-tests
  - title: Integration
    details: Add properties to existing tests using package:test
    link: /properties/write-properties#integrate-with-package-test

  - title: Basic Data Types
    details: Generate nulls, booleans, numbers, etc.
    link: /arbitraries#basic-data-types
  - title: Strings
    details: Generate runes and strings
    link: /arbitraries#strings
  - title: Collections
    details: Generate lists, maps, sets
    link: /arbitraries#collections
  - title: Composition
    details: Combine existing arbitraries to generate new ones
    link: /arbitraries#composition
  - title: Custom Data Types
    details: Write new arbitraries to create values of custom data types
    link: /arbitraries#custom-data-types
  - title: Generate Outside Tests
    details: Generate values outside of tests
    link: /arbitraries#generate-values-outside-of-tests

  - title: Generation Control
    details: Manage or influence the generation of test data
    link: /generation
  - title: Edge Cases
    details: Generate tests for edge cases
    link: /generation#generate-edge-cases
  - title: Generate Enums
    details: Use arbitraries to generate enum values
    link: /generation#generate-enums
  - title: Shrinking
    details: Overview of the shrinking process behavior
    link: /shrinking
  - title: Statistics
    details: Collect metrics for a test
    link: /statistics

  - title: Stateful Quickstart
    details: Learn how to set up and quickly write stateful properties
    link: /stateful/quickstart
  - title: Stateful Properties
    details: Write properties for stateful testing
    link: /stateful/properties
  - title: Commands
    details: Behavior and commands provide test specification
    link: /stateful/commands
  - title: Execution Model
    details: Execution model and cycle structure of stateful testing
    link: /stateful/#stateful-test-execution-model
---