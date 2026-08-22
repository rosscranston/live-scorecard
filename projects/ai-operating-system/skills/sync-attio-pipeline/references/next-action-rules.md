# Next Action rules

Keep `Next Action` short and operational. For every open Deal in Lead, Prove Value, or Contracting, require exactly one of these states:

1. A specific next meeting is booked. Set `Next Action` to `<meeting type> on YYYY-MM-DD`. Do not create a redundant follow-up task.
2. No meeting is booked, but the prospect remains viable. Set `Next Action` to `<action> — due YYYY-MM-DD` and create or update one incomplete Attio task linked to the Deal, assigned to the Deal owner.
3. Ross explicitly labels the prospect Bad or Ignore. Set `Next Action` to `No follow-up — Bad fit` and create no task. If an open Deal already exists, a move to Lost still requires approval.

## Resolve dates

Use the completed meeting timestamp as the base for relative language. Interpret dates in the Deal owner's timezone, defaulting to `America/Los_Angeles`:

- `tomorrow`: add one calendar day.
- `in N days`: add N calendar days.
- `in N weeks`: add 7 × N calendar days.
- `a couple weeks` or `a couple of weeks`: add 14 calendar days.
- `a few weeks`: add 21 calendar days.
- `next week`: use the next Monday.
- `in N months`: add N calendar months and clamp to the last valid day.
- `next month`: use the same day in the next month and clamp to the last valid day.

If the resolved date is Saturday or Sunday, move it to the next Monday. Set the Attio deadline to 9:00 AM in the Deal owner's timezone. Preserve the prospect's exact phrase in the Deal note.

If a viable prospect gives no date or timeframe and no meeting is booked, create a seven-calendar-day follow-up and mark its date as an operating default, not a prospect commitment. Do not use this default for a Bad or Ignore prospect.

## Task behavior

- Use task content `Follow up with <primary contact> to <specific outcome>`.
- Before creating a task, search incomplete tasks linked to the Deal.
- Treat the same linked Deal plus normalized action as the same task. Update its deadline rather than creating another task.
- When the meeting is booked or the follow-up is completed, mark the prior task complete only with verified evidence.
- Verify the task ID, linked Deal, assignee, deadline, completion state, and corresponding `Next Action` value after every write.
