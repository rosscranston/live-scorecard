# Screenshare privacy model

Private Call Notepad is a separate floating macOS window. It is designed to sit
over a browser or presentation locally while the presenter shares only the
underlying browser or app window.

## Required workflow

1. In Google Meet, Zoom, Teams, or another meeting app, choose a single browser,
   app, or tab as the shared source.
2. Do not choose an entire screen or display.
3. Keep the notepad as a separate app window over the shared window.
4. Confirm the meeting app's self-preview before discussing sensitive material.

## Defense in depth

The app also applies `NSWindow.sharingType = .none`. Apple currently documents
that value as a legacy constant and says not to use it to hide or omit content
from capture. It is therefore only a best-effort compatibility hint, not the
privacy boundary.

No public macOS API lets one arbitrary app guarantee that every third-party
full-display capture tool will omit its pixels. If the entire display is shared,
the notepad may be visible.

Apple references:

- https://developer.apple.com/documentation/appkit/nswindow/sharingtype-swift.enum/none
- https://developer.apple.com/documentation/screencapturekit/sccontentfilter

