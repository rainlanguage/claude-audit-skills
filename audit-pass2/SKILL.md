---
name: audit-pass2
description: "Audit Pass 2: Test Coverage. Reviews source files against their test files for coverage gaps, untested functions, missing error path tests, and edge cases."
allowed-tools: Read, Grep, Glob, Task, Write
---

# Audit Pass 2: Test Coverage

## General Rules

Each pass will need multiple agents to cover the full codebase. When partitioning files across agents, assign one file per agent. This ensures each agent reads its file thoroughly rather than skimming across many files. For passes that require cross-file context (e.g., Pass 2 needs both source and test files), the agent receives the source file plus its corresponding test file(s) — this is still a single-file-per-agent partition from the source file perspective.

Agents are assigned sequential IDs (A01, A02, ...) based on alphabetical order of their source file paths. Each agent prefixes its findings with its ID (e.g., A03-1, A03-2). This produces a stable global ordering: sort by agent ID, then by finding number within each agent. The ordering is deterministic because it derives from the file list, which is fixed for a given codebase snapshot.

Every pass requires reading every assigned file in full. Do not rely on grepping as a substitute for reading — systematic line-by-line review catches issues that keyword searches miss. Grepping is appropriate for cross-referencing (e.g., checking if an error name appears in test files) but not for understanding code.

After reading each file, the agent must list evidence of thorough reading before reporting findings. For each file, list:
- The contract/library name
- Every function name and its line number
- Every error/event/struct defined (if any)

This evidence must appear in the agent's output before any findings for that file. If the evidence is missing or incomplete, the audit of that file is invalid and must be re-run.

Findings from all passes should be reported, not fixed. Fixes are a separate step after findings are reviewed. Each finding must be classified as one of: **CRITICAL** (exploitable now with direct impact), **HIGH** (significant risk requiring specific conditions), **MEDIUM** (real concern with mitigating factors), **LOW** (minor issue or theoretical risk), **INFO** (observation with no direct risk).

Each agent must write its findings to `audit/<YYYY-MM-DD>-<NN>/pass2/<FileName>.md` where `<NN>` is a zero-padded incrementing integer starting at 01, and `<FileName>` matches the source file name (e.g. `LibEval.md` for `LibEval.sol`). To determine `<NN>`, glob for `audit/<YYYY-MM-DD>-*` and use one higher than the highest existing number, or 01 if none exist. All passes of the same audit share the same `<NN>`. Each audit run uses this namespace so previous runs are preserved as history. Findings that only exist in agent task output are lost when context compacts — the file is the record of truth.

## Pass 2 Instructions

For each source file, read both the source file and its corresponding test file(s). Test files are in `test/` mirroring `src/` structure, suffixed `.t.sol`. Some source files (especially error definitions in `src/error/`) are tested indirectly by test files elsewhere — grep for the error/function name across `test/` to find where coverage exists. Report all coverage gaps, including but not limited to:

- Source files with no corresponding test file
- Functions with no test exercising them
- Error/revert paths with no test triggering them (check every `revert` in source, every `error` in `src/error/`)
- Missing edge case coverage: zero-length inputs, max-length inputs, off-by-one boundaries, odd/even parity
