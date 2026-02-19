---
name: audit-pass0
description: "Audit Pass 0: Process Review. Reviews project process documents for ambiguity, fragility under context compression, and inconsistencies."
allowed-tools: Read, Grep, Glob, Write
---

# Audit Pass 0: Process Review

## General Rules

An audit consists of the passes defined below. All passes are mandatory. Do not combine them into a single pass. Each pass must be run as its own separate conversation to avoid hitting context limits.

Every pass requires reading every assigned file in full. Do not rely on grepping as a substitute for reading — systematic line-by-line review catches issues that keyword searches miss. Grepping is appropriate for cross-referencing but not for understanding code.

After reading each file, the agent must list evidence of thorough reading before reporting findings. For each file, list:
- The module/class/contract name
- Every function/method name and its line number
- Every type, error, and constant defined (if any)

This evidence must appear in the agent's output before any findings for that file. If the evidence is missing or incomplete, the audit of that file is invalid and must be re-run.

Findings from all passes should be reported, not fixed. Fixes are a separate step after findings are reviewed. Each finding must be classified as one of: **CRITICAL** (exploitable now with direct impact), **HIGH** (significant risk requiring specific conditions), **MEDIUM** (real concern with mitigating factors), **LOW** (minor issue or theoretical risk), **INFO** (observation with no direct risk).

Each agent must write its findings to `audit/<YYYY-MM-DD>-<NN>/pass<M>/<FileName>.md` where `<NN>` is a zero-padded incrementing integer starting at 01, `<M>` is the pass number, and `<FileName>` matches the source file name (without extension). To determine `<NN>`, glob for `audit/<YYYY-MM-DD>-*` and use one higher than the highest existing number, or 01 if none exist. All passes of the same audit share the same `<NN>`. Each audit run uses this namespace so previous runs are preserved as history. Findings that only exist in agent task output are lost when context compacts — the file is the record of truth.

## Pass 0 Instructions

Review project process documents (e.g., CLAUDE.md and any referenced instructions) for issues that would cause future sessions to misinterpret instructions. This pass reviews process documents, not source code. No subagents needed — the documents are small enough to review in the main conversation. Record findings to `audit/<YYYY-MM-DD>-<NN>/pass0/process.md`.

Check for:
- Ambiguous instructions a future session could misinterpret (e.g. reused placeholder names, unclear defaults)
- Instructions that are fragile under context compression (e.g. relying on subtle distinctions)
- Missing defaults or undefined terms
- Inconsistencies between process documents
