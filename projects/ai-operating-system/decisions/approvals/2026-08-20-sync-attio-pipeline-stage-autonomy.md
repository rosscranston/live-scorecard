# Approval: sync-attio-pipeline stage autonomy

- **Approved by:** Ross Gates
- **Date:** 2026-08-20
- **Scope:** `sync-attio-pipeline` only
- **Destination:** Notion `Deals-Temp` until Attio writes are separately enabled

## Approved automatic actions

- Create and update confidently matched `Deals-Temp` records at confidence 0.90 or higher.
- Set Lead after the first verified external sales meeting.
- Move Lead to Prove Value after the second verified external sales meeting.
- Keep a third Output Review in Prove Value and add a third-meeting note.

## Explicit approval still required

- Contracting, Won, Lost, or any backward movement
- ambiguous record merges
- enabling Attio writes
- enabling a newly implemented webhook endpoint

## Source

Ross's direct instructions in the Codex task on 2026-08-20.
