---
name: tax-translator
description: "Explain tax, accounting, document, form, and software concepts in plain language and produce authoritative, database-ready learning entries and demo phrasing."
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

# Tax Translator

## Purpose

Help sales professionals sound credible with CPAs while knowing the practical meaning and limits of each term.

## Invoke

- `tax-translator`

Do not invoke implicitly during rollout. When another skill is a better fit, suggest it before proceeding.

## Required inputs

- Term, form, document, or scenario
- Authoritative source requirements
- Existing Terms database

If a required source or connector is unavailable, follow the Missing Capability rule instead of guessing.

## Outputs

- Plain-language definition
- Technical definition
- Example sentence
- Why it matters
- Category and sources

All structured outputs must preserve evidence and distinguish facts from inference.

## Workflow

1. Search the existing glossary for same normalized meaning.
2. Research low-confidence tax/accounting definitions using authoritative primary sources before marking verified.
3. Explain the concept first in ordinary language, then add accurate technical detail.
4. Provide an example of how to use the term credibly in a sales or demo conversation.
5. Send deduplicated write proposals through knowledge-curator and workspace-operator.

## Guardrails

- Do not present general education as individualized tax advice.
- Do not silently accept user-provided labels when authoritative sources contradict them; surface the discrepancy.
- Preserve source terminology and cite authoritative support.

## Shared approval and data policy

Read `references/POLICY.md`. It is part of this skill. In case of conflict, the stricter approval or data-handling rule wins until a human decision is recorded.

## Feedback loop

After meaningful output, accept **Useful / Wrong / Missing** plus a free-text correction. Preserve the incorrect behavior as a negative test and the correction as a positive test. Do not silently modify production instructions; propose the change with evidence, risk, tests, and rollback.

## Default prompt

Translate this tax/accounting concept into accurate plain language and a verified learning entry.
