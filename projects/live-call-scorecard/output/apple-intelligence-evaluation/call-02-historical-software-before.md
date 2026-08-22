# Daniel Ortiz - historical and seller software distractors

- Fixture: `call-02-historical-software`
- Basis: Synthetic call designed from observed Circleback replay errors where demo integrations and prior-employer facts contaminated the prospect scorecard.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 13/16
- First-pick accuracy: 13/16
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

| Field | Gold | Apple final | First saved | Result |
|---|---|---|---|---|
| NAME | Daniel Ortiz | Daniel Ortiz | Daniel Ortiz | PASS |
| FIRM | Ortiz Accounting | Ortiz Accounting | Ortiz Accounting | PASS |
| LOCATION | Fresno, California | — | — | MISSED |
| TIMEZONE | America/Los_Angeles | — | — | MISSED |
| TAX SOFTWARE | ProSeries | — | — | MISSED |
| ENVIRONMENT | Desktop | Desktop | Desktop | PASS |
| TOTAL RETURNS | 600 | 600 | 600 | PASS |
| PERSONAL | 500 | 500 | 500 | PASS |
| BUSINESS | 100 | 100 | 100 | PASS |
| CLIENT PORTAL | TaxDome | TaxDome | TaxDome | PASS |
| PRACTICE MGMT | TaxDome | TaxDome | TaxDome | PASS |
| SUPPORTING | QuickBooks Online | QuickBooks Online | QuickBooks Online | PASS |
| ADMINS | 1 | 1 | 1 | PASS |
| PREPARERS | 2 | 2 | 2 | PASS |
| REVIEWERS | 1 | 1 | 1 | PASS |
| CPAS | 2 | 2 | 2 | PASS |

## Scorecard mutation history

- Turn 2 / FIRM: `blank` -> `Ortiz Accounting` / correct / "Ortiz Accounting is correct."
- Turn 4 / NAME: `blank` -> `Daniel Ortiz` / correct / "Yes, I'm Daniel Ortiz, and Ortiz Accounting is correct."
- Turn 6 / ENVIRONMENT: `blank` -> `Desktop` / correct / "At my old firm we had Lacerte, but Ortiz Accounting uses ProSeries desktop now."
- Turn 8 / TOTAL RETURNS: `blank` -> `600` / correct / "We file 600 total returns, with 500 personal returns and 100 business returns."
- Turn 8 / PERSONAL: `blank` -> `500` / correct / "We file 600 total returns, with 500 personal returns and 100 business returns."
- Turn 8 / BUSINESS: `blank` -> `100` / correct / "We file 600 total returns, with 500 personal returns and 100 business returns."
- Turn 10 / CLIENT PORTAL: `blank` -> `TaxDome` / correct / "TaxDome handles our client portal and practice management."
- Turn 10 / PRACTICE MGMT: `blank` -> `TaxDome` / correct / "TaxDome handles our client portal and practice management."
- Turn 10 / SUPPORTING: `blank` -> `QuickBooks Online` / correct / "QuickBooks Online is the other supporting software we use."
- Turn 12 / ADMINS: `blank` -> `1` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."
- Turn 12 / PREPARERS: `blank` -> `2` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."
- Turn 12 / REVIEWERS: `blank` -> `1` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."
- Turn 12 / CPAS: `blank` -> `2` / correct / "There is 1 admin, 2 preparers, 1 reviewer, and 2 CPAs."

## Wrong extractor proposals

None.

## Diagnostic totals

- Model or pattern proposals returned: 27
- Scorecard mutations: 13
- Rejected trace decisions: 38
- Wrong final fields: none
- Missing final fields: LOCATION, TIMEZONE, TAX SOFTWARE
- Unexpected final fields: none
