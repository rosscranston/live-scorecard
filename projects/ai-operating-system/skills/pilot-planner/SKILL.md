---
name: pilot-planner
description: "Design a prospect-specific trial or pilot with representative returns, known outputs, proof points, integration prerequisites, success criteria, owners, deadlines, and next-call agenda."
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

# Pilot Planner

## Purpose

Make proof-of-value work decisive, measurable, and tied to the prospect’s buying criteria.

## Invoke

- `pilot-planner`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Prospect context
- Decision criteria
- Tax software
- Representative returns
- Known completed comparison return

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Pilot plan
- Success criteria
- Responsibilities
- Risks
- Next-call agenda

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Identify the prospect’s deciding requirement and current stage.
2. Select two to three representative returns and at least one already-completed comparison return when available.
3. Define inputs, expected outputs, integration path, owners, and due dates.
4. Define objective success criteria and what evidence will be shown on the review call.
5. Surface prerequisites and unresolved product/integration claims before committing.
6. Create action proposals and a next-call agenda.

## Guardrails

- Do not promise an integration or timeline without an approved source.
- Do not place raw client tax documents in the Git repository or local AI OS state.
- Keep client files in approved cloud systems only.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Build a measurable pilot that proves the prospect’s actual deciding requirements without unsupported commitments.
