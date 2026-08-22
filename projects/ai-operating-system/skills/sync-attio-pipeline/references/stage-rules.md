# Stage rules

The mirrored stages are `Lead`, `Prove Value`, `Contracting`, `Won 🎉`, and `Lost`.

| Evidence | Result | Approval |
|---|---|---|
| First verified external sales meeting for a company | Lead | Automatic |
| A specific follow-up demo is scheduled during the current call | Prove Value immediately, even on the first meeting | Automatic |
| Second verified external sales meeting | Prove Value | Automatic |
| Third meeting is an Output Review | Remain Prove Value and add `3rd meeting: Output Review` evidence | Automatic |
| Prospect explicitly asks to proceed with a contract, or Cranston sends the contract | Propose Contracting | Required |
| Executed agreement or unambiguous signed-contract confirmation | Propose Won 🎉 | Required |
| Explicit disqualification or closed-lost outcome | Propose Lost | Required |
| Any backward stage movement | Propose the move | Required |

“Scheduled” requires an agreed date/time or a created Calendar event, not a vague willingness to meet again. A vague or relative follow-up request does not advance the stage; apply `next-action-rules.md` so it becomes an exact dated reminder or an explicit no-follow-up decision. The current stage is a floor unless Ross approves a backward move. Contracting evidence must be about entering the agreement process, not merely asking about pricing or legal terms. Won requires evidence of execution, not a verbal yes or an unsigned document.
