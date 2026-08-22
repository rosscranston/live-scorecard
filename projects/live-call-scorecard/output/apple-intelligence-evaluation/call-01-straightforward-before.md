# Maya Chen - straightforward established firm

- Fixture: `call-01-straightforward`
- Basis: Synthetic discovery call modeled on the structure and terminology of the locally stored Circleback demo replay.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 16/19
- First-pick accuracy: 17/19
- Wrong scorecard writes: 3
- Wrong extractor proposals: 5

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

| Field | Gold | Apple final | First saved | Result |
|---|---|---|---|---|
| NAME | Maya Chen | Maya Chen | Maya Chen | PASS |
| FIRM | Chen Tax & Advisory | Chen Tax & Advisory | Chen Tax & Advisory | PASS |
| LOCATION | Austin, Texas | Austin, Texas | Austin, Texas | PASS |
| TIMEZONE | America/Chicago | America/Chicago | America/Chicago | PASS |
| TOTAL RETURNS | 1,240 | 980 | 980 | WRONG |
| PERSONAL | 980 | 980 | 980 | PASS |
| BUSINESS | 260 | 260 | 260 | PASS |
| TAX SOFTWARE | UltraTax | UltraTax | UltraTax | PASS |
| ENVIRONMENT | Desktop | desktop | Desktop | PASS |
| HOSTED BY | Rightworks | Rightworks | Rightworks | PASS |
| CLIENT PORTAL | SmartVault | SmartVault | SmartVault | PASS |
| PRACTICE MGMT | Canopy | Canopy | Canopy | PASS |
| SUPPORTING | QuickBooks Online, SurePrep, GruntWorx | QuickBooks Online, SurePrep, GruntWorx, and GruntWorx | QuickBooks Online, SurePrep, GruntWorx | WRONG |
| ADMINS | 2 | 2 | 2 | PASS |
| PREPARERS | 6 | 6 | 6 | PASS |
| REVIEWERS | 2 | 2 | 2 | PASS |
| CPAS | 4 | 4 | 4 | PASS |
| MIN COMMITMENT | 100 | 100 | 100 | PASS |
| OTHER NUMBERS | $40 per return | — | — | MISSED |

## Scorecard mutation history

- Turn 2 / NAME: `blank` -> `Maya Chen` / correct / "I'm Maya Chen"
- Turn 2 / FIRM: `blank` -> `Chen Tax & Advisory` / correct / "the firm is Chen Tax & Advisory"
- Turn 4 / LOCATION: `blank` -> `Austin, Texas` / correct / "We're based in Austin, Texas."
- Turn 4 / TIMEZONE: `blank` -> `America/Chicago` / correct / "We're based in Austin, Texas."
- Turn 6 / TOTAL RETURNS: `blank` -> `980` / WRONG / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 6 / PERSONAL: `blank` -> `980` / correct / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 6 / BUSINESS: `blank` -> `260` / correct / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 8 / TAX SOFTWARE: `blank` -> `UltraTax` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 8 / ENVIRONMENT: `blank` -> `Desktop` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 8 / HOSTED BY: `blank` -> `Rightworks` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 9 / ENVIRONMENT: `Desktop` -> `desktop` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 10 / ENVIRONMENT: `desktop` -> `desktop, hosted` / WRONG / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 10 / CLIENT PORTAL: `blank` -> `SmartVault` / correct / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 10 / PRACTICE MGMT: `blank` -> `Canopy` / correct / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 10 / SUPPORTING: `blank` -> `QuickBooks Online, SurePrep, GruntWorx` / correct / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 12 / ENVIRONMENT: `desktop, hosted` -> `desktop` / correct / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 12 / SUPPORTING: `QuickBooks Online, SurePrep, GruntWorx` -> `QuickBooks Online, SurePrep, GruntWorx, and GruntWorx` / WRONG / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 12 / ADMINS: `blank` -> `2` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 12 / PREPARERS: `blank` -> `6` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 12 / REVIEWERS: `blank` -> `2` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 12 / CPAS: `blank` -> `4` / correct / "We have 2 admins, 6 preparers, 2 reviewers, and 4 CPAs."
- Turn 13 / MIN COMMITMENT: `blank` -> `100` / correct / "For the trial, our minimum commitment is 100 returns, and the price is $40 per return."

## Wrong extractor proposals

- Turn 6 / TOTAL RETURNS: `980` / "We file 1,240 total returns: 980 personal returns and 260 business returns."
- Turn 10 / ENVIRONMENT: `desktop, hosted` / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 11 / ENVIRONMENT: `desktop, hosted` / "We use UltraTax on desktop, hosted by Rightworks."
- Turn 12 / SUPPORTING: `QuickBooks Online, SurePrep, and GruntWorx` / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."
- Turn 13 / SUPPORTING: `QuickBooks Online, SurePrep, and GruntWorx` / "SmartVault is our client portal, Canopy is our practice management, and our other tools are QuickBooks Online, SurePrep, and GruntWorx."

## Diagnostic totals

- Model or pattern proposals returned: 80
- Scorecard mutations: 22
- Rejected trace decisions: 88
- Wrong final fields: TOTAL RETURNS, SUPPORTING
- Missing final fields: OTHER NUMBERS
- Unexpected final fields: none
