# Architecture

## Live path

```text
Google Meet in Chrome ── ScreenCaptureKit .audio ──┐
                                                   ├─ SpeechChannel
Mac microphone ─────── ScreenCaptureKit .microphone┘       │
                                                           ▼
                                         partial + finalized transcript ──► Words UI
                                                           │
                                                           │ finalized only
                              ┌────────────────────────────┴─────────────────────┐
                              ▼                                                  ▼
                  SQLite transcript_segments                    last 12 + speaker channel
                                                                                 │
                                               ┌─────────────────────────────────┴───────────────┐
                                               ▼                                                 ▼
                                 Foundation Models extractor                         deterministic fallback
                                               └─────────────────────────┬───────────────────────┘
                                                                         ▼
                                                       quote-substring evidence validation
                                                                         ▼
                                              reducer, correction, calculation, timezone
                                                           │                         │
                                                           ▼                         ▼
                                                   SwiftUI scorecard              SQLite facts
```

System audio and microphone audio remain separate. This gives reliable `ROSS` and `PROSPECT` channel labels without attempting live voice diarization.

The full finalized transcript remains in meeting state for the Words view and in SQLite for local evidence. Only the rolling 12-segment window is sent to extraction. Volatile partials are kept separately by audio channel, shown immediately in the UI, and replaced when that channel produces a final segment.

Every model-produced quote must appear in the supplied transcript window after whitespace and case normalization. A generated fact with an unsupported quote is discarded.

## State rules

- The scorecard uses one current row per field and meeting.
- A later accepted statement replaces the current row.
- Directly stated totals outrank calculated totals.
- Calculated total returns require both personal and business values.
- Manual edits outrank automation at the moment they are made, but a later spoken correction can update the row.
- Prior values are copied into the new meeting as blue `prior` facts and remain until changed.
- Transcript segments remain as local evidence even though old fact values are not retained as a separate visible history.

## Post-call path

```text
Circleback completed webhook JSON ── manual file import ── finalized extraction

End Meeting ── SyncEnvelope ── SQLite sync_outbox
                                    status: awaiting_configuration
                                    destination: notion
```

The local application is not exposed as a public webhook server. Circleback signature verification and a secured public receiver belong in the later server-side bridge.

Notion writes remain blocked until the exact AI OS database, schema, credentials, verification read, and duplicate policy are configured.
