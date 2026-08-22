# Screenshare privacy model

Tax Terms is a separate floating macOS window. It is designed to sit over a
browser or presentation locally while the presenter shares only the underlying
browser, app, or tab.

## Required workflow

1. In Google Meet, Zoom, Teams, or another meeting app, share one browser tab or
   one application window.
2. Do not share the entire display.
3. Keep Tax Terms as its own app window above the shared window.
4. Confirm the meeting application's self-preview before showing sensitive
   notes.
5. Press `Control-Option-0` for the opaque privacy curtain whenever needed.

The app applies `NSWindow.sharingType = .none` as a best-effort legacy hint and
can automatically curtain itself when it becomes inactive. Apple documents the
sharing value as legacy and says not to use it to hide window contents from
capture. No public macOS API can guarantee that an arbitrary app is omitted from
every third-party whole-display screenshot or recording.

Apple references:

- https://developer.apple.com/documentation/appkit/nswindow/sharingtype-swift.enum/none
- https://developer.apple.com/documentation/screencapturekit/sccontentfilter

