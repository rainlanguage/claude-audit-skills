---
name: audit-pass5
description: "Audit Pass 5: Correctness / Intent Verification. Verifies that code, tests, and documentation actually do what they claim to do."
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Pass 5: Correctness / Intent Verification

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Pass 5 Instructions

For each file, verify that every named item (function, test, constant, doc comment) does what it claims. This pass is not about presence/absence (covered by passes 2-4) but about whether the intent expressed by a name, comment, or specification matches the actual behavior.

Areas to review include but are not limited to:

- **Tests vs. claims**: Does each test actually exercise the behavior its name and NatSpec describe? A test named for a specific error path must trigger that error path. A test named for a boundary condition must test that boundary.
- **Algorithms and formulas**: When code implements a known mathematical concept, algorithm, or specification (e.g., a hash function, a sorting algorithm, a financial formula, a bit manipulation pattern), verify the implementation is correct against the definition.
- **Constants and magic numbers**: Verify that named constants match their documented meaning and that magic numbers are correct (e.g., bitmasks have the right width, offsets match the struct layout, sizes match the specification).
- **NatSpec vs. implementation**: Verify that doc comments accurately describe what the code does — parameter descriptions match actual usage, return value descriptions match what is returned, stated invariants hold.
- **Error conditions vs. triggers**: Verify that each error/revert is triggered by the condition its name and documentation describe, not by a different condition.
- **Interface conformance**: When code claims to implement an interface or standard (e.g., ERC-165, ERC-20), verify it actually satisfies all requirements of that standard.
