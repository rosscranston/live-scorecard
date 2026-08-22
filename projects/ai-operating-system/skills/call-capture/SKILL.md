---
name: call-capture
description: "Process one completed Circleback call into sourced notes, questions, direct quotes, terms, actions, decisions, and proposed knowledge-base changes."
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

# Call Capture

## Purpose

Extract complete reusable evidence from one call without confusing raw meeting truth with AI interpretation.

## Invoke

- `call-capture`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Circleback transcript, recording metadata, and hand-typed notes
- Related Attio deal and prior context

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Sourced call record
- Questions and answers
- Direct quotes
- Terms
- Actions
- Knowledge proposals

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Read the full available call record and preserve source links and exact quotes.
2. Separate explicit statements from inference.
3. Extract prospect profile, pain, urgency, authority, objections, decision criteria, promises, and next step.
4. Extract every useful direct quote and nominate a canonical quote without deleting history.
5. Extract tax, accounting, software, security, and sales terms for curator review.
6. Emit service-neutral workspace actions rather than connector-specific writes.

## Guardrails

- Circleback remains the exhaustive meeting source; do not overwrite the transcript.
- Do not expose client-sensitive transcript content in Git or tests.
- Historical calls are context only unless the user explicitly requests backfill writes.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Capture this completed call into sourced, deduplicable knowledge and action proposals.
