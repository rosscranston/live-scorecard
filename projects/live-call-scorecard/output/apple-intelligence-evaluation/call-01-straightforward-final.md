# Maya Chen - straightforward established firm

- Fixture: `call-01-straightforward`
- Basis: Synthetic discovery call modeled on the structure and terminology of the locally stored Circleback demo replay.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 19/19
- First-pick accuracy: 19/19
- On-time first-pick accuracy: 19/19
- Wrong scorecard writes: 0
- Wrong extractor proposals: 0

## Transcript

1. **ROSS:** Before we jump in, what name should I put on my notes, and what is the name of your firm?
2. **PROSPECT:** I'm Maya Chen, and the firm is Chen Tax & Advisory.
3. **ROSS:** Where are you calling in from today?
4. **PROSPECT:** We're based in Austin, Texas.
5. **ROSS:** How many total returns do you file in a year, and how does that split between personal and business returns?
6. **PROSPECT:** We file 1,240 total returns: 980 personal returns and 260 business returns.
7. **ROSS:** What do you use for tax software, and is it desktop, cloud, or hosted?
8. **PROSPECT:** We use UltraTax on desktop, hosted by Rightworks.
9. **ROSS:** What do you use for a client portal, practice management, and other supporting software?
10. **PROSPECT:** SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx.
11. **ROSS:** How many admins, preparers, reviewers, and CPAs are on the team?
12. **PROSPECT:** We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs.
13. **ROSS:** For the trial, our minimum commitment is 100 returns, and the price is $40 per return.

## Gold versus final scorecard

| Field | Gold | Apple final | First saved | First turn | Eligible turn | Result |
|---|---|---|---|---:|---:|---|
| NAME | Maya Chen | Maya Chen | Maya Chen | 2 | 2 | PASS |
| FIRM | Chen Tax & Advisory | Chen Tax & Advisory | Chen Tax & Advisory | 2 | 2 | PASS |
| LOCATION | Austin, Texas | Austin, Texas | Austin, Texas | 4 | 4 | PASS |
| TIMEZONE | America/Chicago | America/Chicago | America/Chicago | 4 | 4 | PASS |
| TOTAL RETURNS | 1,240 | 1,240 | 1,240 | 6 | 6 | PASS |
| PERSONAL | 980 | 980 | 980 | 6 | 6 | PASS |
| BUSINESS | 260 | 260 | 260 | 6 | 6 | PASS |
| TAX SOFTWARE | UltraTax | UltraTax | UltraTax | 8 | 8 | PASS |
| ENVIRONMENT | Desktop | Desktop | Desktop | 8 | 8 | PASS |
| HOSTED BY | Rightworks | Rightworks | Rightworks | 8 | 8 | PASS |
| CLIENT PORTAL | SmartVault | SmartVault | SmartVault | 10 | 10 | PASS |
| PRACTICE MGMT | Canopy | Canopy | Canopy | 10 | 10 | PASS |
| SUPPORTING | QuickBooks Online, SurePrep, GruntWorx | QuickBooks Online, SurePrep, GruntWorx | QuickBooks Online, SurePrep, GruntWorx | 10 | 10 | PASS |
| ADMINS | 2 | 2 | 2 | 12 | 12 | PASS |
| PREPARERS | 6 | 6 | 6 | 12 | 12 | PASS |
| REVIEWERS | 2 | 2 | 2 | 12 | 12 | PASS |
| CPAS | 4 | 4 | 4 | 12 | 12 | PASS |
| MIN COMMITMENT | 100 | 100 | 100 | 13 | 13 | PASS |
| OTHER NUMBERS | $40 per return | $40 per return | $40 per return | 13 | 13 | PASS |

## Scorecard mutation history

- Turn 2 / NAME: `blank` -> `Maya Chen` / correct / "I'm Maya Chen, and the firm is Chen Tax & Advisory."
- Turn 2 / FIRM: `blank` -> `Chen Tax & Advisory` / correct / "I'm Maya Chen, and the firm is Chen Tax & Advisory."
- Turn 4 / LOCATION: `blank` -> `Austin, Texas` / correct / "We're based in Austin, Texas."
- Turn 4 / TIMEZONE: `blank` -> `America/Chicago` / correct / "We're based in Austin, Texas."
- Turn 6 / TOTAL RETURNS: `blank` -> `1,240` / correct / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 6 / PERSONAL: `blank` -> `980` / correct / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 6 / BUSINESS: `blank` -> `260` / correct / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 8 / TAX SOFTWARE: `blank` -> `UltraTax` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 8 / ENVIRONMENT: `blank` -> `Desktop` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 8 / HOSTED BY: `blank` -> `Rightworks` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 10 / CLIENT PORTAL: `blank` -> `SmartVault` / correct / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 10 / PRACTICE MGMT: `blank` -> `Canopy` / correct / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 10 / SUPPORTING: `blank` -> `QuickBooks Online, SurePrep, GruntWorx` / correct / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 12 / ADMINS: `blank` -> `2` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 12 / PREPARERS: `blank` -> `6` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 12 / REVIEWERS: `blank` -> `2` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 12 / CPAS: `blank` -> `4` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 13 / MIN COMMITMENT: `blank` -> `100` / correct / "For the trial, our minimum commitment is 100 returns, and the price is $40 per return."
- Turn 13 / OTHER NUMBERS: `blank` -> `$40 per return` / correct / "For the trial, our minimum commitment is 100 returns, and the price is $40 per return."

## Wrong extractor proposals

None.

## Diagnostic totals

- Model or pattern proposals returned: 52
- Scorecard mutations: 19
- Rejected trace decisions: 41
- Wrong final fields: none
- Missing final fields: none
- Unexpected final fields: none
