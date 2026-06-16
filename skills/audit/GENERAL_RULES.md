# Audit General Rules

## File Discovery

The audit covers **all languages** present in the repository, not just one. Before starting any pass, discover source files by reading `CLAUDE.md` / `AGENTS.md` for the project structure, then glob for all source directories. Common patterns:

- Solidity: `src/**/*.sol`
- Rust: `crates/*/src/**/*.rs` (exclude `target/`)
- TypeScript/JavaScript: `packages/*/src/**/*.{ts,tsx,js,jsx}` (exclude `node_modules/`, `dist/`, `.svelte-kit/`)
- Svelte: `packages/*/src/**/*.svelte`

Exclude auto-generated files (bindings, build artifacts), vendored dependencies (`lib/`, `node_modules/`), and lock files. When in doubt about whether a directory contains first-party source, check for a `Cargo.toml`, `package.json`, or similar manifest.

The file list for agent assignment is the union of all discovered source files across all languages, sorted alphabetically. Agent IDs are assigned from this combined list. Each pass reviews all languages — there are no language-specific passes.

Pass instructions that mention language-specific concerns (e.g., "Solidity-Specific Concerns") apply only to files of that language. Agents reviewing files of other languages apply the general concerns plus any language-specific sections relevant to their file's language.

## Agent Partitioning

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

Each agent must create a GitHub issue for each finding using `gh issue create`. Issues are the record of truth — findings that only exist in agent task output are lost when context compacts.

**Security disclosure**: CRITICAL and HIGH severity findings may describe exploitable vulnerabilities. Do NOT automatically file these as public GitHub issues. Instead, present them to the user locally and let the user decide whether to file publicly or apply a fix first. Only MEDIUM, LOW, and INFO findings are filed as issues automatically.

Each issue must have:
- **Title**: `[<FindingID>] [<SEVERITY>] <short description>` (e.g., `[A03-1] [MEDIUM] Missing input validation in parser`)
- **Labels**: `audit`, `pass<M>` (e.g., `pass1`), and severity as lowercase (e.g., `medium`)
- **Body**: The finding description, file path(s) and line number(s), and the proposed fix

Before the first pass, ensure the required labels exist on the repo. Run `gh label list` and create any missing labels from: `audit`, `pass0`, `pass1`, `pass2`, `pass3`, `pass4`, `pass5`, `critical`, `high`, `medium`, `low`, `info`. Use `gh label create <name>` for any that don't exist.

## Proposed Fixes

Each LOW+ finding must include a proposed fix in the GitHub issue body. The fix section must contain:
- The file path(s) and line number(s) to change
- The exact proposed fix as a diff or before/after code block
- For test coverage findings: a complete proposed test file or test function

Every proposed fix must be thorough enough to pass a subsequent audit. For test coverage fixes specifically, this means comprehensive tests covering edge cases, boundary conditions, error paths, and fuzz testing where applicable — not just a single happy-path test. Apply the same rigor described in Pass 2 to any tests written as fixes.

Fixes are included in the issue body during each pass, not deferred to triage. This means when triage presents a finding, the proposed fix is already available for the user to accept, modify, or dismiss.

Before reporting findings, read `audit/known-false-positives.md` and do not re-flag any issue documented there.

Before proposing a test for an audit finding, answer: "How does this test cover the gap?" The test must exercise the specific thing the finding identifies. If existing tests would produce the same result, the new test does not add coverage.

Always use specific revert expectations in tests — never use bare `vm.expectRevert()` without arguments. A bare expectRevert matches any revert, so the test could pass for the wrong reason. Use `vm.expectRevert(abi.encodeWithSelector(Error.selector, args...))` or `vm.expectRevert(Error.selector)`. If the revert truly has no data (e.g. raw `abi.decode` failures), use `vm.expectRevert(bytes(""))` with a comment explaining why there is no specific error.

Per-test `forge-config: default.fuzz.runs` overrides exist intentionally for slow fuzz tests. Do not remove them without benchmarking. Before adding or removing fuzz run overrides, run the test and check timing. Conversely, when a fuzz test without an override takes more than a few seconds, add a reduced-runs override to keep the suite fast.

Do not scope audit coverage based on diffs or recent changes — every source file is in scope regardless of modification date. The audit reviews the codebase as a whole, not an incremental delta.

## Rounding Direction Rule

All rounding from precision loss (e.g., Float-to-fixed-decimal conversions, integer division) MUST favor non-interactive participants. Contracts count as non-interactive participants. For each rounding operation found during audit, verify:
- WHO is the non-interactive participant (order owner, contract, protocol)
- WHICH direction the rounding goes (up or down)
- WHETHER that direction favors the non-interactive participant
Flag any rounding that favors interactive participants (msg.sender, arb callers, external protocols) as a finding.

## Variable Naming

Do not use short, meaningless variable names (e.g., single characters like `r`, `n`, `x`, or abbreviations like `ob`, `cfg`, `val`) for closure parameters, loop variables, or local bindings. Variable names must clearly convey what the variable represents in context (e.g., `raindex_cfg` instead of `ob`, `network_key` instead of `nk`, `raindex_entry` instead of `re`). Short names that happen to be meaningful in context are acceptable (e.g., `id`, `url`, `key` when unambiguous). Flag unclear or overly abbreviated variable names as LOW findings during code quality passes.

## Pass Ordering

Passes are strictly sequential (0 → 1 → 2 → 3 → 4 → 5). Do not run multiple passes in parallel — each pass may depend on prior pass findings for context. Within a single pass, file-level agents MAY run in parallel. Triage begins only after all passes are complete with output files on disk.
