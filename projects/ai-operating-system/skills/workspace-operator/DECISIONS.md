# Decision Log — workspace-operator

## 2026-08-20 — Scoped deal-pipeline autonomy

- **Decision:** Permit `sync-attio-pipeline` to update the Notion `Deals-Temp` mirror and make verified forward Lead and Prove Value transitions automatically.
- **Boundary:** Contracting, Won, Lost, backward changes, ambiguous merges, Attio activation, and new webhook activation require explicit approval.
- **Reason:** Ross directly approved automatic early-stage changes while retaining review for consequential outcomes.

## 2026-08-15 — Initial boundary

- **Decision:** Compartmentalize connector-specific reads and writes so business judgment is portable and service permissions are controlled centrally.
- **Invocation:** Explicit only.
- **Production changes:** Proposal and approval required.
- **Feedback:** Every correction creates negative and positive tests.
