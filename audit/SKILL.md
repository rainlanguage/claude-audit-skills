---
name: audit
description: Full audit process for a codebase. Covers all passes (0-5) and triage. Use when starting or reviewing a complete audit.
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Review

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

An audit consists of the passes defined below. All passes are mandatory. Do not combine them into a single pass. Each pass must be run as its own separate conversation to avoid hitting context limits.

**Pass execution order is strictly sequential: 0 → 1 → 2 → 3 → 4 → 5.** Do not start a later pass until the current pass is fully complete and its output file is written to disk. Do not run multiple passes in parallel. Within a single pass, agents reviewing different files MAY run in parallel, but passes themselves are sequential.

**Triage may only begin after all 6 passes are complete and their output files exist on disk.** If `/audit` is invoked and some passes are missing, run the missing passes (in order) before starting triage.

Each pass will need multiple agents to cover the full codebase. When partitioning files across agents, assign one file per agent. This ensures each agent reads its file thoroughly rather than skimming across many files. For passes that require cross-file context (e.g., Pass 2 needs both source and test files), the agent receives the source file plus its corresponding test file(s) — this is still a single-file-per-agent partition from the source file perspective.

Agents are assigned sequential IDs (A01, A02, ...) based on alphabetical order of their source file paths. Each agent prefixes its findings with its ID (e.g., A03-1, A03-2). This produces a stable global ordering: sort by agent ID, then by finding number within each agent. The ordering is deterministic because it derives from the file list, which is fixed for a given codebase snapshot.

Every pass requires reading every assigned file in full. Do not rely on grepping as a substitute for reading — systematic line-by-line review catches issues that keyword searches miss. Grepping is appropriate for cross-referencing (e.g., checking if a name appears in test files) but not for understanding code.

After reading each file, the agent must list evidence of thorough reading before reporting findings. For each file, list:
- The module/class/contract name
- Every function/method name and its line number
- Every type, error, and constant defined (if any)

This evidence must appear in the agent's output before any findings for that file. If the evidence is missing or incomplete, the audit of that file is invalid and must be re-run.

Findings from all passes should be reported, not fixed. Fixes are a separate step after findings are reviewed. A finding must identify an actual problem — something that is wrong, missing, or could go wrong. Correct behavior is not a finding at any severity. Do not report "X works correctly" or "no issues found" as findings.

## Pass definitions

Each pass is defined in its own skill file. **The individual pass file is the single source of truth for that pass's instructions.** When editing pass instructions, edit the individual pass file only — do not duplicate pass content here.

- **Pass 0: Process Review** — Read `~/.claude/skills/audit-pass0/SKILL.md`
- **Pass 1: Security** — Read `~/.claude/skills/audit-pass1/SKILL.md`
- **Pass 2: Test Coverage** — Read `~/.claude/skills/audit-pass2/SKILL.md`
- **Pass 3: Documentation** — Read `~/.claude/skills/audit-pass3/SKILL.md`
- **Pass 4: Code Quality** — Read `~/.claude/skills/audit-pass4/SKILL.md`
- **Pass 5: Correctness / Intent Verification** — Read `~/.claude/skills/audit-pass5/SKILL.md`

## Triage

Triage instructions are defined in `~/.claude/skills/audit-triage/SKILL.md`. **That file is the single source of truth for triage instructions.** Read it before starting triage.

Before starting triage, glob for `audit/*/triage.md` and read the most recent prior triage file (by directory sort order). Any finding in the current audit that duplicates a previously triaged item should be carried forward into the current triage file with its existing status, not re-presented to the user.
