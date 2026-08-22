# Restore on the M5 MacBook Pro

## 1. Install and initialize

1. Install Git, the GitHub CLI, Xcode Command Line Tools, and Codex.
2. Sign in to GitHub and Codex on the new Mac.
3. Open Codex once so it creates `~/.codex`, then quit Codex completely.
4. Create a new SSH key for the M5 Mac. Do not copy the Hermes private SSH key.

## 2. Clone the migration repository

```bash
mkdir -p "$HOME/AI"
cd "$HOME/AI"
git clone git@github.com:rosscranston/codex-migration.git
cd codex-migration
```

If you choose a different repository name, use that clone URL instead.

## 3. Restore portable Codex files

Run the restore helper while Codex is closed:

```bash
./scripts/restore-on-new-mac.sh
```

The script:

- decrypts the private history with the passphrase you saved;
- backs up the new Mac's current portable Codex files;
- restores personal skills, rules, memories, task JSONL files, and automation files;
- merges the portable task index when `jq` is available; and
- does not copy credentials, live databases, caches, or machine-specific connector state.

The backup location is printed by the script.

## 4. Apply settings deliberately

Review `codex-portable/config/config-reference.toml`. Merge the settings you want into the new Mac's `~/.codex/config.toml`; do not replace the whole new file. Connector configuration and paths are machine-specific, and all accounts must be reauthenticated.

## 5. Restore projects

The source snapshots under `projects/` are usable transfer copies. For projects with canonical GitHub repositories, clone the canonical repositories using `existing-github/REPOSITORIES.md`, then compare any newer snapshot changes before replacing files.

Build the native apps from source:

```bash
cd projects/live-call-scorecard && ./scripts/build-app.sh
cd ../private-call-notepad && ./scripts/build-app.sh
cd ../tax-terms && ./scripts/build-app.sh
```

The prebuilt Apple-silicon apps are also under `products/macos-apps/`. They are not notarized for general distribution; Live Scorecard and Tax Terms retain the Hermes machine's local developer signature. Rebuilding from source on the M5 Mac is the most reliable option. macOS may require approval in Privacy & Security.

## 6. Reconnect scheduled tasks

Open Codex and inspect Automations. For every task in `codex-portable/automations/`:

1. confirm its active or paused status;
2. point it at the correct project folder on the M5 Mac;
3. reconnect required apps such as Gmail, Calendar, Circleback, and Notion;
4. preserve the original schedule and timezone; and
5. run one manual test and verify the result before relying on the schedule.

The two growth-target tasks depend on the separate `head-of-growth-series-a-or-b` repository. The Circleback cleanup task depends on the Cranston Sales project folder. The Daily Sales Coach also requires working Circleback and Notion connections.

## 7. Verify

```bash
./scripts/verify.sh
```

Then open each app/product, run the relevant project tests, and confirm the three active scheduled tasks appear with the correct times.
