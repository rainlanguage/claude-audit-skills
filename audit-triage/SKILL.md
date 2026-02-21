---
name: audit-triage
description: "Audit Triage. Works through audit findings one at a time, letting the user decide disposition. Tracks progress in triage.md."
allowed-tools: Read, Grep, Glob, Bash, Task, Edit, Write
---

# Audit Triage

## General Rules

Findings from all passes should be reported, not fixed. Fixes are a separate step after findings are reviewed. Each finding must be classified as one of: **CRITICAL** (exploitable now with direct impact), **HIGH** (significant risk requiring specific conditions), **MEDIUM** (real concern with mitigating factors), **LOW** (minor issue or theoretical risk), **INFO** (observation with no direct risk).

Findings are written to `audit/<YYYY-MM-DD>-<NN>/pass<M>/<FileName>.md`. Agents are assigned sequential IDs (A01, A02, ...) based on alphabetical order of their source file paths. Each agent prefixes its findings with its ID (e.g., A03-1, A03-2).

## Triage Instructions

Before starting triage, glob for `audit/*/triage.md` and read the most recent prior triage file (by directory sort order). Any finding in the current audit that duplicates a previously triaged item should be carried forward into the current triage file with its existing status, not re-presented to the user.

During triage, maintain `audit/<YYYY-MM-DD>-<NN>/triage.md` recording the disposition of every LOW+ finding, keyed by finding ID (e.g., A03-1). Each entry has a status: **FIXED** (code changed), **DOCUMENTED** (documentation/comments added), **DISMISSED** (no action needed), **UPSTREAM** (fix belongs in a dependency/submodule, not this repo), or **PENDING** (not yet triaged). This file is the durable record of triage progress — conversation context is lost on compaction, but the file persists. Before presenting the next finding, check the triage file for the first PENDING ID in sort order. Present findings neutrally and let the user decide the disposition.

When triaging a finding as already FIXED (test already exists), apply the same rigor as writing a new fix: read the actual test code, verify it covers the finding, check for missing edge cases and boundary conditions, and add tests if gaps exist. "Test exists" is not the same as "properly tested." One finding at a time — no batch-marking.
