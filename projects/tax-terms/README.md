# Tax Terms

A compact native macOS flashcard application for learning the tax industry. It
syncs the existing Notion Terms database in both directions while keeping local
review history and spaced-repetition timing private on the Mac.

## What it includes

- 177 Notion terms with synchronized definitions, examples, priorities,
  categories, status, resources, and freeform study notes.
- Editable card backs with per-field visibility controls in Admin.
- Any/all tag filters, priority and study-status filters, due-card filtering,
  and full-text search.
- Smart filter-driven lists and hand-picked manual lists, each with a dense
  all-terms overview and instant quiz launch.
- `Again`, `Review`, and `Memorized` spaced-repetition actions with keyboard
  shortcuts and persistent progress.
- A complete 177-term curated resource catalog emphasizing IRS/vendor primary
  sources and timestamped video explanations where video is faster.
- Dense Private Call Notepad-inspired light and dark themes.
- Default top-right placement at 25% of screen width × 40% of screen height,
  always-on-top control, transparency, nine snap positions, and a privacy
  curtain.
- AES-256-GCM encrypted local storage. Encryption key and Notion token are kept
  in the macOS Keychain.

## Build and run

Requires macOS 14 or later and Xcode command-line tools.

```sh
swift test
./scripts/build-app.sh
open ".build/Tax Terms.app"
```

The packaged application is `.build/Tax Terms.app`. To preview without a Notion
token, run the debug binary with `TAX_TERMS_DEMO=1`.

## First launch

Read [Documentation/NOTION_SETUP.md](Documentation/NOTION_SETUP.md), then open
Admin with `Command-,`, paste the internal-integration token, and select
**Save + Test + Sync**. The initial resource-seeding sync can take about a minute
because writes are deliberately paced under Notion's API limit.

## Main shortcuts

| Shortcut | Action |
|---|---|
| `Command-1 / 2 / 3 / ,` | Home / Quiz / Lists / Admin |
| `Space` | Reveal current card |
| `1 / 2 / 3` | Again / Review / Memorized |
| `Left / Right` | Previous / next card |
| `Command-S` | Sync now |
| `Control-Option-1…9` | Snap window like a numeric keypad |
| `Control-Option-0` | Toggle privacy curtain |

## Privacy boundary

Screenshot exclusion is best effort, not a guarantee. Share a single browser
tab or app window instead of the whole display and verify the meeting preview.
See [Documentation/PRIVACY.md](Documentation/PRIVACY.md).
