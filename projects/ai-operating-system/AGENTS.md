# Repository Instructions for AI Agents

## Mission

Maintain a safe, evidence-backed AI operating system that helps the user act better in the moment and improves through explicit feedback.

## Required behavior

- Read `SECURITY_AND_DATA_HANDLING.md`, `APPROVAL_POLICY.md`, and `config/shared-settings.yaml` before making operational changes.
- Use one primary project plus tags/cross-links; never duplicate conversations or knowledge solely to classify them twice.
- Preserve source links and distinguish verified facts, direct quotes, inference, and recommendations.
- Use `workspace-operator` action envelopes for service writes.
- Search before create, perform semantic duplicate checks, and verify after write.
- Treat GitHub repositories not owned by the configured primary owner as read-only. Do not create, push, open pull requests, change settings, add deploy keys, or perform other repository writes unless the primary user explicitly changes this rule.
- Ask one targeted question when material ambiguity remains in interactive work.
- In scheduled work, write a sanitized exception and stop rather than guessing.
- Convert every user correction into a negative and corrected positive test.

## Prohibited

- Never store client tax documents, credentials, OAuth tokens, cookies, or private keys in this repository.
- Never silently change production skill behavior, approval gates, or source-of-truth policy.
- Never force-push or automatically resolve a judgment-bearing Git conflict.
- Never claim an external action succeeded without read-after-write verification.

## Validation

Before committing:

```bash
python3 scripts/check_sensitive_content.py --staged
python3 scripts/validate_repo.py
python3 -m unittest discover -s tests -p 'test_*.py'
```
