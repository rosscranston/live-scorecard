# Migration manifest

Inventory cutoff: **2026-08-11 00:00 America/Los_Angeles through 2026-08-22**.

## Programs and source included

| Item | Location | Notes |
|---|---|---|
| Live Call Scorecard | `projects/live-call-scorecard/` | Swift source, resources, tests, and build scripts; `.build` excluded. |
| Private Call Notepad | `projects/private-call-notepad/` | Swift source, resources, tests, and build scripts; `.build` excluded. |
| Tax Terms | `projects/tax-terms/` | Recovered from `/private/tmp/tax-terms`; Swift source, resources, tests, and build scripts. |
| AI Operating System | `projects/ai-operating-system/` | Source snapshot including the current uncommitted `sync-attio-pipeline` changes; local caches and `.git` excluded. |
| Private Notes | `projects/private-notes/` | Clean source snapshot; `.git` excluded. |
| Webinar signup tool | `products/standalone-web/cranston-webinar-signup.html` | Standalone HTML product. |
| Sales demo practice tool | `products/standalone-web/sales-demo-practice.html` | Standalone HTML product. |
| DreamBig model and board deck | `products/dreambig/` | Final workbook, deck, source scripts, and selected previews; inspection dumps and Office lock files excluded. |
| Synthetic tax demo set | `products/synthetic-demo-tax-documents/` | Explicitly synthetic documents plus their generator scripts. |
| Sales enablement products | `products/sales-enablement/` | Generic guides and research; prospect-specific quote banks and call evaluations excluded. |
| Built Mac apps | `products/macos-apps/` | Apple-silicon `.app` bundles for all three Swift apps. |

## Codex state included

- Five scheduled-task definitions: three active and two paused at inventory time.
- Personal skills under `~/.codex/skills`, excluding reinstallable `.system` skills.
- `default.rules`, empty global `AGENTS.md`, and a sanitized settings reference.
- Active task JSONL files from August 12 through August 22 and archived task JSONL files from August 11 through August 22.
- Task-index entries updated on or after August 11.
- Codex memories and automation run memories.

Raw task history, memories, and automation memory are under `private-state-plaintext/`, ignored by Git, until `scripts/encrypt-private-state.sh` produces the encrypted archive.

## Scheduled tasks inventoried

| Status | Task | Schedule | Original dependency |
|---|---|---|---|
| Active | Daily brief | Weekdays 8:00 AM | Projectless; Gmail and Calendar connections. |
| Active | Daily Circleback external-call sharing and access cleanup | Daily 5:00 PM | `/Users/rossegates/Documents/ChatGPT/Cranston Sales`; Circleback and signed-in browser. |
| Active | Daily Sales Coach | Daily 5:30 PM | Circleback and Notion connections. |
| Paused | Weekday Bay Area growth-target refresh | Weekdays 7:00 AM | `/Users/rossegates/career/head-of-growth-series-a-or-b`. |
| Paused | Weekly growth-target data-gap sweep | Friday 2:00 PM | `/Users/rossegates/career/head-of-growth-series-a-or-b`. |

All times are from the original local configuration. Verify `America/Los_Angeles` on the new Mac.

## Deliberately excluded

- `~/.codex/auth.json`, installation ID, global state, credentials, browser/chrome native state, connector tokens, cookies, and SSH private keys.
- `state_5.sqlite`, `logs_2.sqlite`, `memories_1.sqlite`, `goals_1.sqlite`, `queue_1.sqlite`, and every WAL/SHM file.
- Codex logs, plugin caches, computer-use recordings/state, models cache, locks, IPC, and rebuildable system skills.
- Swift `.build` directories, Python/Node dependency directories, caches, and scratch directories.
- The client-specific Live Scorecard evaluation and prospect-specific exact-quote banks.
- The 1.4 GB Finance Dashboard checkout, which predates the August 11 cutoff and contains local data/dependencies. Its modified source remains at `/Users/rossegates/Finance/finance-dashboard-codex` on Hermes and should be migrated as its own reviewed private repository if desired.
- `CranstonAI/cranston-growth` source and the growth-target repository source. They have canonical remotes outside the configured `rosscranston` write boundary and are listed as clone dependencies instead.

