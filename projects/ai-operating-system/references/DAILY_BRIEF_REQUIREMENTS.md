# Daily Brief Requirements — Approved Baseline v0.3.0

**Approval date:** August 15, 2026  
**Approved by:** Ross Gates  
**Status:** All previously recommended Daily Brief defaults are approved requirements.

## Purpose

The Daily Brief is the morning interface that helps the AE know what to do, ask, and say before and during the day's work. It is not a passive record.

## Cadence and destination

- Run `day-operator brief` at 6:00 AM America/Los_Angeles.
- Finish no later than 8:00 AM.
- Create one new page per AE and date in the Notion Daily Call Logs database.
- Title the page `YYYY-MM-DD | AE`.
- Create the page even when no external sales calls are scheduled.
- Scan every Calendar event; perform deep preparation only for external or sales-related meetings.
- Count external sales meetings only in the `Meeting Count` property.

## Source ownership

- Attio is the long-term source of truth for deal and customer history.
- Circleback is the exhaustive source of truth for meeting recordings, transcripts, and notes.
- Notion Projects is the source of truth for internal work.
- Daily Call Logs is the AE's working cockpit.
- Gmail is supporting communication context, not the canonical deal record.
- The nightly `work-auditor daily` handoff is supporting AI context, not source data.

## Presentation boundary

- Keep verified source data visible.
- Put generated, inferred, summarized, researched, or historically mined content inside a collapsed `⚠️ AI` section unless this document explicitly approves a visible exception.
- Preserve the AE's manual notes without rewriting them during the call.
- Preserve exact numbers; never round returns per year.
- Show only information that could change what Ross does, asks, or says. Keep deeper context collapsed.

## Approved page order

1. Today's Mission.
2. Today's schedule.
3. Per-meeting visible source data and manual notes.
4. Collapsed AI preparation for each meeting.
5. Do Today.
6. Kick Off With AI.
7. What Changed Overnight.
8. Feedback controls.

## A. Page-level priorities

1. Open with a one-sentence **Today's Mission** based on the day's highest-value outcome.
2. Keep meetings chronological.
3. Mark one **Must Win Today** when stage, deal value, urgency, and evidence support it.
4. Show all work events.
5. Omit purely personal events unless they affect the workday or have a business purpose.
6. On a no-call day, still include Do Today, Kick Off With AI, relevant work blocks, and overnight learning.

## B. Visible meeting data

For each external sales meeting, keep these sourced fields visible when available:

- Time.
- Call number.
- Meeting type.
- Contact.
- Firm.
- Primary tax software.
- Exact returns per year.
- Attio stage.
- Deal value.
- Latest Circleback link.
- Manual notes.
- Current sourced next step.
- Open commitments by Ross and the prospect, with owner and due date when known.
- Latest relevant Gmail thread link.
- Whether an unanswered prospect email exists.

Keep the detailed email summary collapsed.

### Missing data

- Show **Needs confirmation** for decision-critical missing fields.
- Omit low-value optional fields rather than cluttering the page.

### Conflicting sources

- Show a visible **Resolve Before Call** warning when Calendar, Attio, Circleback, Gmail, or Notion materially conflict.
- Keep the supporting analysis inside the collapsed AI section.

## C. In-the-moment preparation

1. Add an AI-generated **Win Condition** describing the exact advancement or next step the call should secure.
2. Keep the Win Condition collapsed during rollout because it is inferred.
3. A separate approval is required before the Win Condition may become visible by default.
4. Copy the short meeting-stage checklist inline and link to the full master playbook.
5. For an existing prospect, consider:
   - Last-call summary.
   - Unresolved objections.
   - Decision criteria.
   - Stakeholders.
   - Promised follow-ups.
   - Likely blockers.
   - Recommended questions.
6. Show the five most actionable preparation bullets initially; keep deeper context collapsed.
7. For a new prospect, show a five-line executive summary and link to or collapse the full research.
8. Add **What to Say** with one to three approved phrases or direct quotes to rehearse.
9. Add **Avoid Saying** warnings for unsupported product, integration, pricing, security, roadmap, legal, or tax claims.
10. Limit visible preparation to five bullets and three priority questions per call unless a critical exception requires more.

## D. Overnight “dream” output

Place **What Changed Overnight** near the bottom of the same Daily Call Log page so call preparation remains first.

Show any of these that occurred:

- Newly discovered workflow.
- Skill created or proposed.
- Skill rule changed.
- Conversation moved or renamed.
- Duplicate resolved.
- Correction learned.
- Unresolved exception.
- One item Ross should rehearse.

During rollout, the nightly audit may automatically update:

- Tests.
- Positive and negative examples.
- Changelogs.
- Decision logs.
- Indexes and tables of contents.
- Non-behavioral metadata.

During rollout, the nightly audit must only propose changes to:

- Production instructions.
- Approval gates.
- Business claims.
- Source priority.
- Autonomous-write permissions.

A low-risk production behavior may be proposed for autonomy after **five consecutive reviewed runs with no material correction**. Approval remains scoped to the exact skill, service, operation, and risk class.

Every proposed production change must include:

- Previous rule.
- Proposed rule.
- Supporting evidence.
- Reason.
- Confidence.
- Risk.
- Affected skills and files.
- Test cases.
- Rollback method.

## E. Refresh, notification, and feedback

1. Build the page at 6:00 AM.
2. Refresh before a meeting only when Calendar, Attio, Gmail, Circleback, Notion, or the nightly handoff has changed materially.
3. Draft a short readiness notification for `ross-notebook` after the Notion page is created and verified.
4. Posting the Slack message remains approval-required.
5. Capture **Useful / Wrong / Missing** feedback plus a free-text correction for the overall brief and each important meeting-prep block.
6. Turn every correction into:
   - A negative test example showing what not to do.
   - A corrected positive example showing the expected behavior.

## Existing new-conversation research fields

- Person and title.
- Company and what it does.
- Company size.
- Industry.
- Likely accounting/tax complexity.
- Recent developments.
- Likely relevance.
- Likely pain points.
- Discovery questions.
- Likely objections.
- Recommended next step.

## Implementation boundary

1. `work-auditor daily` produces a structured `morning-handoff` from the previous 24 hours.
2. `day-operator brief` combines current source data and the handoff into the Notion page.
3. Business skills emit service-neutral action proposals.
4. `workspace-operator` performs approved service-specific actions and verifies them.
5. The connector layer must not reinterpret business intent.

## Acceptance rule

An implementation does not pass merely because it creates a complete-looking page. It passes only when:

- Source data is correctly separated from AI interpretation.
- The page is usable at a glance.
- Conflicts and missing decision-critical information are obvious.
- The preparation materially helps Ross act better in the moment.
- User corrections are captured as tests and are not repeated in later runs.
