# Destination field map

`Deals-Temp` mirrors the Attio deal pipeline plus the qualification fields the skill will later write or derive.

## Pipeline identity

- Deal Name
- Stage
- Deal Owner
- Deal Value
- Associated Company
- Associated People
- Domain
- Primary Contact
- Sample Data Received
- Attio Deal ID
- Attio Sync Status

## Qualification and action

- Annual Return Volume
- Primary Tax Software
- Client Fit
- Calculated Fit
- Ross Fit Override
- Fit Rationale
- Verified Meeting Count
- Current Meeting Type
- Next Action
- Next Action Date
- Decision Path Blocker
- Qualification Brief

## Minimum and evidence controls

- Company Minimum
- Minimum Communicated
- Minimum Response
- Minimum Response Evidence
- Latest Circleback ID
- Latest Circleback Source
- Transcript Status
- Evidence Status
- Approval Status
- Contract Evidence
- Signed Evidence
- Last Meeting
- Last CRM Sync

## Page-body brief

Keep lower-frequency and narrative detail in the page body:

- Ross ownership answer and evidence;
- firm size, team structure, and entity mix;
- exact annual volume and return mix;
- who prepares and who reviews;
- current tax software and other software;
- workflow, bottleneck, staffing, and capacity constraints;
- AI or competing tools evaluated;
- decision maker and stakeholders;
- timeline, urgency, next step, and what the customer must understand;
- decision-path concerns and fit rationale;
- exact minimum statement and reaction;
- compact chronological meeting evidence;
- relevant rep coaching notes.

## Attio mapping

Use the existing Deal card fields plus the one approved action field:

- Deal name
- Deal stage
- Deal owner
- Deal value, calculated as verified annual returns multiplied by $40
- Associated people, limited to verified external prospect speakers or attendees from that company
- Associated company
- Sample data received
- Competitive alternatives, limited to alternatives explicitly tried or evaluated
- Next Action, a text attribute with API slug `next_action` and stable attribute ID `e03c02f5-a503-4f1c-afa9-383227a72e21`

Upsert Companies by verified business domain and People by email. Put all remaining qualification fields in a dated note attached to the Deal record, with the Circleback ID and direct meeting link. Do not attach new qualification briefs to the Company record. If a named competitor is not an existing select option, choose `Other` and preserve its exact name in the Deal note. Store reminder deadlines in native Attio tasks linked to the Deal; `Next Action` remains the compact readable summary.

Attio mapping must use stable attribute IDs. Do not assume names alone are sufficient for production writes.
