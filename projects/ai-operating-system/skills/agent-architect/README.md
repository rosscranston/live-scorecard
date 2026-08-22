# Agent Architect

- **Skill slug:** `agent-architect`
- **Version:** 1.0.0
- **Invocation policy:** Explicit only
- **Primary purpose:** Put each task on the safest and most reliable execution surface while keeping the system portable.

## Common invocations

- `agent-architect`

## Installation

- Codex: install or symlink this folder under `~/.agents/skills/agent-architect`.
- Hermes: include the repository `skills/` directory in `skills.external_dirs`.
- ChatGPT: upload the generated `agent-architect-1.0.0.zip` package.

## Files

- `SKILL.md` — executable workflow instructions.
- `agents/openai.yaml` — UI metadata and explicit-only policy.
- `references/POLICY.md` — portable shared guardrails.
- `tests/cases.json` — acceptance examples.
- `CHANGELOG.md` — semantic version history.
- `DECISIONS.md` — skill decisions.
