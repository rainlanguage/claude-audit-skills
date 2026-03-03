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
