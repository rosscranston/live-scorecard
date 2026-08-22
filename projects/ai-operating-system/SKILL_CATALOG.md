# Skill Catalog

All skills are explicit-only at version 1.0.0. The first eight listed below form the initial operating stack; the remaining four extend coaching, learning, pilot design, and team communication.

| ID | Invocation | Purpose | Risk class |
|---:|---|---|---|
| 01 | `work-auditor daily` / `work-auditor weekly` | Audit recent business AI work and improve safe learning artifacts | Medium |
| 02 | `chat-router` | Assign one project, tags, title, and archive state | Medium |
| 03 | `day-operator brief` / `day-operator review` | Build the morning cockpit and process the evening learning loop | High |
| 04 | `meeting-lifecycle` | Prepare and close out one sales meeting | Medium |
| 05 | `call-capture` | Extract sourced knowledge and actions from one call | Medium |
| 06 | `knowledge-curator` | Maintain deduplicated living sales knowledge | High |
| 07 | `demo-coach` | Role-play and improve sales responses | Low |
| 08 | `tax-translator` | Produce accurate plain-language learning entries | Medium |
| 09 | `pilot-planner` | Build measurable prospect pilots | Medium |
| 10 | `team-update` | Draft concise visibility updates | Low |
| 11 | `agent-architect` | Choose the correct agent, connector, script, and approval boundary | Medium |
| 12 | `workspace-operator` | Central connector execution, verification, audit, and rollback | Critical |

## Composition

```text
work-auditor
├── chat-router
├── agent-architect
└── workspace-operator (only for approved actions)

day-operator
├── meeting-lifecycle
├── call-capture
├── knowledge-curator
├── agent-architect
└── workspace-operator

knowledge-curator
├── tax-translator
└── workspace-operator
```

Each skill includes:

- `SKILL.md` — instructions and metadata;
- `README.md` — human-readable overview;
- `CHANGELOG.md` — semantic version history;
- `DECISIONS.md` — skill-specific decision log;
- `agents/openai.yaml` — explicit invocation policy and UI metadata;
- `references/` — shared or skill-specific rules;
- `tests/cases.json` — positive, negative, and boundary cases; and
- optional deterministic scripts.
