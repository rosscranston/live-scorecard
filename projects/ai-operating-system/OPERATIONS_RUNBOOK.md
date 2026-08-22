# Operations Runbook

## Daily cadence

| Local time | Job | Expected result |
|---:|---|---|
| 12:00 AM | `work-auditor daily` | Audit previous 24 hours and create morning handoff |
| 6:00 AM | `day-operator brief` | Create/refresh Notion Daily Call Log by 8:00 AM |
| 6:00 PM | `day-operator review` | Process completed calls and living knowledge through 6 PM |
| Friday 12:00 AM | `work-auditor weekly` | Audit previous 168 hours and create scorecard |

## Morning checklist

- Confirm the Daily Call Log exists and has today’s date and AE.
- Review Resolve Before Call warnings first.
- Check Today’s Mission and Must Win Today.
- Review no more than five preparation bullets and three priority questions per call.
- Give Useful, Wrong, Missing, and free-text feedback.

## Evening checklist

- Review end-of-day report before finishing work.
- Resolve approval proposals or leave them pending with a reason.
- Confirm automatic knowledge writes did not create semantic duplicates.
- Record any incorrect answer as a correction.

## Weekly checklist

- Review skill usage, failures, overrides, time saved, and newly discovered rules.
- Review proposed autonomy promotions.
- Review deploy keys and recent repository activity.
- Package and upload ChatGPT web releases only when an approved skill changed.

## Sync operations

Manual safe sync:

```bash
./scripts/ai-os-sync.sh
```

Inspect why automatic sync stopped:

```bash
cat ~/.local/state/ai-os/sync.log
# macOS alternative
cat ~/Library/Logs/ai-operating-system-sync.log
```

Approve a protected change after review:

```bash
./scripts/approve-and-sync.sh proposals/APPROVAL_FILE.md
```

## Stop automation

Mac sync:

```bash
./scripts/uninstall-auto-sync-macos.sh
```

Ubuntu sync:

```bash
./scripts/uninstall-auto-sync-ubuntu.sh
```

Hermes jobs:

```bash
./scripts/remove-hermes-cron.sh
```

Hermes gateway:

```bash
systemctl --user stop hermes-gateway.service
```
