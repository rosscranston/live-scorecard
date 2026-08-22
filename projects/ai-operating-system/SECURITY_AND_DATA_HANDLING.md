# Security and Data Handling

## Classification

| Class | Examples | Git repository | Local agent processing |
|---|---|---:|---:|
| Public | Product documentation, generic templates | Allowed | Allowed |
| Internal | Sales process, skill instructions, sanitized examples | Allowed in private repo | Allowed |
| Confidential | Prospect strategy, non-public pricing context, account details | Only sanitized/minimized | Only on approved surface |
| Restricted client data | Tax returns, W-2s, 1099s, K-1s, SSNs, EINs, bank data | **Prohibited** | Approved cloud systems only |
| Secret | API keys, OAuth tokens, private SSH keys, cookies | **Prohibited** | Local secret stores only |

## Permanent prohibitions

The system must never autonomously:

- delete or archive records;
- send external email;
- post to Slack or another external channel;
- change a calendar invitation or attendee list;
- change a pipeline stage, mark a deal lost, or abandon a lead;
- publish a product, security, pricing, integration, legal, roadmap, or tax claim that lacks an approved source;
- bypass a missing connector using browser-session scraping;
- store or transfer raw client tax documents through Git; or
- force-push, resolve a Git conflict automatically, or overwrite a protected production rule.

These actions may be performed only after the policy explicitly permits them and, where stated, a human approves the exact action.

## Git controls

- Repository must be private.
- `.gitignore` excludes local secrets, logs, caches, generated bundles, raw exports, attachments, and connector state.
- `check_sensitive_content.py` scans tracked or all local files for likely secrets and high-risk identifiers.
- `sync_policy.py` blocks automatic commits touching protected paths.
- Auto-sync never uses `--force` or `--force-with-lease`.
- Each computer uses a distinct repository-scoped deploy key.
- Review and revoke deploy keys when a device is lost, retired, or reassigned.

## Credentials

Keep credentials in the native store used by the connector or in a local `.env` file outside the repository. Recommended locations:

```text
Mac:     ~/.config/ai-operating-system/secrets.env
Ubuntu:  ~/.config/ai-operating-system/secrets.env
Hermes:  ~/.hermes/.env and ~/.hermes/auth.json
SSH:     ~/.ssh/ai-os-<machine>
```

Never copy a private key between computers. Generate one key per device.

## Sensitive-content scanner limits

The scanner is a guardrail, not a guarantee. It can miss sensitive narrative text and can produce false positives. Review staged diffs before every protected or manual push:

```bash
git diff --cached
python3 scripts/check_sensitive_content.py --staged
```

## Incident response

If a secret or restricted document is committed:

1. Stop auto-sync on both machines.
2. Revoke or rotate the exposed credential immediately.
3. Remove the file from the current tree.
4. Rewrite Git history using an approved procedure; deleting one commit is not sufficient once pushed.
5. Force-update only through a deliberate incident process, never the normal sync script.
6. Review access logs and deploy keys.
7. Record the incident and add a regression test or scanner rule.
