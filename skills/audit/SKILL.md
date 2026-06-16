---
name: audit
description: Full codebase audit — seven review dimensions (process, security, test coverage, documentation, code quality, correctness/intent, hazard surface) plus triage. Reviews EVERY source file across all languages as a whole-repo snapshot (not a diff), reports problems (never fixes them, never "works correctly"), severity-rates each, attaches a concrete proposed fix, and tracks findings as GitHub issues; triage then re-validates each finding against live source and applies fixes TDD-style. Triggers on "audit this codebase", "security review", "full audit", "review the whole repo for bugs/coverage/docs/quality/correctness/hazards", "find what's wrong before an external audit".
version: 0.1.0
---

# Codebase Audit (whole-repo, multi-dimension)

An audit is **seven review dimensions** over the whole codebase, then **triage**:

- **0. Process** — the project's instruction docs (CLAUDE.md/AGENTS.md/etc.) for things a future session would misread.
- **1. Security** — vulnerabilities.
- **2. Test coverage** — behavior not exercised by tests.
- **3. Documentation** — completeness + accuracy of docs against the implementation.
- **4. Code quality** — maintainability, consistency, leaky abstractions, portability.
- **5. Correctness / intent** — does each named thing actually do what its name/comment/spec claims?
- **6. Hazard surface** — architectural shapes that make a future mistake more likely to land silently in production.
- **Triage** — re-validate each finding against live source, let the owner decide disposition, apply accepted fixes TDD-style.

Two rules sit above everything and never bend:

- **Findings are PROBLEMS, not fixes.** A finding must identify something **wrong, missing, or that could go wrong**. Correct behavior is NOT a finding at any severity — never report "X works correctly" or "no issues found". (A *proposed fix* rides along on each finding, but the finding is the problem, not the patch. Fixes are only *applied* in triage.)
- **Whole-repo snapshot, never a diff.** Every source file is in scope regardless of when it last changed. Do not scope by recent changes / PR diff.

**Run this in ultracode — native Workflow orchestration.** This skill is written for ultracode: an audit is a **fan-out** driven by the native Workflow tool — `agent()` / `parallel()` / `pipeline()`, schema-forced structured findings, and `budget`. The dimensions above are largely **independent file reviews, so fan them out in parallel** (one agent per file × dimension; Pass 6 is the exception — partitioned by category, not file). Let the runtime own concurrency, fan-out, and ordering; the **orchestrator** (the agent authoring the Workflow) owns the file survey, the synthesis/dedup, the security-disclosure gate, and the human-in-the-loop triage loop. Agents review files with clean contexts and **return schema-validated findings** — they do not file issues, write to disk, or hand off between stages.

> This consolidates what used to be nine separate skills run by one conversation. The old machinery — strictly-sequential passes, manual `Agent`-tool dispatch, `A01..` agent IDs for ordering, an "evidence-of-reading" preamble, and filing each finding to GitHub *during* the pass "because context compacts" — all existed only to fit a single context window with a primitive fan-out. Native ultracode removes every one of those constraints: clean per-agent contexts, runtime-owned fan-out/ordering, and structured findings that survive natively. Keep the **review substance** below; drop that scaffolding.

## Shared rules (every dimension inherits these)

**File discovery — ALL languages, no language-specific passes.** First read `CLAUDE.md` / `AGENTS.md` for project structure and conventions. Then glob every first-party source tree:
- Solidity: `src/**/*.sol`
- Rust: `crates/*/src/**/*.rs` (exclude `target/`)
- TS/JS: `packages/*/src/**/*.{ts,tsx,js,jsx}` (exclude `node_modules/`, `dist/`, `.svelte-kit/`)
- Svelte: `packages/*/src/**/*.svelte`

Exclude auto-generated files (bindings, build artifacts, `*.pointers.sol` and similar codegen), vendored deps (`lib/`, `node_modules/`), and lock files. When unsure whether a dir is first-party, check for a `Cargo.toml` / `package.json` / manifest. Every dimension reviews **every** language; a dimension's language-specific checklist items apply only to files of that language.

**Read in full.** Every assigned file is read top-to-bottom. Grep is for *cross-referencing* (is this name used in tests? does this constant appear elsewhere?), never a substitute for reading code.

**Severity scheme (verbatim):**
- **CRITICAL** — exploitable now with direct impact.
- **HIGH** — significant risk requiring specific conditions.
- **MEDIUM** — real concern with mitigating factors.
- **LOW** — minor issue or theoretical risk.
- **INFO** — suggestion for improvement with no direct risk.

**Every LOW+ finding carries a proposed fix** (authored now, *applied* only in triage): the file path(s) + line number(s) to change, and the exact change as a diff or before/after block. For a test-coverage finding the fix is a **complete** proposed test file/function — comprehensive (edge cases, boundaries, error paths, fuzz where applicable), not a single happy path; the same rigor Pass 2 demands of the code under review. Before proposing a test, answer *"how does this test cover the gap?"* — it must exercise the **specific** thing the finding identifies; if an existing test would produce the same result, it adds no coverage and is not valid.

**Dedup before flagging.** Read `audit/known-false-positives.md` (if present) and do not re-flag anything documented there. Also dedup against existing audit issues (see Triage).

**Domain rules (apply across every dimension, primarily the source-code ones):**
- **Rounding direction.** All rounding from precision loss (Float→fixed-decimal conversions, integer division) MUST favor **non-interactive** participants (order owner, contract, protocol — contracts count as non-interactive). For each rounding op: identify WHO is non-interactive, WHICH direction it rounds, WHETHER that direction favors the non-interactive party. Flag any rounding that favors **interactive** participants (`msg.sender`, arb callers, external protocols).
- **Variable naming.** Flag short/meaningless names (single chars `r`/`n`/`x`, abbreviations `ob`/`cfg`/`val`) for closure params, loop vars, or local bindings as **LOW** (e.g. `raindex_cfg` not `ob`, `network_key` not `nk`). Short-but-meaningful names (`id`, `url`, `key` when unambiguous) are fine.
- **Solidity/Foundry test rules.** Always use **specific** revert expectations — never bare `vm.expectRevert()` (matches any revert, can pass for the wrong reason). Use `vm.expectRevert(abi.encodeWithSelector(Error.selector, args...))` or `vm.expectRevert(Error.selector)`; only `vm.expectRevert(bytes(""))` (with a comment) when a revert genuinely carries no data. Per-test `forge-config: default.fuzz.runs` overrides exist intentionally for slow fuzz tests — don't remove without benchmarking (run it, check timing); conversely add a reduced-runs override when an un-overridden fuzz test takes more than a few seconds.

## Running the audit as a fan-out

1. **Survey (orchestrator).** Run file discovery once; produce the validated file list (and the set of process docs for Pass 0). Read `CLAUDE.md`/`AGENTS.md` and `audit/known-false-positives.md` once and pass their relevant content into agent prompts as context.
2. **Fan out dimensions in parallel.** Passes 0–5 are independent file reviews: dispatch one `agent({schema})` per **file × dimension** (or per file with the dimension's full checklist), concurrently. Pass 6 partitions by **hazard category, not file** (each agent scans the whole repo for its category). Each agent reads its file(s) in full and returns schema-validated findings — it does NOT create issues, write files, or order itself. Tier effort: **high** for Security / Correctness / Hazard (and any assembly/`unsafe`/crypto/eval-loop file); **lower** for Docs / naming-style Quality / Process. Some Quality dimensions are repo-global (dependency-version consistency, cross-file style, test-util DRY) — give those one repo-wide agent with the full file set rather than per-file agents that can't see duplication.
3. **Loop until dry.** Re-run a dimension/file until it surfaces no new findings; the hazard categories are explicitly non-exhaustive, so keep scanning and accrue newly-discovered patterns as emergent categories. Convergence is orchestrator-controlled (the file/category list is exhausted and a round adds nothing new), never an agent editing shared state.
4. **Synthesize (orchestrator, high effort, after the fan-out returns).** Collect all structured findings (`.filter(Boolean)`), dedup (cross-category overlaps, e.g. the same duplicate under both "multiple sources of truth" and "configuration spread"; and against `known-false-positives.md` + existing audit issues), and assign stable IDs. A worker's "clean" is an input to audit, not a verdict to relay.
5. **Apply the security-disclosure gate, then output.** See "Findings → issues" below.

**Schema-force every finding** so format/severity/fix-presence are guaranteed and orderable without manual ID prefixes or evidence-of-reading prose:
`{ id, dimension (0..6), severity (CRITICAL|HIGH|MEDIUM|LOW|INFO), file, lines, language, description, proposedFix }`.

## The review dimensions

### 0. Process review
Review the project's **process/instruction documents** (CLAUDE.md, AGENTS.md, and anything they reference), NOT source code, for defects that would cause a future session to misinterpret instructions:
- Ambiguous instructions a future session could misread (reused placeholder names, unclear defaults).
- Instructions fragile under context compression (relying on a subtle distinction).
- Missing defaults or undefined terms.
- Inconsistencies between process documents.

### 1. Security
Review every source file for security issues; consult CLAUDE.md/AGENTS.md for project-specific concerns. The list is "including but not limited to."

**General (all languages):** memory safety (OOB reads/writes, pointer arithmetic, missing bounds checks); input validation (untrusted input unsanitized, invalid values silently misinterpreted); authn/authz (missing access control, privilege escalation); injection (command/SQL/path-traversal or language equivalents); reentrancy & state consistency (external calls allowing re-entry before state is finalized); arithmetic safety (unchecked overflow/underflow, divide-by-zero, silent wrapping); error handling (missing checks, swallowed errors, inconsistent conventions); cryptography (weak algorithms, hardcoded secrets, bad randomness); resource management (leaks, unbounded allocation, DoS vectors).

**Solidity (`.sol`):** assembly blocks for memory safety; stack underflow/overflow protection in opcode `run` functions; integrity functions declaring inputs/outputs matching what `run` actually consumes/produces; reentrancy in opcodes making external calls (ERC20/721/extern); store namespace isolation (`msg.sender` + `StateNamespace` must always scope storage access); bytecode-hash verification in the deployer cannot be bypassed; function-pointer tables cannot index out of bounds or be manipulated; operand parsing rejects invalid operands rather than silently misinterpreting; the eval loop cannot be made to jump to arbitrary code via crafted bytecode; context-array access is bounds-checked; extern dispatch encodes/decodes `ExternDispatchV2` correctly; all reverts use custom errors, never string messages.

**Rust (`.rs`):** `unsafe` blocks and whether their invariants hold; `unwrap`/`expect` on fallible ops that could panic in production; `Result`/`Option` propagation (no silent drops); integer overflow in release builds (no panic on overflow in release); serialization/deserialization injection/corruption; TOCTOU races in file/network ops; sensitive data (keys/tokens) not logged or leaked in errors.

**TS/JS/Svelte:** prototype pollution, XSS, injection; user inputs validated before use in queries/commands/rendering; hardcoded secrets/API keys; unsafe `eval()`/`Function()`/template-literal injection; swallowed promises / missing `.catch()`; known-vulnerable dependency patterns.

### 2. Test coverage
For each source file, read **both** the source and its corresponding test file(s), and judge whether behavior is actually exercised. Locate tests via CLAUDE.md conventions and by grepping the function/type/contract name across the whole test dir (some files are tested indirectly — confirm before concluding "untested"). Conventions: Solidity (Foundry) `test/**/*.t.sol`; Rust `#[cfg(test)] mod tests` in-file or `tests/` (integration crates e.g. `crates/integration_tests`); TS `*.test.ts`/`*.spec.ts` or `__tests__/`. Report all gaps: source files with no test; functions with no test exercising them; error/failure paths with no test triggering them; missing edge cases (zero-length, max-length, off-by-one boundaries, odd/even parity). Proposed test fixes follow the test-rigor rules in Shared rules.

### 3. Documentation
Review all documentation for **completeness and accuracy** against the implementation. Apply any doc conventions from CLAUDE.md on top of:
- **Enumerate** every public function/method one-by-one (do not sample) and verify EACH has documentation; **list every undocumented one** as its own finding.
- Docs must describe **parameters and return values** (flag docs that omit them).
- After confirming docs exist, review them **against the implementation for accuracy** — flag docs that contradict, are stale relative to, or misdescribe actual behavior/signature.
- **README / top-level docs:** does it clearly describe what the project is + its design rationale? Does it reflect the current state (current interface/type names, not stale)? Any dangling references to renamed/removed/external entities that no longer exist?

### 4. Code quality
Review for maintainability, consistency, and good abstractions across the whole repo:
1. **Style consistency** — similar code using different patterns for the same thing.
2. **Leaky abstractions** — internal details exposed through public interfaces, implementation concerns crossing module boundaries, tight coupling between things that should be independent.
3. **Commented-out code** — each instance should be reinstated or deleted, not left commented.
4. **Build warnings** — no warnings from the project's toolchain; build warnings are real problems (**LOW or higher, NOT INFO**).
5. **Dependency version consistency** — no conflicting versions of the same dependency.
6. **Solidity bare `src/` imports** — flag bare `src/...` import paths in ALL `.sol` files **including test and script files** (they break when the project is a git submodule, where `src/` resolves to the consumer's source dir). Fix to relative (`../../src/lib/Foo.sol`) or remapped (`projectname/lib/Foo.sol`) paths. Do NOT dismiss test-file occurrences as out of scope — tests must compile when the repo is a dependency.
7. **Test-util DRY** — before reviewing tests, read existing helpers (`test/util/lib/*.sol`, `test/util/abstract/*.sol`); flag inline boilerplate that duplicates or could use an existing helper (e.g. hand-building config structs when a `default*` builder exists; inline log decoding when an `extract*FromLogs` helper exists; repeated multi-line patterns that should be a shared helper).
8. **Variable naming** — apply the naming rule from Shared rules (flag short/meaningless names as LOW).

### 5. Correctness / intent verification
Distinct from 2–4 (presence/absence): verify each **named** item does what it **claims**. For each file:
- **Tests vs. claims** — a test named for a specific error path MUST trigger that path; a test named for a boundary MUST test that boundary.
- **Algorithms & formulas** — when code implements a known concept (hash, sort, financial formula, bit pattern), verify it against the definition.
- **Constants & magic numbers** — named constants match their documented meaning; bitmasks have the right width, offsets match struct layout, sizes match spec.
- **NatSpec vs. implementation** — param descriptions match actual usage, return descriptions match what's returned, stated invariants hold.
- **Error conditions vs. triggers** — each error/revert is triggered by the condition its name/docs describe, not a different one (a test that uses a bare `vm.expectRevert()` and so could pass on the wrong revert is an intent mismatch here).
- **Interface conformance** — code claiming to implement a standard (ERC-165, ERC-20, …) actually satisfies all of its requirements.

### 6. Hazard surface
Architecture-level. Unlike 0–5 (local, per file), this reviews the **shape of the system over its lifetime** across code changes, redeployments, integrations, dependency bumps, and operator actions. Applied to every candidate: **"over the lifetime of this system, where does the design itself increase the chance of a mistake going undetected?"** Anywhere the answer is non-empty is a finding, and the goal is to **shrink** that surface, not document it. A *correct answer* (non-finding) is one of: (a) a single canonical source generators consume from; (b) a structural test / type-level check that fires when reality drifts from spec; or (c) a redesign removing the duplicate/ordering/manual step. A comment saying "remember to do X" is NOT an answer — comments rot, and a rotting comment is itself the hazard. **Partition by category, not by file** (the whole point is to look across files).

Categories (starting points, NOT exhaustive — anything fitting the framing question is in scope; add emergent patterns as new categories):
1. **Multiple sources of truth** — the same fact in 2+ places the code doesn't enforce to agree (token addresses in Solidity constants AND JSON registries AND frontend configs; permission strings in source AND test fixtures; codehashes in pointer files AND fork-test pins; storage layout in NatSpec AND assumed by assembly). For each: is there a generator+check, one canonical source, or a structural test asserting agreement? If none, file it.
2. **Implicit ordering dependencies** — operations that must run in a specific order without that order being machine-enforced (deploy scripts where A's bytecode embeds B's address; migrations where step N depends on N-1; build pipelines with no test verifying step Y's input matches step X's output; operator runbooks). Each without a structural pin is a finding.
3. **Convention-vs-enforcement gaps** — a naming/structural convention true today by author discipline but unchecked by code (`CONST = keccak256("CONST")` with no test asserting it for the whole class; "filename equals contract name" with no tooling; ERC-7201 storage-location constants some hardcoded as hex with no test pin). Search the test dir for an enumeration test that would catch a violation; if none, file it.
4. **Configuration spread** — one concept's configuration split across formats/files/repos so a coherent change is a multi-place edit (remappings + import paths + Nix inputs encoding the same dependency; network names duplicated across `foundry.toml`, deploy scripts, CI matrix, env conventions; versioning scattered across libs/pointers/README/CHANGELOG). Would adding one entry require touching N>1 places, and would the system silently work if you updated only some? If yes, file it.
5. **Generated artifacts with stale-detection gaps** — files generated from source that consumers may use without verifying they match current source (`*.pointers.sol`; ABI dumps/bindings/codegen; docs generated from NatSpec; cached deployment metadata). Each without a "regenerate-and-diff" check (CI or test) is a finding.
6. **Cross-repo / cross-language drift** — anywhere this repo is the **producer OR consumer** of state crossing a repo/language/runtime boundary without a contract pinning the shape (a token list this repo holds that another repo's JSON registry consumes — *or should* consume; event signatures decoded by indexers in another language without a generated binding; selectors frontends compute independently). If a unilateral change on either side would silently break the other and nothing here enforces the contract, file it — the structural fix may live in another repo, but the finding belongs here whenever the hazard is observable from here.
7. **Manual / out-of-band operational steps** — anything depending on a human remembering to act at the right time ("after bumping X, regenerate pointers manually" → better: a CI check failing on mismatch; "rotate the mint key every 90 days" → better: an on-chain timelock). Each is a finding; the report must propose the structural change removing the step.
8. **Defaults that encode brittle assumptions** — defaults/fallbacks/convenience APIs that work today because of a property the system happens to have but would silently break if it changes (a `balanceOf` view assuming total supply < 2^128 that silently wraps; a storage-slot derivation hardcoding an OZ namespace string that breaks on the next OZ major; a fixture using `block.timestamp = 1` masking a sign-comparison bug). For each: what property does it depend on, and is that property pinned by a test/type or implicit? If implicit, file it.

**Every Pass-6 finding names all four parts** (incomplete = revise before filing): (1) **the hazard** — what mistake the shape makes more likely; (2) **the shape that creates it** — the duplicate / ordering / manual step / brittle default; (3) **the realistic scenario** where it silently lands in production; (4) **the structural fix** — generator+check, enumeration test, or redesign. Pass-6 severity: HIGH = corrupts user state/money in a realistic scenario (wrong bridge address, stale codehash admitting a malicious impl, missed key rotation); MEDIUM = silently breaks a feature for some users (website missing a token, indexer crashes on an unknown event); LOW = breaks a dev workflow not production; INFO = a convention kept by discipline today that could be cheaply enforced.

## Findings → issues (output)

Findings are tracked as **GitHub issues** (the durable product record). The orchestrator files them once, after synthesis — not per-agent mid-run.

- **Security-disclosure gate (mandatory):** **CRITICAL and HIGH findings may be exploitable — do NOT auto-file them as public issues.** Present them to the user locally; the user decides whether to file publicly or fix first. Only **MEDIUM / LOW / INFO** are auto-filed.
- **Issue shape:** Title `[<FindingID>] [<SEVERITY>] <short description>`; Labels `audit`, `pass<N>` (the dimension), and the lowercase severity; Body = description + file path(s)/line(s) + the proposed fix. Ensure the label set exists first (`gh label list`; create any missing from `audit, pass0..pass6, critical, high, medium, low, info`).

## Triage (the one serial, human-in-the-loop stage)

Triage is the terminal stage and the **only** one that mutates code/docs. Keep it a **single orchestrated loop** — one finding at a time, the user decides — not a fan-out (serial here for UX, not for context).

- **Dedup vs closed issues first.** `gh issue list --label audit --state open`. Any current finding that duplicates a previously **closed** issue is itself closed with a comment referencing the prior one — never re-presented.
- **Ordering.** Before each finding, re-list open audit issues and take the **lowest open issue number**. One at a time; no batch-marking.
- **Re-validation gate (before showing the user).** A per-finding validator (clean context, reads only the cited source + test) returns `{valid, reason, missingCoverage[]}`. If the finding is wrong — describes behavior that doesn't exist, misreads the code, or flags correct behavior — **close it with a dismissal comment and move on without prompting the user.** Only survivors are presented.
- **Disposition scheme** (each → an issue action): **FIXED** (code changed → close), **DOCUMENTED** (docs/comments added → close), **DISMISSED** (no action → close with reason), **UPSTREAM** (belongs in a dependency/submodule → close noting the location), **PENDING** (stays open).
- **"Test already exists" rigor.** Triaging a finding as already-FIXED because a test exists demands the same rigor as writing a new fix: read the actual test, verify it covers the finding, check for missing edge/boundary cases, add tests if gaps remain. "Test exists" is not "properly tested."
- **Fixing is TDD (mandatory order):** write a test that reproduces the bug → **run it, confirm it FAILS** → write the fix → re-run, confirm it PASSES. Never write the fix before the test reproduces the bug. If the bug can't be reproduced in a test (e.g. a memory-alignment issue with no observable behavior), say so when presenting it. For a PENDING finding, start from the proposed fix already in the issue body (note what's underspecified, but use it as the plan rather than re-deriving). All fixes honor the Shared rules' fix-rigor, test, rounding, and naming requirements.

## Principles

- **Findings are problems, not fixes; correct behavior is never a finding.** Never report "X works correctly" / "no issues found".
- **Whole-repo snapshot, every file, every language — never scoped by diff or recency.**
- **Read in full; grep only to cross-reference.**
- **Every LOW+ finding ships a concrete, audit-grade proposed fix** (real diff / complete test), authored at finding time so triage has it ready — but applied only in triage.
- **CRITICAL/HIGH are never auto-filed publicly** — surface to the owner first.
- **Dedup against known-false-positives and prior closed issues** before presenting anything.
- **The orchestrator owns synthesis** — agents review files and return structured findings; the orchestrator dedups, severity-rates, gates disclosure, and drives triage. A worker's "clean" is a claim to audit, not a verdict to relay.
- **Honor the domain rules everywhere** — rounding favors non-interactive participants; no short/meaningless names; specific `vm.expectRevert` only; don't disturb intentional fuzz-run overrides.
- **Triage is the only stage that mutates code, and it does so TDD-first** — reproduce-fail, fix, pass.
