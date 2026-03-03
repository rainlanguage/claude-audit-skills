---
name: audit-pass1
description: "Audit Pass 1: Security. Reviews source files for security vulnerabilities. Consults CLAUDE.md for project-specific security concerns."
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# Audit Pass 1: Security

## General Rules

Before starting, read and follow `~/.claude/skills/audit/GENERAL_RULES.md`.

## Pass 1 Instructions

Review for all security issues. Check CLAUDE.md for project-specific security concerns. General areas to review include but are not limited to:

- Memory safety: out-of-bounds reads/writes, incorrect pointer arithmetic, missing bounds checks
- Input validation: untrusted inputs accepted without sanitization, invalid values silently misinterpreted
- Authentication and authorization: missing access controls, privilege escalation paths
- Injection: command injection, SQL injection, path traversal, or language-specific equivalents
- Reentrancy and state consistency: external calls that allow re-entry before state is finalized
- Arithmetic safety: unchecked overflow/underflow, division by zero, silent wrapping
- Error handling: missing error checks, errors swallowed silently, inconsistent error conventions
- Cryptographic issues: weak algorithms, hardcoded secrets, improper randomness
- Resource management: leaks, unbounded allocation, denial-of-service vectors

### Solidity-Specific Concerns

- Check assembly blocks for memory safety: out-of-bounds reads/writes, incorrect pointer arithmetic, missing bounds checks
- Verify stack underflow/overflow protection in opcode `run` functions
- Check that integrity functions correctly declare inputs/outputs matching what `run` actually consumes/produces
- Look for reentrancy risks in opcodes that make external calls (ERC20, ERC721, extern)
- Verify namespace isolation in the store — `msg.sender` + `StateNamespace` must always scope storage access
- Check that bytecode hash verification in the expression deployer cannot be bypassed
- Verify function pointer tables cannot index out of bounds or be manipulated
- Check that operand parsing rejects invalid operand values rather than silently misinterpreting them
- Verify that the eval loop cannot be made to jump to arbitrary code via crafted bytecode
- Check that context array access is bounds-checked
- Review extern dispatch for correct encoding/decoding of `ExternDispatchV2`
- Ensure all reverts use custom errors, not string messages (`revert("...")` is not allowed)
