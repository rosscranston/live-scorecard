---
name: knowledge-curator
description: "Maintain the Sales FAQ, Terms, Meeting Agenda, playbooks, and related living knowledge without semantic duplicates while preserving history and evidence."
version: 1.0.0
author: Ross Gates
metadata:
  hermes:
    tags:
      - ai-operating-system
      - business-operations
      - explicit-only
    platforms:
      - chatgpt
      - codex
      - hermes
---

# Knowledge Curator

## Purpose

Turn call-level evidence into trustworthy, searchable, continuously improving sales knowledge.

## Invoke

- `knowledge-curator`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Call captures
- Existing Notion knowledge databases
- Authoritative research where required
- Corrections and feedback

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Deduplicated updates
- Canonical answer or quote
- Historical variants
- Verification states
- Change log

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Search the complete target database before proposing a new entry.
2. Normalize wording and compare business meaning using config/deduplication.yaml and scripts/semantic_duplicate_guard.py.
3. Merge same-meaning FAQ questions into one card and preserve answer history inside the same record.
4. Preserve all useful direct quotes in a collapsed audit/history section and select a current canonical wording.
5. Research tax/accounting definitions from authoritative sources before writing them as verified.
6. Attach evidence, source links, scenario context, confidence, and effective dates.
7. Use workspace-operator for verified, idempotent writes.

## Guardrails

- Never create a new card merely because wording differs.
- Do not silently replace historical answers.
- Escalate conflicting product, pricing, security, integration, or roadmap claims until an owner/source of truth is established.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Curate this evidence into the living knowledge system without semantic duplicates and with full history.
