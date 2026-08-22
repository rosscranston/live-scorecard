# Remaining Open Questions

The Daily Brief defaults were approved on August 15, 2026 and are recorded in `DAILY_BRIEF_REQUIREMENTS.md`. The questions below remain outside that approval.

## 1. Superseded conversations

The proposed rule is to keep an older conversation in its original project with a `Superseded by` link to the newer approved source. It becomes an archive candidate only after the durable rule is captured elsewhere.

**Decision needed:** Approve this rule, or move superseded chats immediately into Archive once the new rule is captured?

## 2. Codex repository scope

Which model matches expected use?

### Scenario A — One operating-system repository

Codex normally opens one Git repository containing every skill, shared reference, test, adapter, and configuration file.

- Simplest versioning and sync.
- Best for cross-skill refactoring.
- Business-project code/files may live elsewhere.
- Recommended starting model.

### Scenario B — Skills installed globally across many work repositories

Skills live in a central user-level folder and are available while Codex works in many unrelated repositories.

- Best when Codex will help with sales operations, websites, product code, data scripts, and personal projects.
- Requires stronger boundaries so business context is not applied in unrelated folders.

### Scenario C — Hybrid

A canonical Git repository stores source skills. An install script syncs approved releases into user-level Codex skill folders on both computers.

- Best balance of source control and global availability.
- Requires install/update scripts and release discipline.
- Recommended architecture if Codex will span several repositories.

**Decision needed:** A, B, or C?

## 3. Initial approval batching

Recommendation:

- Approve one **daily batch**, grouped by system.
- Within the batch, keep every action separately visible with evidence.
- Allow “approve all low-risk Notion actions” only after several clean runs.
- Keep email send, Calendar writes, Slack posts, stage changes, archive/delete, and ambiguous matches individually approved.

**Decision needed:** Approve or revise?

## 4. Permanently non-autonomous actions

Recommendation to permanently require approval for:

1. Sending external email.
2. Posting externally visible Slack messages.
3. Accepting/declining invitations or changing attendee lists.
4. Moving a deal to Won or Lost.
5. Changing pricing, legal, security, integration, or roadmap claims.
6. Deleting or archiving any source record.
7. Sharing files or changing permissions.
8. Processing raw client tax documents outside approved cloud systems.
9. Resolving an ambiguous person, firm, deal, or target record.
10. Changing another person's settings, permissions, or data.

**Decision needed:** Approve, remove, or add items?

## 5. Source of truth for business claims

A coordinated source with Sean and Max is still required for:

- Product capabilities.
- Security controls.
- Supported integrations.
- Pricing.
- Roadmap/release dates.

**Decision needed:** Where should this source live, who approves changes, and what status labels should it use?

## 6. Escalation matrix

Recommended:

| Claim type | Escalate to |
|---|---|
| Current product behavior or integration | Engineering/Product |
| Security architecture, retention, encryption, compliance | Security/Engineering |
| Contract, privacy, liability, regulatory representation | Legal |
| Pricing, discount, commercial terms | Authorized sales leader |
| Tax interpretation or tax-treatment advice | CPA/tax authority |
| Roadmap or delivery date | Product owner |
| Customer-specific data handling | Security + authorized account owner |

**Decision needed:** Approve and name the actual owners.

## 7. Acceptance-test set

An acceptance-test set is not necessarily the “best three client calls.” It should contain three examples that prove a skill handles different conditions:

1. A normal successful workflow.
2. A difficult/ambiguous workflow.
3. A workflow where the prior output was corrected.

For `day-operator`, examples might be:

- A day with several cleanly matched sales meetings.
- A day with a new prospect requiring research.
- A day with conflicting Calendar/Circleback/Attio data.

**Decision needed:** Which three days/conversations should serve as the first tests?

## 8. Trial length before autonomy

Approved within the Daily Brief defaults:

- A low-risk production behavior may be proposed for autonomy after **5 consecutive reviewed runs** with no material corrections.
- Approval remains scoped to the exact skill, service, operation, and risk class.

Still unresolved:

- Should conversation move/rename require **10 consecutive high-confidence correct classifications**?
- Should semantic duplicate merges remain proposed until **10 clean cases**?
- Confirm which destructive or externally visible actions must remain permanently non-autonomous.

## 9. End-of-day report

The end-of-day knowledge updater is defined, but the human-readable report still needs requirements.

Questions:

- What should Ross review before ending the day?
- Should it emphasize call performance, pipeline movement, learned language, system changes, or tomorrow's risks?
- Should it include a rehearsal queue for the next morning?
- Should it show only exceptions and important changes, or every processed call?
- Where should the report live?

## 10. Feedback capture

The operating system must collect feedback on every important output.

**Decision needed:** Should feedback be captured primarily in Notion, in ChatGPT replies, in a local Git review file, or in all three with one source of truth?
