---
name: audit
description: Full audit process for a codebase. Covers all passes (0-6) and triage. Use when starting or reviewing a complete audit.
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Review

Before starting, read and follow `GENERAL_RULES.md`.

An audit consists of the passes defined below. All passes are mandatory. Do not combine them into a single pass.

**Each pass MUST be executed by file-scoped subagents dispatched via the Agent tool — the parent conversation never reads source files itself for the review.** This keeps the parent's context limited to subagent return summaries (typically just findings) instead of full file contents, so all seven passes plus triage fit in a single `/audit` invocation. The parent may dispatch per-file subagents directly in parallel waves, or delegate an entire pass to one orchestrator subagent that spawns its own per-file children — either is valid as long as actual file review happens inside a subagent with a clean context.

Pass 0 (Process Review) is the only exception: it covers a handful of small process documents (CLAUDE.md, README, CI YAMLs, etc.) and may be reviewed inline in the parent conversation without subagents.

**Pass execution order is strictly sequential: 0 → 1 → 2 → 3 → 4 → 5 → 6.** Do not start a later pass until the current pass is fully complete and its findings are filed on GitHub. Do not run multiple passes in parallel. Within a single pass, file-scoped subagents MAY run in parallel, but passes themselves are sequential.

**Triage may only begin after all 7 passes are complete and their issues are filed on GitHub.** If `/audit` is invoked and some passes are missing, run the missing passes (in order) before starting triage.

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

- **Pass 0: Process Review** — Read `../audit-pass0/SKILL.md`
- **Pass 1: Security** — Read `../audit-pass1/SKILL.md`
- **Pass 2: Test Coverage** — Read `../audit-pass2/SKILL.md`
- **Pass 3: Documentation** — Read `../audit-pass3/SKILL.md`
- **Pass 4: Code Quality** — Read `../audit-pass4/SKILL.md`
- **Pass 5: Correctness / Intent Verification** — Read `../audit-pass5/SKILL.md`
- **Pass 6: Hazard Surface** — Read `../audit-pass6/SKILL.md`

## Triage

Triage instructions are defined in `../audit-triage/SKILL.md`. **That file is the single source of truth for triage instructions.** Read it before starting triage.

Before starting triage, list open audit issues with `gh issue list --label audit --state open`. Any finding in the current audit that duplicates a previously closed issue should be closed with a comment referencing the prior issue, not re-presented to the user.
