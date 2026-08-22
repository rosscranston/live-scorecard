# Decisions

## 2026-08-20

- Use the existing AI Operating System repository.
- Use `Deals-Temp` in the Cranston Sales Operating System as the write target until Attio admin permission is available.
- Run scheduled sweeps at 7:00 AM, 11:00 AM, 2:00 PM, 5:00 PM, and 7:00 PM Pacific time.
- Keep a disabled webhook switch for a later transcript-ready receiver.
- Allow automatic forward stage changes only to Lead and Prove Value.
- Require approval for Contracting, Won, Lost, backward moves, ambiguous merges, Attio activation, and new webhook activation.
- Resolve owner as existing destination owner, then call leader, then a Cranston participant when the leader cannot be inferred.
- Preserve both calculated fit and Ross's explicit post-call override.
- Use 250 as the company minimum and only 100, 150, 200, or 250 as an explicitly communicated prospect minimum.
- Record whether the prospect thought the minimum was reasonable or too high, without confusing price sensitivity with a minimum objection.
- Move directly to Prove Value when a specific follow-up demo is scheduled during the current call.
- Skip CRM creation when Ross explicitly labels a prospect Bad, Ignore, or competitive research without buying intent.
- The Josh EF&S pilot originally used a mistaken Bad override. Ross corrected Josh to Good on 2026-08-20; the later explicit correction supersedes the earlier label while the original audit remains historical evidence.
- Permit the 2026-08-20 historical Attio backfill for completed, qualified Ross-led conversations only. Future discovery invites, no-shows, reschedules, teammate-owned deals, and explicit Bad or Ignore prospects remain excluded.
- Superseded: the initial pilot put the detailed qualification brief and Circleback link in a Company note.
- Preserve the current Attio Deal card structure; attach every new detailed qualification brief and Circleback link as a note on the Deal record. Existing historical Company notes are not moved automatically.
- Calculate Deal value as verified annual return volume multiplied by $40.
- Use one Deal-level `Next Action` text attribute for the readable step and a native Attio task for the actual due date and reminder.
- Require every open Deal to have a booked meeting, a dated owner-assigned follow-up task, or an explicit `No follow-up — Bad fit` decision.
- Interpret `a couple weeks` as 14 calendar days from the completed meeting, moving weekend dates to Monday and setting task deadlines at 9:00 AM in the Deal owner's timezone.
