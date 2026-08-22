# Scripts

These scripts install, validate, synchronize, package, and diagnose the AI Operating System.

## Guided installers

- `guided-install-macos.sh` — guided Mac setup for the work MacBook Pro.
- `guided-install-ubuntu.sh` — guided Ubuntu/Hermes setup.

## GitHub and synchronization

- `create-private-github-repo.sh` — initialize and publish the canonical private GitHub repository from the first computer.
- `setup-repo-deploy-key.sh` — generate a machine-specific, repository-scoped SSH deploy key.
- `ai-os-sync.sh` — conservative pull/commit/push cycle used by both computers.
- `approve-and-sync.sh` — deliberately stage a protected production change and synchronize it.
- `install-auto-sync-macos.sh` — install the macOS launchd job.
- `install-auto-sync-ubuntu.sh` — install the Ubuntu systemd user timer.

## Skills and Hermes

- `install-local-skills.sh` — link repository skills into the Codex user skill directory.
- `package_skills.py` — create uploadable ChatGPT skill ZIPs and the aggregate skill bundle.
- `configure-hermes.py` — point Hermes at the repository skills and enforce skill-write approval.
- `install-hermes-cron.sh` — install the four defined AI OS schedules.

## Validation and safety

- `validate_repo.py` — run schemas, tests, secret scanning, and structure checks.
- `check_sensitive_content.py` — block common secrets and likely taxpayer identifiers.
- `sync_policy.py` — separate automatically syncable paths from approval-required production paths.
- `semantic_duplicate_guard.py` — deterministic duplicate-candidate screening before Notion/Attio writes.
- `doctor.sh` — report installation and service health.

Run `./scripts/validate_repo.py` before every release and after changing installation or synchronization logic.
