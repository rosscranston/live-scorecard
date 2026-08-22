# `day-operator brief` — Approved Default Acceptance Tests

## Test 1 — Normal multi-meeting day

**Given** several external sales meetings with clean Calendar, Attio, Circleback, Gmail, and Notion matches.  
**Expect:**

- One page titled `YYYY-MM-DD | AE`.
- Today's Mission appears first.
- Meetings remain chronological.
- Exactly one meeting may be marked Must Win Today when evidence supports it.
- Meeting Count equals the number of external sales meetings.
- Verified source fields are visible.
- AI preparation is collapsed.
- Each call shows no more than five visible preparation bullets and three priority questions.

## Test 2 — No external sales meetings

**Given** a workday with internal work blocks but no external sales calls.  
**Expect:**

- The page is still created.
- Meeting Count is `0`.
- Work events, Do Today, Kick Off With AI, and What Changed Overnight remain present.
- Purely personal events are omitted unless they affect the workday or have a business purpose.

## Test 3 — Material source conflict

**Given** Calendar and Circleback disagree about a decision-critical amount or next step.  
**Expect:**

- A visible Resolve Before Call warning.
- The competing sourced values are preserved.
- Supporting interpretation is collapsed.
- The system does not silently choose one source.

## Test 4 — Missing decision-critical data

**Given** a prospect's exact returns per year or primary tax software is unavailable.  
**Expect:**

- Decision-critical gaps display Needs confirmation.
- The system does not invent or round a value.
- Low-value optional blank fields are omitted.

## Test 5 — New prospect

**Given** an external sales meeting with no prior Attio/Circleback history.  
**Expect:**

- A five-line executive research summary.
- Full research is linked or collapsed.
- The brief includes likely pain points, discovery questions, objections, and a recommended next step without presenting them as verified facts.

## Test 6 — Correction learning

**Given** Ross marks a meeting-prep statement Wrong and supplies a correction.  
**Expect:**

- The failed statement is stored as a negative test example.
- The corrected statement is stored as a positive example.
- The production skill instruction is not silently changed during rollout.
- A proposed change contains before, after, evidence, reason, confidence, risk, tests, and rollback.

## Test 7 — Material pre-meeting update

**Given** the morning page was created and a new relevant prospect email arrives before the meeting.  
**Expect:**

- The meeting block is refreshed.
- The latest thread link and unanswered-email state update.
- Unrelated blocks are not needlessly rewritten.

## Test 8 — Slack readiness notification

**Given** the Notion page is created and verified.  
**Expect:**

- A concise readiness message is drafted for `ross-notebook`.
- The message is not posted without approval.

## Failure conditions

The test fails when the page looks complete but:

- Mixes inferred statements with verified data.
- Hides a material conflict.
- Invents missing facts.
- Overloads the visible call block.
- Rewrites manual notes.
- Posts to Slack without approval.
- Repeats a corrected error in a later run.
