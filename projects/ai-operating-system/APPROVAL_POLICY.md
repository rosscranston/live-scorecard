# Approval Policy

## Initial rollout defaults

| Operation | Default |
|---|---|
| Read/search connected sources | Automatic when access exists |
| Research and reason from accessible data | Automatic |
| Draft email | Automatic |
| Add safe tests, examples, changelogs, indexes, and decision-log entries | Automatic |
| Create/update Notion records | Approval during trial; may be proposed for scoped autonomy after five clean runs |
| Create/update Attio records | Approval during trial; may be proposed for scoped autonomy after five clean runs |
| Move/rename ChatGPT conversations | Approval during trial; may be proposed for scoped autonomy after five clean runs |
| Send email | Explicit approval every time |
| Create/update Calendar event | Explicit approval every time |
| Post to Slack | Explicit approval every time |
| Change deal stage or mark Lost | Explicit approval every time |
| Archive/delete any record | Explicit approval every time |
| Change production skill behavior or approval gates | Explicit approval through a proposal |
| Write to a GitHub repository not owned by the configured primary owner | Prohibited until the primary user explicitly changes this rule |

## Scoped exception: sync-attio-pipeline

Ross approved this exception on 2026-08-20 for the `sync-attio-pipeline` skill only:

- creating and updating confidently matched records in the configured Notion `Deals-Temp` database is automatic at confidence 0.90 or higher;
- a first verified external sales meeting may automatically set Lead;
- a second verified external sales meeting may automatically move Lead to Prove Value;
- a third Output Review remains Prove Value and may add a third-meeting note automatically;
- Contracting, Won, Lost, every backward stage movement, and every ambiguous merge still require explicit approval in the recurring Codex task; and
- Attio writes remain disabled until Ross has the required permission and explicitly approves activation.

This exception does not authorize email sends, Calendar writes, Slack posts, deletions, or any other skill or destination.

## Required approval evidence

Every proposal must show:

- source quote or source excerpt;
- source link or stable record identifier;
- current value;
- proposed value;
- reason;
- confidence;
- risk class;
- duplicate/ambiguity result;
- expected verification;
- rollback method; and
- idempotency key.

## Ambiguity

No write occurs when the target or intended action is ambiguous below the configured confidence threshold. Interactive runs ask one targeted question. Scheduled runs create an exception and stop without claiming completion.

## Trial-to-autonomy rule

After five consecutive reviewed runs with no material correction, the system may propose autonomy for one exact tuple:

```text
skill + service + operation + target class + risk class
```

Approval for one tuple does not extend to another. For example, autonomous creation of new verified Terms cards does not authorize autonomous edits to pricing FAQs.
