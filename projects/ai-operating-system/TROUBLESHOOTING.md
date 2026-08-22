# Troubleshooting

## Codex does not show a skill

```bash
./scripts/install-local-skills.sh
find ~/.agents/skills -maxdepth 2 -name SKILL.md -print
```

Restart Codex. Confirm there are no duplicate skill names in another loaded location.

## ChatGPT rejects a skill ZIP

- Unzip and review the contents.
- Ensure the skill has one root folder containing `SKILL.md`.
- Confirm frontmatter includes `name` and `description`.
- Remove generated logs, secrets, binaries, or unsupported files.
- Run `python3 scripts/validate_repo.py` and package again.

## Hermes does not show repository skills

```bash
python3 scripts/configure-hermes.py --check
hermes skills list
```

Confirm the repository path in `~/.hermes/config.yaml` under `skills.external_dirs` is absolute and exists. Restart the Hermes session or gateway after config changes.

## Hermes cron jobs do not run

```bash
hermes cron status
hermes cron list
systemctl --user status hermes-gateway.service --no-pager
journalctl --user -u hermes-gateway.service -n 200 --no-pager
```

Confirm linger is enabled if the user logs out:

```bash
loginctl show-user "$USER" -p Linger
```

## Auto-sync stopped

Inspect:

```bash
git status
./scripts/ai-os-sync.sh --dry-run
```

Common reasons:

- a protected path changed without approval;
- the sensitive scanner found a possible secret;
- a merge/rebase conflict exists;
- the deploy key lacks write access;
- the remote is not the SSH alias configured for that machine; or
- validation failed.

## GitHub SSH failure

```bash
ssh -vT git@github-ai-os
ls -l ~/.ssh/ai-os-*
git remote -v
```

Check file permissions: directory `700`, private key `600`, config `600`.

## Duplicate Notion card created

1. Stop the relevant write automation.
2. Preserve both records until the canonical record is chosen.
3. Run `scripts/semantic_duplicate_guard.py` with the two normalized records.
4. Merge answer history into the canonical card.
5. Link or archive the duplicate only after approval.
6. Add the failure and correction to the affected skill’s test cases.

## Timezone mismatch

The business schedule is America/Los_Angeles. Confirm:

```bash
timedatectl
python3 - <<'PY'
from zoneinfo import ZoneInfo
from datetime import datetime
print(datetime.now(ZoneInfo('America/Los_Angeles')))
PY
```

Hermes schedules explicitly include the intended timezone in their prompts/configuration; do not rely solely on the computer’s display timezone.
