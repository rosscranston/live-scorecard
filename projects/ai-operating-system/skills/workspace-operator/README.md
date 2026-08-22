# Workspace Operator

- **Skill slug:** `workspace-operator`
- **Version:** 1.0.0
- **Invocation policy:** Explicit only
- **Primary purpose:** Compartmentalize connector-specific reads and writes so business judgment is portable and service permissions are controlled centrally.

## Common invocations

- `workspace-operator`

## Installation

- Codex: install or symlink this folder under `~/.agents/skills/workspace-operator`.
- Hermes: include the repository `skills/` directory in `skills.external_dirs`.
- ChatGPT: upload the generated `workspace-operator-1.0.0.zip` package.

## Files

- `SKILL.md` — executable workflow instructions.
- `agents/openai.yaml` — UI metadata and explicit-only policy.
- `references/POLICY.md` — portable shared guardrails.
- `tests/cases.json` — acceptance examples.
- `CHANGELOG.md` — semantic version history.
- `DECISIONS.md` — skill decisions.
