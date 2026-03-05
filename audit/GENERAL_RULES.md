# Audit General Rules

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

## Proposed Fixes

Each LOW+ finding must include a proposed fix written to `.fixes/`. This folder is gitignored so proposed fixes never pollute the commit history. Before the first pass, ensure `.fixes` is in `.gitignore` (add it if missing).

For each finding, the agent writes a fix file to `.fixes/<FindingID>.md` containing:
- The finding ID and title
- The file path(s) and line number(s) to change
- The exact proposed fix as a diff or before/after code block
- For test coverage findings: a complete proposed test file or test function

Every proposed fix must be thorough enough to pass a subsequent audit. For test coverage fixes specifically, this means comprehensive tests covering edge cases, boundary conditions, error paths, and fuzz testing where applicable — not just a single happy-path test. Apply the same rigor described in Pass 2 to any tests written as fixes.

Fix files are written alongside findings during each pass, not deferred to triage. This means when triage presents a finding, the proposed fix is already available for the user to accept, modify, or dismiss. The triage step reads the fix file and presents it with the finding.

Before reporting findings, read `audit/known-false-positives.md` and do not re-flag any issue documented there.

Before proposing a test for an audit finding, answer: "How does this test cover the gap?" The test must exercise the specific thing the finding identifies. If existing tests would produce the same result, the new test does not add coverage.

Per-test `forge-config: default.fuzz.runs` overrides exist intentionally for slow fuzz tests. Do not remove them without benchmarking. Before adding or removing fuzz run overrides, run the test and check timing. Conversely, when a fuzz test without an override takes more than a few seconds, add a reduced-runs override to keep the suite fast.

Do not scope audit coverage based on diffs or recent changes — every source file is in scope regardless of modification date. The audit reviews the codebase as a whole, not an incremental delta.

## Pass Ordering

Passes are strictly sequential (0 → 1 → 2 → 3 → 4 → 5). Do not run multiple passes in parallel — each pass may depend on prior pass findings for context. Within a single pass, file-level agents MAY run in parallel. Triage begins only after all passes are complete with output files on disk.
