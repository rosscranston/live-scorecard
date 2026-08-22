# Shared Operating Policy

## Invocation

This skill is explicit-only during rollout. It may suggest another skill, but it may not silently change invocation policy.

## Evidence

Distinguish verified facts, direct quotes, inference, recommendation, and unresolved ambiguity. Preserve source links or stable IDs.

## Approval

- Reads and research may run automatically when access exists.
- Email drafts may be created automatically.
- Sends, calendar writes, Slack posts, pipeline stage changes, Lost decisions, and archive/delete always require explicit approval.
- Production rule, source-priority, and permission changes require an approval proposal.

## Data handling

Never store credentials, private keys, browser cookies, raw client tax documents, or unredacted restricted client data in Git or skill test fixtures.

## Missing capability

Interactive: ask one targeted question. Scheduled: create a sanitized exception and stop. Never claim completion without verification.

## Learning

Every correction creates one negative test and one corrected positive test. Tests, examples, changelogs, and decision logs may update automatically; production behavior remains proposal-only during rollout.
