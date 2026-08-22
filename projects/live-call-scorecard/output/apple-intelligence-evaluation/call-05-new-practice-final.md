# Avery and Jordan - new practice versus prior employer

- Fixture: `call-05-new-practice`
- Basis: Synthetic call closely based on the new-practice versus Deloitte ambiguity in the stored Circleback replay, with clean speaker labels and explicit firm facts.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 15/15
- First-pick accuracy: 15/15
- On-time first-pick accuracy: 15/15
- Wrong scorecard writes: 0
- Wrong extractor proposals: 0

## Transcript

1. **ROSS:** I have Avery Kim and Jordan Lee on the call. What are you calling the new practice?
2. **PROSPECT:** I'm Avery Kim, my partner is Jordan Lee, and our new firm is Harbor Ledger CPAs.
3. **ROSS:** Where is Harbor Ledger based?
4. **PROSPECT:** We're based in Riverside, California.
5. **PROSPECT:** At Deloitte we each worked on around 250 returns, but those are not Harbor Ledger clients.
6. **ROSS:** How many returns will Harbor Ledger itself file in the first year?
7. **PROSPECT:** Harbor Ledger expects 75 total returns: 60 personal returns and 15 business returns.
8. **ROSS:** Our demo connects to Drake, CCH Axcess, and UltraTax. Which tax software will Harbor Ledger actually use?
9. **PROSPECT:** We use Drake desktop. Canopy is practice management, and QuickBooks Online plus GruntWorx are our supporting tools.
10. **ROSS:** How many admins, preparers, reviewers, and CPAs will the new firm have?
11. **PROSPECT:** We have 0 admins, 0 preparers, 2 reviewers, and 2 CPAs.
12. **ROSS:** Let me share my screen. The platform is three steps and this sample return has 20 documents.

## Gold versus final scorecard

| Field | Gold | Apple final | First saved | First turn | Eligible turn | Result |
|---|---|---|---|---:|---:|---|
| NAME | Avery Kim | Avery Kim | Avery Kim | 2 | 2 | PASS |
| FIRM | Harbor Ledger CPAs | Harbor Ledger CPAs | Harbor Ledger CPAs | 2 | 2 | PASS |
| LOCATION | Riverside, California | Riverside, California | Riverside, California | 4 | 4 | PASS |
| TIMEZONE | America/Los_Angeles | America/Los_Angeles | America/Los_Angeles | 4 | 4 | PASS |
| TOTAL RETURNS | 75 | 75 | 75 | 7 | 7 | PASS |
| PERSONAL | 60 | 60 | 60 | 7 | 7 | PASS |
| BUSINESS | 15 | 15 | 15 | 7 | 7 | PASS |
| TAX SOFTWARE | Drake | Drake | Drake | 9 | 9 | PASS |
| ENVIRONMENT | Desktop | Desktop | Desktop | 9 | 9 | PASS |
| PRACTICE MGMT | Canopy | Canopy | Canopy | 9 | 9 | PASS |
| SUPPORTING | QuickBooks Online, GruntWorx | QuickBooks Online, GruntWorx | QuickBooks Online, GruntWorx | 9 | 9 | PASS |
| ADMINS | 0 | 0 | 0 | 11 | 11 | PASS |
| PREPARERS | 0 | 0 | 0 | 11 | 11 | PASS |
| REVIEWERS | 2 | 2 | 2 | 11 | 11 | PASS |
| CPAS | 2 | 2 | 2 | 11 | 11 | PASS |

## Scorecard mutation history

- Turn 2 / NAME: `blank` -> `Avery Kim` / correct / "I'm Avery Kim, my partner is Jordan Lee, and our new firm is Harbor Ledger CPAs."
- Turn 2 / FIRM: `blank` -> `Harbor Ledger CPAs` / correct / "I'm Avery Kim, my partner is Jordan Lee, and our new firm is Harbor Ledger CPAs."
- Turn 4 / LOCATION: `blank` -> `Riverside, California` / correct / "We're based in Riverside, California."
- Turn 4 / TIMEZONE: `blank` -> `America/Los_Angeles` / correct / "We're based in Riverside, California."
- Turn 7 / TOTAL RETURNS: `blank` -> `75` / correct / "Harbor Ledger expects 75 total returns: 60 personal returns and 15 business returns."
- Turn 7 / PERSONAL: `blank` -> `60` / correct / "Harbor Ledger expects 75 total returns: 60 personal returns and 15 business returns."
- Turn 7 / BUSINESS: `blank` -> `15` / correct / "Harbor Ledger expects 75 total returns: 60 personal returns and 15 business returns."
- Turn 9 / TAX SOFTWARE: `blank` -> `Drake` / correct / "We use Drake desktop. Canopy is practice management, and QuickBooks Online plus GruntWorx are our supporting tools."
- Turn 9 / ENVIRONMENT: `blank` -> `Desktop` / correct / "We use Drake desktop. Canopy is practice management, and QuickBooks Online plus GruntWorx are our supporting tools."
- Turn 9 / PRACTICE MGMT: `blank` -> `Canopy` / correct / "We use Drake desktop. Canopy is practice management, and QuickBooks Online plus GruntWorx are our supporting tools."
- Turn 9 / SUPPORTING: `blank` -> `QuickBooks Online, GruntWorx` / correct / "We use Drake desktop. Canopy is practice management, and QuickBooks Online plus GruntWorx are our supporting tools."
- Turn 11 / ADMINS: `blank` -> `0` / correct / "We have 0 admins, 0 preparers, 2 reviewers, and 2 CPAs."
- Turn 11 / PREPARERS: `blank` -> `0` / correct / "We have 0 admins, 0 preparers, 2 reviewers, and 2 CPAs."
- Turn 11 / REVIEWERS: `blank` -> `2` / correct / "We have 0 admins, 0 preparers, 2 reviewers, and 2 CPAs."
- Turn 11 / CPAS: `blank` -> `2` / correct / "We have 0 admins, 0 preparers, 2 reviewers, and 2 CPAs."

## Wrong extractor proposals

None.

## Diagnostic totals

- Model or pattern proposals returned: 36
- Scorecard mutations: 15
- Rejected trace decisions: 66
- Wrong final fields: none
- Missing final fields: none
- Unexpected final fields: none
