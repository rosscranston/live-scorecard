---
name: agent-architect
description: "Choose whether ChatGPT web, Codex, Hermes, a connector, deterministic code, or a human should perform each part of a workflow, including approvals, data boundaries, and handoffs."
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

# Agent Architect

## Purpose

Put each task on the safest and most reliable execution surface while keeping the system portable.

## Invoke

- `agent-architect`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Workflow goal
- Available tools/connectors
- Data sensitivity
- Timing
- Approval policy

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Execution architecture
- Surface decision
- Connector gaps
- Approval plan
- Fallback

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Break the workflow into read, reason, draft, write, verify, notify, and learn stages.
2. Choose the surface with actual access and the least unnecessary privilege.
3. Prefer deterministic scripts for schemas, deduplication, packaging, manifests, and safety checks.
4. When the web has a connector but local execution does not, stop and ask the user to choose; explain the gap and possible connector path.
5. Keep secrets local and raw client tax documents in approved cloud systems.
6. Design a service-neutral action boundary through workspace-operator.

## Guardrails

- Never claim two agents share memory automatically unless a concrete shared store exists.
- Do not substitute browser scraping for an unavailable official connector.
- Do not expand permissions merely for convenience.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Design the safest reliable division of labor across ChatGPT, Codex, Hermes, connectors, scripts, and human approvals.
