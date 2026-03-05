---
name: audit-triage
description: "Audit Triage. Works through audit findings one at a time, letting the user decide disposition. Tracks progress in triage.md."
allowed-tools: Read, Grep, Glob, Bash, Task, Edit, Write
---

# Audit Triage

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Triage Instructions

Before starting triage, glob for `audit/*/triage.md` and read the most recent prior triage file (by directory sort order). Any finding in the current audit that duplicates a previously triaged item should be carried forward into the current triage file with its existing status, not re-presented to the user.

During triage, maintain `audit/<YYYY-MM-DD>-<NN>/triage.md` recording the disposition of every LOW+ finding, keyed by finding ID (e.g., A03-1). Each entry has a status: **FIXED** (code changed), **DOCUMENTED** (documentation/comments added), **DISMISSED** (no action needed), **UPSTREAM** (fix belongs in a dependency/submodule, not this repo), or **PENDING** (not yet triaged). This file is the durable record of triage progress — conversation context is lost on compaction, but the file persists. Before presenting the next finding, check the triage file for the first PENDING ID in sort order.

Before presenting a finding to the user, read the relevant source code and verify the finding is valid. If the finding is incorrect (e.g., describes behavior that doesn't exist, misreads the code, or flags correct behavior as a problem), mark it as DISMISSED with a brief explanation in the triage file and move to the next finding without prompting the user. Only present findings that survive this validation.

Present validated findings neutrally and let the user decide the disposition.

When triaging a finding as already FIXED (test already exists), apply the same rigor as writing a new fix: read the actual test code, verify it covers the finding, check for missing edge cases and boundary conditions, and add tests if gaps exist. "Test exists" is not the same as "properly tested." One finding at a time — no batch-marking.

When fixing a PENDING finding, read the corresponding `.fixes/<ID>.md` file first. Use it as the fix plan — the file lists the affected files and proposed approach. If the `.fixes/` file is underspecified, note what's missing but still use it as the starting point rather than re-reading original audit findings and re-deriving the fix independently.
