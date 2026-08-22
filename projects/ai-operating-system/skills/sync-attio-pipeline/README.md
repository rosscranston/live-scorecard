# Sync Attio Pipeline

- **Skill slug:** `sync-attio-pipeline`
- **Version:** 1.0.0
- **Invocation policy:** Explicit only
- **Active write target:** Notion `Deals-Temp`
- **Attio writes:** Disabled pending permission and explicit activation

## Purpose

Reconcile completed prospect meetings and transcript-ready follow-ups into one evidence-backed deal per company. The skill combines Google Calendar, Circleback, Notion Daily Planner notes, and bounded Gmail evidence, then verifies every write.

## Schedule

The operating plan calls for sweeps at 7:00 AM, 11:00 AM, 2:00 PM, 5:00 PM, and 7:00 PM Pacific time. A disabled webhook configuration is included for a later transcript-ready receiver. Creating the schedule or webhook is a separate execution step.

## Approval boundary

Forward moves to Lead and Prove Value are automatic when supported by verified meeting counts and confidence is at least 0.90. Contracting, Won, Lost, backward moves, ambiguous merges, Attio activation, and new webhook activation require Ross's explicit approval.

## Installation

- Codex: install or symlink this folder under `~/.agents/skills/sync-attio-pipeline`.
- Hermes: include the repository `skills/` directory in `skills.external_dirs`.
- ChatGPT: upload the generated package when a packaged release is needed.

## Files

- `SKILL.md` — executable workflow.
- `agents/openai.yaml` — UI metadata and explicit invocation policy.
- `references/` — approval, evidence, stage, fit, minimum, field, and page-body rules.
- `tests/cases.json` — positive, negative, and boundary acceptance cases.
- `CHANGELOG.md` — version history.
- `DECISIONS.md` — locked operating decisions.
