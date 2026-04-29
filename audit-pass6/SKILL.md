---
name: audit-pass6
description: "Audit Pass 6: Hazard Surface. Reviews the architecture for shapes that increase the chance of future mistakes — across code changes, deployments, registries, generated artifacts, and other operational surfaces — and proposes structural changes that shrink that surface."
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Pass 6: Hazard Surface

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Pass 6 Instructions

Earlier passes review individual files for local correctness, coverage, documentation, code quality, and intent. This pass reviews the *architecture*: the shape of the system as it lives in the world over time, across code changes, deployments, registries, generated artifacts, and any other operational surface.

The framing question is: **"Over the lifetime of this system — through future code changes, redeployments, integrations, dependency bumps, and operator interventions — where does the design itself increase the chance of a mistake going undetected?"** Anywhere the answer is non-empty is a finding. The goal of every finding is to *shrink* that hazard surface, not to document it.

A correct answer for any case is one of: a single canonical source generators consume from; a structural test or type-level check that fires when reality drifts from the spec; or a redesign that removes the duplicate / ordering / manual step entirely. A comment saying "remember to do X" is not an answer — comments rot, and rotting comments are the hazard.

## Categories to review

These are starting points. The pass is broader than the list — anything that fits the framing question above is in scope, even if it doesn't match a category here. Add new categories to this file as recurring patterns emerge.

### 1. Multiple sources of truth for the same data

Same fact represented in two or more places that the code does not enforce to agree. Examples:
- Token addresses in Solidity constants AND in JSON registry files AND in frontend configs
- Permission strings hardcoded in source AND duplicated in test fixtures
- Codehashes in pointer files AND in fork-test pin constants
- Storage layout described in NatSpec AND assumed by assembly accessors

For each duplicate, ask: is there a generator + check, a single canonical source consumed by everything else, or a structural test that asserts agreement? If none, file the finding.

### 2. Implicit ordering dependencies

Code or operations that must run in a specific order without that order being machine-enforced. Examples:
- Deploy scripts where contract A's bytecode embeds contract B's address, so B must be regenerated first
- Migration scripts where step N depends on step N-1's side effects
- Build pipelines where output of step X feeds step Y but no test verifies Y's input matches X's output
- Operator runbooks: "after deploying X, manually call Y, then update the JSON"

Each ordering dependency without a structural pin (test, type, generated check, or refactor that removes the ordering) is a finding.

### 3. Convention-vs-enforcement gaps

A naming or structural convention that is true today by author discipline but not checked by code. Examples:
- "Constant name equals its keccak preimage" (`SCHEDULE_CORPORATE_ACTION = keccak256("SCHEDULE_CORPORATE_ACTION")`) with no test asserting this for the whole class of permission constants
- "Filename equals contract name" with no tooling check
- "Every `X_V<N>_TYPE_HASH` matches the namespace string `<repo>.<kebab>.<N>`" with no enumeration test
- "All ERC-7201 storage location constants match the spec formula" with one or more hardcoded as hex literals and no test pin

For each convention identified, search the test directory for an enumeration test that would catch a violation. If none exists, file a finding.

### 4. Configuration spread

A single concept whose configuration is split across formats / files / repos in a way that makes a coherent change a multi-place edit. Examples:
- `foundry.toml` remappings + import paths + Nix flake inputs all encoding the same dependency relationship
- Network names duplicated across `foundry.toml` `[rpc_endpoints]`, deploy scripts' `supportedNetworks()`, CI workflow matrix entries, and env var conventions
- Versioning scattered across `LibProdDeployVN.sol`, pointer files, README, and CHANGELOG

For each spread, ask: would adding a new entry require touching N > 1 places, and would the system silently work if you only updated some? If yes, file the finding.

### 5. Generated artifacts with stale-detection gaps

Files generated from source that consumers may use without verifying they match the current source. Examples:
- Pointer files (`*.pointers.sol`) — does CI or a test verify they match a fresh regeneration?
- ABI dumps, bindings, codegen outputs
- Documentation generated from NatSpec
- Cached deployment metadata (addresses, codehashes) committed to disk

Each generated artifact without a "regenerate-and-diff" check (in CI or as a test) is a finding.

### 6. Cross-repo and cross-language drift

Anywhere this repo exports state that is consumed by another repo, language, or runtime without a contract that pins the export shape. Examples:
- Token list in this repo's `LibProdTokensBase.sol` consumed (or that should be consumed) by a registry repo's JSON
- Event signatures emitted here, decoded by indexers in another language without a generated binding
- Error selectors / function selectors used by frontends that compute them independently
- ABI artifacts the deployment toolchain depends on across language boundaries

If the consumer would silently break on a unilateral change here (and the change is allowed because nothing in this repo enforces the contract), file the finding.

### 7. Manual / out-of-band operational steps

Anything that depends on a human remembering to do something at the right time. Examples:
- "After bumping rain.vats, regenerate pointer files manually" (better: a CI check that fails when pointer files don't match a fresh regeneration)
- "After scheduling a corporate action, manually update the indexer config" (better: an event the indexer subscribes to)
- "Operators must rotate the mint key every 90 days" (better: an on-chain timelock that enforces it)

Each manual step that could be automated or eliminated is a finding. The reporting should propose the structural change that removes the step.

### 8. Defaults that encode brittle assumptions

Default values, fallback paths, or convenience APIs that work today because of a property the system happens to have, but would silently break if that property changes. Examples:
- A `balanceOf` view that assumes total supply is below `2^128` and silently wraps above that
- A storage slot derivation that hardcodes an OZ namespace string and breaks on the next OZ major version
- A test fixture that uses `block.timestamp = 1` and would mask a sign-comparison bug if production timestamps were always positive

For each default identified, ask: what property does it depend on? Is that property pinned by a test or a type, or is it an implicit assumption? If implicit, file the finding.

## Reporting shape

Findings should name:
- **The hazard** — what mistake the current shape makes more likely
- **The shape that creates it** — the duplicate, ordering, manual step, brittle default, etc.
- **The realistic scenario** where the mistake silently lands in production
- **The structural fix** — generator, check, test, or redesign that shrinks the hazard surface

A finding without all four parts is incomplete and must be revised before filing.

## Severity guidance

- HIGH: the hazard would corrupt user state or money in a realistic scenario (wrong address used in a bridge, stale codehash that lets a malicious implementation slip in, mint key rotation missed)
- MEDIUM: the hazard breaks a feature silently for some users (website missing a token, indexer crashes on unknown event, deploy succeeds but emits the wrong constants)
- LOW: the hazard breaks a developer workflow but not production (new contributor's local build fails, a regenerate-and-diff check would have caught it earlier)
- INFO: convention is maintained by discipline today and the discipline could be cheaply enforced — flag for future hardening

## Scope and execution

This pass covers the entire repository as one unit. Per-file partitioning is not the right shape — the whole point is to look across files. A single subagent (or a small number of subagents partitioned by category, not by file) handles this pass.

Cross-repo findings are in scope when this repo is the producer or consumer of the state in question. The fix may live in another repo; the finding still belongs here when the hazard surface is observable from here.
