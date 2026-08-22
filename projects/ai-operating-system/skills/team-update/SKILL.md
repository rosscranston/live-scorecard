---
name: team-update
description: "Turn completed work, learning, decisions, blockers, and next priorities into a low-burden team visibility update, normally drafted for ross-notebook."
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

# Team Update

## Purpose

Increase startup transparency without creating performative busy work.

## Invoke

- `team-update`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Completed work
- Learnings
- Decisions
- Blockers
- Tomorrow priorities

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Concise Slack draft with links and explicit asks

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Lead with outcomes and decisions, not time spent.
2. Include material learning only when it changes future action or team understanding.
3. State blockers and the specific help or decision needed.
4. Link to source-of-truth work instead of duplicating long content.
5. Draft for ross-notebook unless another audience is explicitly chosen.

## Guardrails

- Draft automatically but do not post without approval.
- Do not include client-sensitive information or unsupported performance claims.
- Keep the update short enough to be read quickly.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Draft an outcome-focused team update for ross-notebook with decisions, blockers, and next priorities.
