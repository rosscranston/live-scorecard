---
name: work-auditor
description: "Audit the previous 24 or 168 hours of business AI work, identify reusable workflows, organize learnings, propose tested skill improvements, and generate a structured handoff. Use explicitly as work-auditor daily or work-auditor weekly."
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

# Work Auditor

## Purpose

Turn recent business conversations and outcomes into organized projects, reusable skills, tests, and a morning handoff without silently changing production behavior.

## Invoke

- `work-auditor daily`
- `work-auditor weekly`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Accessible business conversations or exports for the requested window
- Approved project map and routing rules
- Current skill catalog, tests, feedback, and exceptions

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Audit report
- Routing manifest
- Skill-change proposals
- Morning handoff
- Test/example additions

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Resolve mode: daily means the immediately preceding 24 hours; weekly means the immediately preceding 168 hours.
2. Limit the audit to business work unless a personal-looking item could support work, onboarding, or a conference.
3. Inventory conversations, outputs, decisions, failures, corrections, commitments, and repeated steps.
4. Invoke chat-router logic to assign one primary project plus tags and cross-links; never duplicate a conversation.
5. Identify one high-value occurrence or repeated workflows that merit a skill or module.
6. Convert every correction into one negative example and one corrected positive example.
7. Automatically update tests, examples, changelogs, decision logs, indexes, and non-behavioral metadata.
8. For production rules, approval gates, business claims, or permissions, create a change proposal instead of editing silently.
9. Emit schemas/audit-output.schema.json and schemas/morning-handoff.schema.json compliant outputs.

## Guardrails

- Do not claim to audit ChatGPT history that is not actually accessible to the runtime.
- Do not scrape browser sessions, cookies, or private ChatGPT endpoints.
- Do not commit secrets, client tax documents, raw transcripts containing sensitive client data, or credentials.
- Ask one targeted question when a material ambiguity cannot be resolved from sources.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Run the approved daily or weekly business-work audit, preserve evidence, update safe learning artifacts, and prepare any approval-required production changes.
