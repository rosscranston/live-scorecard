---
name: workspace-operator
description: "Execute or stage service-neutral action envelopes across Notion, Attio, Gmail, Google Calendar, Slack, Circleback, and supported future services with approval, deduplication, idempotency, verification, and rollback."
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

# Workspace Operator

## Purpose

Compartmentalize connector-specific reads and writes so business judgment is portable and service permissions are controlled centrally.

## Invoke

- `workspace-operator`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- schemas/workspace-action.schema.json compliant action envelope
- Connector registry
- Approval policy
- Local secrets

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Verified result, draft, exception, or no-op with audit record

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Validate the action envelope and identify service, operation, target, evidence, confidence, approval state, and idempotency key.
2. Load only the adapter and credentials required for the target service.
3. Search for the target and semantic duplicates before writes.
4. Apply config/approval-policy.yaml; never treat a proposal as approval.
5. Execute the minimum permitted operation.
6. Read back the target and verify the intended state before reporting success.
7. Write a sanitized audit record and rollback information.
8. If a connector is unavailable, create an exception; in interactive mode ask one targeted question, and in headless mode stop safely.

## Guardrails

- Never store credentials, OAuth tokens, session cookies, or raw client tax data in Git.
- Never write when the target is ambiguous or below the configured confidence threshold.
- Never send email, alter calendar events, post Slack, change pipeline stage, archive, or delete without the required approval.
- Do not report success until a read-after-write verification succeeds.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Validate and execute this service-neutral action through the correct adapter, approval gate, duplicate check, verification, and audit path.
