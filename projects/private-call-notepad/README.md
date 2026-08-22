# Private Call Notepad

A lightweight native macOS notepad styled after Cranston Live Scorecard. It has
no transcription, microphone, calendar, AI, or database code; network activity
is limited to the configured Git notes sync.

## Features

- Dense black terminal interface with Cranston green and admin blue accents.
- Custom document-and-shield app icon for Finder, the Dock, and app switching.
- Compact one-line header with a green saved dot and yellow unsaved dot.
- Local autosave into one timestamped Markdown document per day.
- Clean editor text with timestamps hidden from the notepad interface.
- A stored `[HH:MM:SS]` entry after each line break or 10 seconds of inactivity.
- Whole-window transparency from 0% to 75%.
- Always-on-top behavior across macOS Spaces and full-screen apps.
- Persistent window size and location across launches.
- Nine global snap shortcuts: `Control-Option-1` through
  `Control-Option-9`, arranged like a numeric keypad.
- Separate admin dashboard for display and position controls.
- Automatic notes-only Git commit and push every 30 minutes while the app is open.
- Best-effort legacy capture opt-out hint.

## Build

```sh
swift test
./scripts/build-app.sh
open ".build/Private Call Notepad.app"
```

The built app is `.build/Private Call Notepad.app`.

Notes are autosaved to one daily file under:

```text
/Users/rossegates/Documents/ChatGPT/ai-os-cranston/private-notes/notes/YYYY-MM-DD.md
```

The Git remote is `git@github-work:rosscranston/private-notes.git`. The
`github-work` host alias selects the SSH identity authenticated as
`rosscranston`; it points to the same GitHub repository as the standard
`git@github.com:rosscranston/private-notes.git` URL.

## Screensharing requirement

Share one browser/app window or one browser tab. Do not share the entire display.
Apple no longer supports `NSWindow.sharingType.none` as a guaranteed capture
exclusion mechanism, so no native app can promise invisibility to every
third-party full-display capture tool. See `Documentation/PRIVACY.md`.
