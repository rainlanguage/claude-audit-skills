---
name: audit
description: Full audit process for a codebase. Covers all passes (0-4) and triage. Use when starting or reviewing a complete audit.
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Review

An audit consists of the passes defined below. All passes are mandatory. Do not combine them into a single pass. Each pass must be run as its own separate conversation to avoid hitting context limits.

Each pass will need multiple agents to cover the full codebase. When partitioning files across agents, assign one file per agent. This ensures each agent reads its file thoroughly rather than skimming across many files. For passes that require cross-file context (e.g., Pass 2 needs both source and test files), the agent receives the source file plus its corresponding test file(s) — this is still a single-file-per-agent partition from the source file perspective.

Agents are assigned sequential IDs (A01, A02, ...) based on alphabetical order of their source file paths. Each agent prefixes its findings with its ID (e.g., A03-1, A03-2). This produces a stable global ordering: sort by agent ID, then by finding number within each agent. The ordering is deterministic because it derives from the file list, which is fixed for a given codebase snapshot.

Every pass requires reading every assigned file in full. Do not rely on grepping as a substitute for reading — systematic line-by-line review catches issues that keyword searches miss. Grepping is appropriate for cross-referencing (e.g., checking if a name appears in test files) but not for understanding code.

After reading each file, the agent must list evidence of thorough reading before reporting findings. For each file, list:
- The module/class/contract name
- Every function/method name and its line number
- Every type, error, and constant defined (if any)

This evidence must appear in the agent's output before any findings for that file. If the evidence is missing or incomplete, the audit of that file is invalid and must be re-run.

Findings from all passes should be reported, not fixed. Fixes are a separate step after findings are reviewed. A finding must identify an actual problem — something that is wrong, missing, or could go wrong. Correct behavior is not a finding at any severity. Do not report "X works correctly" or "no issues found" as findings.

Each finding must be classified as one of: **CRITICAL** (exploitable now with direct impact), **HIGH** (significant risk requiring specific conditions), **MEDIUM** (real concern with mitigating factors), **LOW** (minor issue or theoretical risk), **INFO** (suggestion for improvement with no direct risk).

Each agent must write its findings to `audit/<YYYY-MM-DD>-<NN>/pass<M>/<FileName>.md` where `<NN>` is a zero-padded incrementing integer starting at 01, `<M>` is the pass number, and `<FileName>` matches the source file name (without extension). To determine `<NN>`, glob for `audit/<YYYY-MM-DD>-*` and use one higher than the highest existing number, or 01 if none exist. All passes of the same audit share the same `<NN>`. Each audit run uses this namespace so previous runs are preserved as history. Findings that only exist in agent task output are lost when context compacts — the file is the record of truth.

Before starting triage, glob for `audit/*/triage.md` and read the most recent prior triage file (by directory sort order). Any finding in the current audit that duplicates a previously triaged item should be carried forward into the current triage file with its existing status, not re-presented to the user.

## Triage

During triage, maintain `audit/<YYYY-MM-DD>-<NN>/triage.md` recording the disposition of every LOW+ finding, keyed by finding ID (e.g., A03-1). Each entry has a status: **FIXED** (code changed), **DOCUMENTED** (documentation/comments added), **DISMISSED** (no action needed), **UPSTREAM** (fix belongs in a dependency/submodule, not this repo), or **PENDING** (not yet triaged). This file is the durable record of triage progress — conversation context is lost on compaction, but the file persists. Before presenting the next finding, check the triage file for the first PENDING ID in sort order. Present findings neutrally and let the user decide the disposition.

When triaging a finding as already FIXED (test already exists), apply the same rigor as writing a new fix: read the actual test code, verify it covers the finding, check for missing edge cases and boundary conditions, and add tests if gaps exist. "Test exists" is not the same as "properly tested." One finding at a time — no batch-marking.

## Pass 0: Process Review

Review project process documents (e.g., CLAUDE.md and any referenced instructions) for issues that would cause future sessions to misinterpret instructions. This pass reviews process documents, not source code. No subagents needed — the documents are small enough to review in the main conversation. Record findings to `audit/<YYYY-MM-DD>-<NN>/pass0/process.md`.

Check for:
- Ambiguous instructions a future session could misinterpret (e.g. reused placeholder names, unclear defaults)
- Instructions that are fragile under context compression (e.g. relying on subtle distinctions)
- Missing defaults or undefined terms
- Inconsistencies between process documents

## Pass 1: Security

Review for all security issues. Check CLAUDE.md for project-specific security concerns. General areas to review include but are not limited to:

- Memory safety: out-of-bounds reads/writes, incorrect pointer arithmetic, missing bounds checks
- Input validation: untrusted inputs accepted without sanitization, invalid values silently misinterpreted
- Authentication and authorization: missing access controls, privilege escalation paths
- Injection: command injection, SQL injection, path traversal, or language-specific equivalents
- Reentrancy and state consistency: external calls that allow re-entry before state is finalized
- Arithmetic safety: unchecked overflow/underflow, division by zero, silent wrapping
- Error handling: missing error checks, errors swallowed silently, inconsistent error conventions
- Cryptographic issues: weak algorithms, hardcoded secrets, improper randomness
- Resource management: leaks, unbounded allocation, denial-of-service vectors

### Solidity-Specific Concerns

- Check assembly blocks for memory safety: out-of-bounds reads/writes, incorrect pointer arithmetic, missing bounds checks
- Verify stack underflow/overflow protection in opcode `run` functions
- Check that integrity functions correctly declare inputs/outputs matching what `run` actually consumes/produces
- Look for reentrancy risks in opcodes that make external calls (ERC20, ERC721, extern)
- Verify namespace isolation in the store — `msg.sender` + `StateNamespace` must always scope storage access
- Check that bytecode hash verification in the expression deployer cannot be bypassed
- Verify function pointer tables cannot index out of bounds or be manipulated
- Check that operand parsing rejects invalid operand values rather than silently misinterpreting them
- Verify that the eval loop cannot be made to jump to arbitrary code via crafted bytecode
- Check that context array access is bounds-checked
- Review extern dispatch for correct encoding/decoding of `ExternDispatchV2`
- Ensure all reverts use custom errors, not string messages (`revert("...")` is not allowed)

## Pass 2: Test Coverage

For each source file, read both the source file and its corresponding test file(s). Check CLAUDE.md for project conventions on test file location and naming. Some source files may be tested indirectly by test files elsewhere — grep for the function/type name across the test directory to find where coverage exists. Report all coverage gaps, including but not limited to:

- Source files with no corresponding test file
- Functions with no test exercising them
- Error/failure paths with no test triggering them
- Missing edge case coverage: zero-length inputs, max-length inputs, off-by-one boundaries, odd/even parity

## Pass 3: Documentation

Review all documentation for completeness and accuracy. Check CLAUDE.md for project-specific documentation conventions (e.g., doc comment format, required tags). General checks include but are not limited to:

- Systematically enumerate every public function/method and verify each has documentation
- Explicitly list undocumented functions as findings
- Documentation should describe parameters and return values
- After ensuring documentation exists, review it against the implementation for accuracy

## Pass 4: Code Quality

Review for maintainability, consistency, and good abstractions, including but not limited to:

- Audit for style consistency across the repo — when similar code uses different patterns for the same thing, flag it
- Identify leaky abstractions: internal details exposed through public interfaces, implementation concerns bleeding across module boundaries, or tight coupling between components that should be independent
- Review all commented-out code — each instance should be either reinstated or deleted, not left commented
- Ensure no warnings from the project's build toolchain — build warnings are real problems (LOW or higher), not INFO
- Check that all dependency versions are consistent (no conflicting versions of the same dependency)
