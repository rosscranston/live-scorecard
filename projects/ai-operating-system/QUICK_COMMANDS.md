# Quick Commands

## Validate

```bash
./scripts/doctor.sh
python3 scripts/validate_repo.py
python3 -m unittest discover -s tests -p 'test_*.py'
```

## Sync

```bash
./scripts/ai-os-sync.sh --dry-run
./scripts/ai-os-sync.sh
```

## Skills

```bash
./scripts/install-local-skills.sh
./scripts/package_skills.py
find ~/.agents/skills -maxdepth 2 -name SKILL.md -print
```

## Hermes

```bash
hermes doctor
hermes skills list
hermes gateway install
hermes cron list
hermes cron status
hermes cron runs "AI OS Morning Brief" --limit 20
```

## Services

```bash
# macOS sync
launchctl print gui/$(id -u)/com.ai-operating-system.sync

# Ubuntu sync
systemctl --user status ai-operating-system-sync.timer
journalctl --user -u ai-operating-system-sync.service -n 100 --no-pager
```
