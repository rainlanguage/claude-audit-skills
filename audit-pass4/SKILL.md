---
name: audit-pass4
description: "Audit Pass 4: Code Quality. Reviews for style consistency, leaky abstractions, commented-out code, build warnings, and dependency consistency."
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Pass 4: Code Quality

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Pass 4 Instructions

Review for maintainability, consistency, and good abstractions, including but not limited to:

- Audit for style consistency across the repo — when similar code uses different patterns for the same thing, flag it
- Identify leaky abstractions: internal details exposed through public interfaces, implementation concerns bleeding across module boundaries, or tight coupling between components that should be independent
- Review all commented-out code — each instance should be either reinstated or deleted, not left commented
- Ensure no warnings from the project's build toolchain — build warnings are real problems (LOW or higher), not INFO
- Check that all dependency versions are consistent (no conflicting versions of the same dependency)
- Flag bare `src/` import paths in **all** Solidity files, including test and script files (e.g., `import ... from "src/lib/Foo.sol"`). These break when the project is used as a git submodule because `src/` resolves to the consuming project's source directory, not the submodule's. Use relative paths (e.g., `../../src/lib/Foo.sol`) or remapped paths (e.g., `projectname/lib/Foo.sol`) instead. Do not dismiss test file occurrences as "out of scope" — tests must also compile when the repo is a dependency.

## Test Utility Awareness

Before reviewing test files, read all existing test utility libraries and abstract helpers:
- Glob `test/util/lib/*.sol` and `test/util/abstract/*.sol` and read each file
- Understand what helpers, builders, and abstractions already exist

When reviewing a test file, flag inline boilerplate that duplicates or could use an existing helper. Examples:
- Manually building `TakeOrdersConfigV5` structs when `LibTestTakeOrder.defaultTakeConfig` exists
- Inline log decoding when `LibTestTakeOrder.extractOrderFromLogs` exists
- Repeated order-creation patterns when `LibTestTakeOrder.addOrderWithExpression` exists
- Any repeated multi-line pattern across test files that could be a shared helper

This is a cross-file concern: the goal is to ensure test code stays DRY by using the project's existing test utilities rather than reinventing them inline.
