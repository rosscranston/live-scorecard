---
name: meeting-lifecycle
description: "Prepare, guide, and close out one sales meeting using the correct meeting type, playbook, evidence, notes boundary, next step, and follow-up actions."
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

# Meeting Lifecycle

## Purpose

Apply consistent sales process before, during, and after each meeting while preserving human judgment.

## Invoke

- `meeting-lifecycle`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Calendar event
- Attio deal
- Latest Circleback context
- Meeting playbook
- Relevant email and commitments

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Preparation brief
- Checklist
- Post-call summary
- One-sentence next step
- Action proposals

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Identify the chronological Call-# and one approved meeting type: Discovery, Hands-on Demo, Output Review, Desktop Software, or Onboarding.
2. Load the matching playbook and current prospect evidence.
3. Define the sourced current next step and an inferred Win Condition, keeping inference collapsed during rollout.
4. Provide no more than five visible preparation bullets and three priority questions unless a critical exception exists.
5. After the call, preserve manual notes, summarize evidence, capture questions and commitments, and create a one-sentence next step.
6. Pass write proposals to workspace-operator.

## Guardrails

- Meeting type is not automatically the same as Call-#.
- Do not change deal stage without explicit approval.
- Do not claim a follow-up was sent, booked, or written unless verified.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Run the approved lifecycle for this meeting from preparation through verified follow-up proposals.
