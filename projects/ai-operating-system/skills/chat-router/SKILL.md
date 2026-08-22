---
name: chat-router
description: "Classify and organize business conversations into one primary project, tags, cross-links, a standardized title, and an archive state. Use when routing, renaming, or auditing conversations."
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

# Chat Router

## Purpose

Keep the conversation portfolio navigable without duplicating knowledge or losing cross-project context.

## Invoke

- `chat-router`
- `route this conversation`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Conversation title and content
- Project map
- Known lifecycle and archive rules

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Primary project
- Tags
- Cross-links
- Proposed or executed title
- Lifecycle state
- Confidence and evidence

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Determine whether the work is business-related, onboarding-reusable, or a true personal one-off.
2. Select exactly one primary project using config/project-map.yaml.
3. Attach secondary tags and cross-links rather than copying the conversation.
4. Title using Project | Outcome | YYYY-MM-DD.
5. Mark inactive one-offs as archive candidates after 30 days; deletion or archival remains approval-required.
6. If routing confidence is below the configured threshold, create an exception and ask one targeted question.
7. Return a schemas/chat-route.schema.json compliant record.

## Guardrails

- Never duplicate the same conversation into multiple projects.
- Never archive or delete autonomously.
- Do not infer a business project from a weak topical resemblance alone.
- Correct obvious spelling in the proposed title while preserving meaning.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Route this conversation to one primary project, add non-duplicative cross-links, and use the approved title and archive rules.
