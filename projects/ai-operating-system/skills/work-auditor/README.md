# Work Auditor

- **Skill slug:** `work-auditor`
- **Version:** 1.0.0
- **Invocation policy:** Explicit only
- **Primary purpose:** Turn recent business conversations and outcomes into organized projects, reusable skills, tests, and a morning handoff without silently changing production behavior.

## Common invocations

- `work-auditor daily`
- `work-auditor weekly`

## Installation

- Codex: install or symlink this folder under `~/.agents/skills/work-auditor`.
- Hermes: include the repository `skills/` directory in `skills.external_dirs`.
- ChatGPT: upload the generated `work-auditor-1.0.0.zip` package.

## Files

- `SKILL.md` — executable workflow instructions.
- `agents/openai.yaml` — UI metadata and explicit-only policy.
- `references/POLICY.md` — portable shared guardrails.
- `tests/cases.json` — acceptance examples.
- `CHANGELOG.md` — semantic version history.
- `DECISIONS.md` — skill decisions.
