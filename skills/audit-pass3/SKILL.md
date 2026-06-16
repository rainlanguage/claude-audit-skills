---
name: audit-pass3
description: "Audit Pass 3: Documentation. Reviews doc comment completeness, parameter/return documentation, and accuracy against implementation."
allowed-tools: Read, Grep, Glob, Task, Write
---

# Audit Pass 3: Documentation

## General Rules

Before starting, read and follow `../audit/GENERAL_RULES.md`.

## Pass 3 Instructions

Review all documentation for completeness and accuracy. Check CLAUDE.md for project-specific documentation conventions (e.g., doc comment format, required tags). General checks include but are not limited to:

- Systematically enumerate every public function/method and verify each has documentation
- Explicitly list undocumented functions as findings
- Documentation should describe parameters and return values
- After ensuring documentation exists, review it against the implementation for accuracy
- Review README.md and other top-level project documentation (not just code doc comments):
  - Does the README clearly describe what the project is and its design rationale?
  - Does the README accurately reflect the current state of the codebase (e.g. current interface/type names, not stale ones)?
  - Are there dangling references to renamed, removed, or external entities that no longer exist?
