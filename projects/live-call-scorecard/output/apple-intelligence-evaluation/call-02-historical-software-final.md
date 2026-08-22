# Daniel Ortiz - historical and seller software distractors

- Fixture: `call-02-historical-software`
- Basis: Synthetic call designed from observed Circleback replay errors where demo integrations and prior-employer facts contaminated the prospect scorecard.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 16/16
- First-pick accuracy: 16/16
- On-time first-pick accuracy: 16/16
- Wrong scorecard writes: 0
- Wrong extractor proposals: 0

## Transcript

1. **ROSS:** Hey Daniel. I have Ortiz Accounting from the calendar. Is that still the correct firm name?
2. **PROSPECT:** Yes, I'm Daniel Ortiz, and Ortiz Accounting is correct.
3. **ROSS:** Where are you calling in from?
4. **PROSPECT:** Fresno, California.
5. **ROSS:** Our product can export to Lacerte, Drake, CCH Axcess, and UltraTax. What do you use for tax software?
6. **PROSPECT:** At my old firm we had Lacerte, but Ortiz Accounting uses ProSeries desktop now.
7. **ROSS:** How many returns do you file annually?
8. **PROSPECT:** We file 600 total returns, with 500 personal returns and 100 business returns.
9. **ROSS:** What portal, practice management, and other software do you use?
10. **PROSPECT:** TaxDome handles our client portal and practice management. QuickBooks Online is the other supporting software we use.
11. **ROSS:** You mentioned three people overall. How many are admins, preparers, reviewers, and CPAs?
12. **PROSPECT:** There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs.

## Gold versus final scorecard

| Field | Gold | Apple final | First saved | First turn | Eligible turn | Result |
|---|---|---|---|---:|---:|---|
| NAME | Daniel Ortiz | Daniel Ortiz | Daniel Ortiz | 2 | 2 | PASS |
| FIRM | Ortiz Accounting | Ortiz Accounting | Ortiz Accounting | 2 | 2 | PASS |
| LOCATION | Fresno, California | Fresno, California | Fresno, California | 4 | 4 | PASS |
| TIMEZONE | America/Los_Angeles | America/Los_Angeles | America/Los_Angeles | 4 | 4 | PASS |
| TAX SOFTWARE | ProSeries | ProSeries | ProSeries | 6 | 6 | PASS |
| ENVIRONMENT | Desktop | Desktop | Desktop | 6 | 6 | PASS |
| TOTAL RETURNS | 600 | 600 | 600 | 8 | 8 | PASS |
| PERSONAL | 500 | 500 | 500 | 8 | 8 | PASS |
| BUSINESS | 100 | 100 | 100 | 8 | 8 | PASS |
| CLIENT PORTAL | TaxDome | TaxDome | TaxDome | 10 | 10 | PASS |
| PRACTICE MGMT | TaxDome | TaxDome | TaxDome | 10 | 10 | PASS |
| SUPPORTING | QuickBooks Online | QuickBooks Online | QuickBooks Online | 10 | 10 | PASS |
| ADMINS | 1 | 1 | 1 | 12 | 12 | PASS |
| PREPARERS | 2 | 2 | 2 | 12 | 12 | PASS |
| REVIEWERS | 1 | 1 | 1 | 12 | 12 | PASS |
| CPAS | 2 | 2 | 2 | 12 | 12 | PASS |

## Scorecard mutation history

- Turn 2 / NAME: `blank` -> `Daniel Ortiz` / correct / "Yes, I'm Daniel Ortiz, and Ortiz Accounting is correct."
- Turn 2 / FIRM: `blank` -> `Ortiz Accounting` / correct / "Yes, I'm Daniel Ortiz, and Ortiz Accounting is correct."
- Turn 4 / LOCATION: `blank` -> `Fresno, California` / correct / "Fresno, California."
- Turn 4 / TIMEZONE: `blank` -> `America/Los_Angeles` / correct / "Fresno, California."
- Turn 6 / TAX SOFTWARE: `blank` -> `ProSeries` / correct / "At my old firm we had Lacerte, but Ortiz Accounting uses ProSeries desktop now."
- Turn 6 / ENVIRONMENT: `blank` -> `Desktop` / correct / "At my old firm we had Lacerte, but Ortiz Accounting uses ProSeries desktop now."
- Turn 8 / TOTAL RETURNS: `blank` -> `600` / correct / "We file 600 total returns, with 500 personal returns and 100 business returns."
- Turn 8 / PERSONAL: `blank` -> `500` / correct / "We file 600 total returns, with 500 personal returns and 100 business returns."
- Turn 8 / BUSINESS: `blank` -> `100` / correct / "We file 600 total returns, with 500 personal returns and 100 business returns."
- Turn 10 / CLIENT PORTAL: `blank` -> `TaxDome` / correct / "TaxDome handles our client portal and practice management. QuickBooks Online is the other supporting software we use."
- Turn 10 / PRACTICE MGMT: `blank` -> `TaxDome` / correct / "TaxDome handles our client portal and practice management. QuickBooks Online is the other supporting software we use."
- Turn 10 / SUPPORTING: `blank` -> `QuickBooks Online` / correct / "TaxDome handles our client portal and practice management. QuickBooks Online is the other supporting software we use."
- Turn 12 / ADMINS: `blank` -> `1` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."
- Turn 12 / PREPARERS: `blank` -> `2` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."
- Turn 12 / REVIEWERS: `blank` -> `1` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."
- Turn 12 / CPAS: `blank` -> `2` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."

## Wrong extractor proposals

None.

## Diagnostic totals

- Model or pattern proposals returned: 24
- Scorecard mutations: 16
- Rejected trace decisions: 61
- Wrong final fields: none
- Missing final fields: none
- Unexpected final fields: none
