---
name: sync-attio-pipeline
description: Reconcile completed Cranston sales meetings, Circleback transcripts, Notion daily-planner notes, and bounded Gmail evidence into a deduplicated deal pipeline. Use for scheduled CRM sweeps, historical backfills, transcript-ready follow-ups, qualification extraction, client-fit scoring, meeting-count stage changes, and approval-gated Contracting or Won proposals. Write to the configured temporary Notion mirror until Attio writes are explicitly enabled.
metadata:
  version: 1.0.0
  author: Ross Gates
  hermes:
    tags:
      - ai-operating-system
      - sales-operations
      - explicit-only
    platforms:
      - chatgpt
      - codex
      - hermes
---

# Sync Attio Pipeline

Keep each company represented by one evidence-backed deal and retain a compact qualification history without turning the deal record into a transcript dump.

## Required references

Read these files before reconciling a deal:

- `references/POLICY.md`
- `references/source-precedence.md`
- `references/field-map.md`
- `references/stage-rules.md`
- `references/fit-rubric.md`
- `references/minimum-rules.md`
- `references/next-action-rules.md`
- `references/deal-brief-template.md`

Also read the repository's `config/sync-attio-pipeline.yaml`, `APPROVAL_POLICY.md`, and `skills/workspace-operator/SKILL.md`.

## Reconciliation workflow

1. Read the configuration. Respect `write_target`, the Attio permission flags, the five scheduled sweep times, and the webhook switch. A true webhook flag does not create or authorize a receiver.
2. Search the bounded Calendar window for completed external sales meetings. Exclude internal-only calls, personal events, recruiting, vendor calls, and meetings without a plausible prospect. Do not infer qualification merely because Ross attended.
3. Deduplicate Calendar and Circleback using the Calendar iCalUID, Circleback meeting ID, company domain, attendees, and start time. Do not count a reschedule, duplicate recording, or internal debrief as another prospect meeting.
4. Resolve the company and deal before creating anything. Prefer an existing destination record, verified business domain, company name stated in the call, and attendee email domain. Never derive a company from a personal email domain without corroboration. Ambiguous matches require confirmation.
5. Resolve the deal owner in this order: existing destination owner, call leader, then a Cranston participant on the call if the leader cannot be inferred. Preserve an existing owner unless there is explicit correction evidence.
6. Gather the complete Circleback transcript when available, the corresponding Notion Daily Planner entry, relevant Calendar metadata, and only the bounded Gmail thread needed to test contract or signature evidence. Treat AI summaries as discovery aids, not stronger evidence than the transcript.
7. Determine the verified meeting count and the current meeting type separately. Count only prospect-facing sales meetings for this company. An Output Review can be the third meeting without becoming a new stage.
8. Apply the inclusion gate before creating a destination record. If Ross explicitly labels a prospect `Bad`, says to ignore them, or identifies competitive research without real buying intent, skip CRM creation unless Ross grants a record-specific exception. Record the exclusion reason in the run report, not in Attio.
9. Extract every qualification field from the evidence. Store exact short quotes, source IDs, and timestamps when available. Use `Unknown`, `Not discussed`, `Unclear`, or `Needs confirmation` instead of guessing.
10. Calculate the stage, calculated fit, effective client fit, minimum response, decision-path blocker, and Next Action from the references. Ross's explicit post-call fit label overrides the calculated fit, but keep both values. Every open deal must end with a booked meeting, an incomplete dated Attio task, or an explicit no-follow-up fit decision.
11. Prepare a workspace-action envelope with a stable idempotency key and source evidence before every create, update, or stage proposal.
12. Search the configured destination again immediately before writing. Match companies by verified business domain, people by email, and deals by company plus canonical deal name. Never create a second record simply because the name differs slightly.
13. For Attio, preserve the existing Deal card schema except for the approved `Next Action` text attribute. Upsert the company and verified prospect speakers, create or update the deal using the mapped attributes, and attach the detailed qualification brief as a note on the Deal record with a direct Circleback meeting link. Do not attach new qualification briefs to the Company. Opportunity value equals verified annual returns multiplied by $40. Populate Competitive alternatives only with products or alternatives the prospect explicitly tried or evaluated.
14. Apply permitted automatic changes. Lead and Prove Value forward transitions may be automatic. A first-call prospect who schedules a specific follow-up demo during the call moves directly to Prove Value. Contracting, Won, Lost, any backward move, an ambiguous merge, enabling general Attio writes, and enabling a new webhook endpoint require approval.
15. Search incomplete Attio tasks linked to the Deal before creating a reminder. Update a matching task when the action or deadline changed; do not create duplicates. Assign the task to the Deal owner and store its exact date in `Next Action`.
16. Read the destination record after every write and verify identifiers, changed properties, relationships, note metadata and body, Next Action, linked task deadline and assignee, and the expected queue or stage. For Attio, require the note parent object and record ID to match the Deal receiving the qualification brief.
17. If Ross corrects a classification or rule, add a negative and positive regression case before considering the correction complete.

## Idempotency keys

Use stable, inspectable keys:

- Deal: `pipeline:deal:<verified-domain-or-approved-company-key>`
- Meeting: `pipeline:meeting:<circleback-meeting-id>`
- Stage: `pipeline:stage:<deal-key>:<before>:<after>:<evidence-id>`
- Approval: `pipeline:approval:<deal-key>:<proposed-stage>:<evidence-id>`
- Task: `pipeline:task:<deal-key>:<yyyy-mm-dd>:<normalized-action>`

## Scheduled and transcript-ready modes

Run bounded sweeps at 7:00 AM, 11:00 AM, 2:00 PM, 5:00 PM, and 7:00 PM in `America/Los_Angeles`. Each sweep should also revisit previously discovered meetings whose transcript status is Pending. Historical backfill uses the same logic in explicit date windows and records a checkpoint.

When a webhook receiver is later implemented and enabled, process a transcript-ready event immediately and let the next sweep verify that it was not missed. The sweeps remain the recovery path.

## Output and record shape

Keep filterable, frequently queried facts in database properties. Put the richer evidence-backed qualification brief in the page body using `references/deal-brief-template.md`. Keep exact quotes short and link or identify the source rather than pasting full transcripts or email threads.

Return a compact reconciliation report containing:

- meetings inspected, matched, skipped, and pending transcripts;
- deals created or updated;
- automatic stage changes;
- Next Actions and reminder tasks created, updated, completed, or left unchanged;
- approval proposals with exact evidence;
- unknown or conflicting fields;
- verification result and checkpoint.

## Guardrails

- Do not write to Attio while `attio.writes_enabled` is false unless a current action envelope and decision record grant explicit, record-specific one-off approval. A one-off pilot does not enable scheduled or bulk writes.
- Do not create a company, person, or deal for a prospect Ross explicitly labels Bad or Ignore unless he gives a record-specific exception.
- Do not add or rearrange Attio Deal attributes beyond the explicitly approved `Next Action` text attribute without a new approval.
- Do not treat a request for information, pricing curiosity, or a generic price objection as contract evidence.
- Do not mark Won from intent, verbal enthusiasm, a draft, or a sent-but-unsigned agreement.
- Do not expose full transcripts, email bodies, credentials, or unnecessary personal information in the pipeline.
- Do not overwrite higher-confidence evidence with a weaker summary or inference.
- Do not silently move a deal backward or collapse two ambiguous companies.
