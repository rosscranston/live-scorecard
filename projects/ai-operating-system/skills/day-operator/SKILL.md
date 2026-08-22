---
name: day-operator
description: "Create the approved Notion morning Daily Call Log or run the 6 PM end-of-day review. Use explicitly as day-operator brief or day-operator review."
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

# Day Operator

## Purpose

Help the AE act better in the moment by turning verified sources and overnight learning into a concise operating cockpit.

## Invoke

- `day-operator brief`
- `day-operator review`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Google Calendar
- Attio
- Circleback
- Gmail
- Notion Projects and playbooks
- Morning handoff

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Verified Daily Call Log page
- Readiness notification draft
- End-of-day knowledge and action update

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. For brief mode, follow references/DAILY_BRIEF_REQUIREMENTS.md and config/daily-brief.json exactly.
2. Scan all work calendar events and perform deep preparation only for external or sales meetings.
3. Keep verified source facts visible and generated or inferred content collapsed in an ⚠️ AI section unless an approved exception applies.
4. Create or update one page per AE and date using YYYY-MM-DD | AE; verify the write before reporting success.
5. For review mode, process completed calls through 6:00 PM; calls after that roll into the following review.
6. Update approved living knowledge artifacts through workspace-operator action envelopes and preserve source links.
7. Capture Useful, Wrong, Missing, and free-text feedback; convert corrections into tests.

## Guardrails

- Do not rewrite the AE’s manual shorthand notes during a call.
- Never round returns per year or invent missing source facts.
- Show Resolve Before Call when material sources conflict.
- Draft Slack readiness notifications; do not post without approval.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Build or review the Daily Call Log using the approved source ownership, page order, visibility, preparation, and feedback rules.
