# Codex migration bundle

This folder preserves the programs, products, scheduled-task definitions, personal Codex skills, and selected Codex history found on the Hermes Mac for **2026-08-11 through 2026-08-22**.

It is designed for a **private** GitHub repository. Do not make this repository public.

## What is here

- `projects/`: source snapshots for the native Mac apps, AI Operating System, and private notes.
- `products/`: built `.app` bundles, standalone web tools, DreamBig deliverables, sales-enablement artifacts, and explicitly synthetic demo tax documents.
- `codex-portable/`: scheduled-task definitions, personal skills, rules, and a sanitized settings reference.
- `private-state-plaintext/`: local-only staging for raw task logs, task index, memories, and automation run memories. Git ignores this entire directory.
- `encrypted/`: destination for the encrypted private-state archive that may be committed to the private repository.
- `scripts/`: encryption, verification, and new-Mac restore helpers.

## Before pushing

Keep Codex closed, then run:

```bash
cd /path/to/codex-migration-2026-08-11-to-2026-08-22
./scripts/encrypt-private-state.sh
./scripts/verify.sh
```

The encryption script asks for a passphrase without placing it in the shell command or repository. Save that passphrase in your password manager. The encrypted history cannot be restored without it.

After verification, create a private repository owned by `rosscranston`:

```bash
git init -b main
git add .
git status --short
git commit -m "Add Codex migration bundle through 2026-08-22"
gh repo create rosscranston/codex-migration --private --source=. --remote=origin --push
```

Review `git status` before committing. `private-state-plaintext/` must not appear.

## Important limits

- Credentials, OAuth state, cookies, private keys, live SQLite databases, WAL files, logs, plugin caches, and computer-control state are intentionally excluded. Sign in again on the new Mac.
- Raw Codex JSONL task files are preserved in the encrypted archive. Restoring those files is best-effort; Codex may not repopulate every old task in the desktop sidebar because the mutable local databases are intentionally not copied.
- Scheduled-task definitions are preserved, but their project IDs and absolute paths are machine-local. Verify or recreate each task in the Codex desktop app after restoring its project.
- Existing organization repositories are not republished. Clone them from their canonical remotes as listed in `existing-github/REPOSITORIES.md`.

See `RESTORE_ON_NEW_MAC.md` for the complete restore sequence and `MIGRATION_MANIFEST.md` for inclusions and exclusions.

