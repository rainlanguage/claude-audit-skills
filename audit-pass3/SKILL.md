---
name: audit-pass3
description: "Audit Pass 3: Documentation. Reviews NatSpec completeness, @param/@return tags, explicit @notice usage, and accuracy against implementation."
allowed-tools: Read, Grep, Glob, Task, Write
---

# Audit Pass 3: Documentation

## General Rules

Each pass will need multiple agents to cover the full codebase. When partitioning files across agents, assign one file per agent. This ensures each agent reads its file thoroughly rather than skimming across many files.

Agents are assigned sequential IDs (A01, A02, ...) based on alphabetical order of their source file paths. Each agent prefixes its findings with its ID (e.g., A03-1, A03-2). This produces a stable global ordering: sort by agent ID, then by finding number within each agent. The ordering is deterministic because it derives from the file list, which is fixed for a given codebase snapshot.

Every pass requires reading every assigned file in full. Do not rely on grepping as a substitute for reading — systematic line-by-line review catches issues that keyword searches miss. Grepping is appropriate for cross-referencing (e.g., checking if an error name appears in test files) but not for understanding code.

After reading each file, the agent must list evidence of thorough reading before reporting findings. For each file, list:
- The contract/library name
- Every function name and its line number
- Every error/event/struct defined (if any)

This evidence must appear in the agent's output before any findings for that file. If the evidence is missing or incomplete, the audit of that file is invalid and must be re-run.

Findings from all passes should be reported, not fixed. Fixes are a separate step after findings are reviewed. Each finding must be classified as one of: **CRITICAL** (exploitable now with direct impact), **HIGH** (significant risk requiring specific conditions), **MEDIUM** (real concern with mitigating factors), **LOW** (minor issue or theoretical risk), **INFO** (observation with no direct risk).

Each agent must write its findings to `audit/<YYYY-MM-DD>-<NN>/pass3/<FileName>.md` where `<NN>` is a zero-padded incrementing integer starting at 01, and `<FileName>` matches the source file name (e.g. `LibEval.md` for `LibEval.sol`). To determine `<NN>`, glob for `audit/<YYYY-MM-DD>-*` and use one higher than the highest existing number, or 01 if none exist. All passes of the same audit share the same `<NN>`. Each audit run uses this namespace so previous runs are preserved as history. Findings that only exist in agent task output are lost when context compacts — the file is the record of truth.

## Pass 3 Instructions

Review all documentation for completeness and accuracy, including but not limited to:

- Systematically enumerate every function in every contract and library, and verify each has NatSpec documentation
- Explicitly list undocumented functions as findings
- All NatSpec must include `@param` and `@return` tags as relevant for functions, structs, errors, etc.
- When a doc block contains any explicit tag (e.g. `@title`), all entries must be explicitly tagged. Untagged lines after a tag are parsed as continuation of the previous tag, not as implicit `@notice`. Every contract/library-level doc block with `@title` must also have an explicit `@notice`.
- After ensuring documentation exists, review it against the implementation for accuracy
