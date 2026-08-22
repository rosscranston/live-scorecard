# Connector Setup

No local MCP servers or connector credentials are assumed. Connector availability changes over time, so discover and verify the current official connector before installing it.

## General procedure for every service

1. Identify an official or trusted connector/MCP server.
2. Review its source, requested scopes, authentication storage, and maintenance status.
3. Install it only on the runtime that needs it.
4. Grant the minimum scopes needed for the current trial.
5. Configure the adapter in a machine-local file based on `config/connectors.example.yaml`.
6. Run read-only tests.
7. Run draft or sandbox-write tests.
8. Verify read-after-write and rollback.
9. Record the connector version and approved scopes in `decisions/connectors/` without storing credentials.
10. Enable production writes only through the approval policy.

## Recommended rollout order

### Notion

Required for Daily Call Logs, Projects, Sales FAQ, Terms, and Meeting Agenda.

Trial:

- search and fetch the target pages/databases;
- resolve data-source IDs without hard-coding secrets;
- create a test page in a dedicated sandbox area;
- search before every create;
- verify the created page and properties;
- test semantic duplicate prevention; and
- only then enable approved production writes.

### Google Calendar

Begin read-only. The morning brief scans work events, but creating or updating events always requires explicit approval.

### Gmail

Allow read/search and automatic draft creation. Sending remains approval-required every time.

### Attio

Begin read-only for deal truth. During trial, create/update operations require approval. Stage changes and Lost decisions permanently require explicit approval.

### Circleback

Read/search automatically when connected. Do not overwrite transcripts. Do not export raw client-sensitive transcripts into Git.

### Slack

Draft to `ross-notebook`. Posting remains approval-required.

## Missing local connector behavior

When ChatGPT web has access to a service but Hermes or Codex does not:

- interactive run: stop and ask one targeted question, explaining that the local runtime lacks the connector and listing the safe choices;
- scheduled run: write a sanitized exception record and stop that action;
- never substitute browser-cookie extraction or pretend the action completed.

## Config locations

Shared, non-secret intent:

```text
config/connectors.example.yaml
config/shared-settings.yaml
```

Machine-local implementation and credentials:

```text
~/.config/ai-operating-system/connectors.yaml
~/.config/ai-operating-system/secrets.env
~/.hermes/config.yaml
~/.hermes/.env
```
