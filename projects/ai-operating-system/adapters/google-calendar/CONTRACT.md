# Google Calendar Adapter Contract

## Status

Implementation not selected. Configure an official or trusted connector and document it under `decisions/connectors/`.

## Required capabilities

- Report available read, draft, write, delete, and verification operations.
- Accept a validated `schemas/workspace-action.schema.json` envelope.
- Use least-privilege authentication stored outside Git.
- Resolve the exact target and stop on ambiguity below threshold.
- Search before create and perform a semantic duplicate check when relevant.
- Enforce `config/approval-policy.yaml`.
- Verify the result by reading the target after execution.
- Return a sanitized result or exception.

## Service-specific notes

See `CONNECTOR_SETUP.md` and `APPROVAL_POLICY.md` before implementation.
