---
name: audit-pass0
description: "Audit Pass 0: Process Review. Reviews project process documents for ambiguity, fragility under context compression, and inconsistencies."
allowed-tools: Read, Grep, Glob, Write
---

# Audit Pass 0: Process Review

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Pass 0 Instructions

Review project process documents (e.g., CLAUDE.md and any referenced instructions) for issues that would cause future sessions to misinterpret instructions. This pass reviews process documents, not source code. No subagents needed — the documents are small enough to review in the main conversation. File findings as GitHub issues per GENERAL_RULES.md.

Check for:
- Ambiguous instructions a future session could misinterpret (e.g. reused placeholder names, unclear defaults)
- Instructions that are fragile under context compression (e.g. relying on subtle distinctions)
- Missing defaults or undefined terms
- Inconsistencies between process documents
