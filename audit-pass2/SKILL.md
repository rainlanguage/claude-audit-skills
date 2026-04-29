---
name: audit-pass2
description: "Audit Pass 2: Test Coverage. Reviews source files against their test files for coverage gaps, untested functions, missing error path tests, and edge cases."
allowed-tools: Read, Grep, Glob, Task, Write, Bash
---

# Audit Pass 2: Test Coverage

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Pass 2 Instructions

For each source file, read both the source file and its corresponding test file(s). Check CLAUDE.md for project conventions on test file location and naming. Some source files may be tested indirectly by test files elsewhere — grep for the function/type name across the test directory to find where coverage exists. Report all coverage gaps, including but not limited to:

- Source files with no corresponding test file
- Functions with no test exercising them
- Error/failure paths with no test triggering them
- Missing edge case coverage: zero-length inputs, max-length inputs, off-by-one boundaries, odd/even parity

### Test Location Conventions by Language

- **Solidity** (Foundry): Tests in `test/` directory, typically `*.t.sol` files
- **Rust**: Tests in `#[cfg(test)] mod tests` within source files, or in `tests/` directories. Integration tests in dedicated crates (e.g., `crates/integration_tests`)
- **TypeScript**: Tests as `*.test.ts` or `*.spec.ts` alongside source or in `__tests__/` directories
