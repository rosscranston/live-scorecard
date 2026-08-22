# Installation Checklist

## MacBook Pro

- [ ] Extract repository outside iCloud/Dropbox/Google Drive.
- [ ] Read security and approval policies.
- [ ] Run `./scripts/bootstrap-macos.sh`.
- [ ] Run `gh auth login` and verify with `gh auth status`.
- [ ] Create private repository with `create-private-github-repo.sh`.
- [ ] Install Mac repository deploy key.
- [ ] Install 12 Codex skill symlinks.
- [ ] Install macOS auto-sync LaunchAgent.
- [ ] Run doctor and dry sync.
- [ ] Generate ChatGPT skill ZIPs.
- [ ] Upload and verify required skills in ChatGPT web.

## Ubuntu / Hermes

- [ ] Generate a separate Ubuntu deploy key.
- [ ] Register only the Ubuntu public key with the private repository.
- [ ] Clone using the Ubuntu SSH alias.
- [ ] Run `./scripts/bootstrap-ubuntu.sh`.
- [ ] Configure Hermes provider; verify `hermes doctor`.
- [ ] Install 12 shared skill symlinks.
- [ ] Add repository skills to Hermes external directories.
- [ ] Confirm `skills.write_approval: true`.
- [ ] Install Hermes gateway user service.
- [ ] Enable user linger after deciding it is appropriate.
- [ ] Confirm machine timezone is America/Los_Angeles.
- [ ] Install four Hermes cron jobs.
- [ ] Manually run and review each job before unattended use.
- [ ] Install Ubuntu auto-sync user timer.
- [ ] Run doctor and dry sync.

## Connectors

- [ ] Notion read-only tests.
- [ ] Notion sandbox write, duplicate, verification, and rollback tests.
- [ ] Calendar read-only tests.
- [ ] Gmail read and draft tests; sending remains approval-required.
- [ ] Attio read-only tests and sandbox updates.
- [ ] Circleback read-only tests.
- [ ] Slack draft test; posting remains approval-required.
- [ ] Record every approved connector, scope, and version without credentials.

## First week

- [ ] Record Useful / Wrong / Missing feedback every day.
- [ ] Confirm every correction creates positive and negative tests.
- [ ] Review daily exceptions.
- [ ] Review Friday skill scorecard.
- [ ] Do not promote autonomy without five clean reviewed runs and a scoped approval.
