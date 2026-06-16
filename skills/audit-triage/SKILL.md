---
name: audit-triage
description: "Audit Triage. Works through audit findings one at a time, letting the user decide disposition. Tracks progress via GitHub issues."
allowed-tools: Read, Grep, Glob, Bash, Task, Edit, Write
---

# Audit Triage

## General Rules

Before starting, read and follow `../audit/GENERAL_RULES.md`.

## Triage Instructions

Before starting triage, list open audit issues with `gh issue list --label audit --state open`. Any finding in the current audit that duplicates a previously closed issue should be closed with a comment referencing the prior issue, not re-presented to the user.

Triage progress is tracked via GitHub issue state and labels. Each issue disposition maps to:
- **FIXED** (code changed) — close the issue after the fix is applied
- **DOCUMENTED** (documentation/comments added) — close the issue after documentation is added
- **DISMISSED** (no action needed) — close the issue with a comment explaining why
- **UPSTREAM** (fix belongs in a dependency/submodule, not this repo) — close the issue with a comment noting the upstream location
- **PENDING** (not yet triaged) — issue remains open

Before presenting the next finding, list open audit issues and pick the first one by issue number.

Before presenting a finding to the user, read the relevant source code and verify the finding is valid. If the finding is incorrect (e.g., describes behavior that doesn't exist, misreads the code, or flags correct behavior as a problem), close the issue with a comment explaining the dismissal and move to the next finding without prompting the user. Only present findings that survive this validation.

Present validated findings neutrally and let the user decide the disposition.

When triaging a finding as already FIXED (test already exists), apply the same rigor as writing a new fix: read the actual test code, verify it covers the finding, check for missing edge cases and boundary conditions, and add tests if gaps exist. "Test exists" is not the same as "properly tested." One finding at a time — no batch-marking.

When fixing a finding, follow TDD: write a test that reproduces the bug, run it to confirm it fails, then write the fix and run the test again to confirm it passes. Do not write the fix before running the test and confirming it reproduces the bug. If the bug cannot be reproduced in a test (e.g., memory alignment issues with no observable behavior), state this explicitly when presenting the finding.

When fixing a PENDING finding, read the proposed fix from the GitHub issue body first. Use it as the fix plan — the issue lists the affected files and proposed approach. If the proposed fix is underspecified, note what's missing but still use it as the starting point rather than re-deriving the fix independently.
