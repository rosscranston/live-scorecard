# Pipeline synchronization policy

## Active destination

Read `config/sync-attio-pipeline.yaml` on every run. While `write_target` is `notion_temp`, write only to the configured `Deals-Temp` data source unless Ross grants a documented, record-specific Attio pilot. A one-off approval does not change the active destination or enable scheduled Attio writes.

## Automatic actions

At confidence 0.90 or higher, the skill may automatically:

- create or update a confidently matched `Deals-Temp` record;
- add meeting evidence and refresh qualification fields;
- set a first verified external sales meeting to Lead;
- move a deal forward to Prove Value after its second verified external sales meeting;
- keep a third Output Review in Prove Value and add a third-meeting note.

## Approval-required actions

Ask Ross in the recurring Codex task before:

- moving a deal to Contracting, Won, or Lost;
- moving any deal backward;
- merging ambiguous deal or company records;
- enabling Attio writes or changing the active write target to Attio;
- enabling a webhook endpoint that has not already been implemented and approved;
- lowering a specific prospect's customer-facing minimum without explicit evidence.

## Attio one-off pilots

A one-off pilot may run while general Attio writes remain disabled only when its action envelope and decision record identify the exact company/domain, person, deal, permitted fields, and approval source. Preserve the existing Deal card structure. Create the detailed qualification note on the Deal record, not the Company. After the pilot, mark the approval consumed and read every created record back, including the note parent object, Deal record ID, metadata, and body.

## Inclusion gate

Do not create CRM records for prospects Ross explicitly labels `Bad`, `Ignore`, or competitive research without real buying intent. This gate runs before company and person creation. A record-specific exception may override the gate for a controlled test, but the note must preserve Ross's actual assessment.

Every approval request must show the current stage, proposed stage, company, exact evidence, source, confidence, and idempotency key. Approval applies only to that proposed action unless Ross explicitly broadens it.

## Evidence safety

Use minimal excerpts and source identifiers. Never store a full transcript or full email thread in the deal. Unknowns stay unknown. Conflicts remain visible until resolved.
