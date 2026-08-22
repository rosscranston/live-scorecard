# Priya Shah - corrections, evaluation language, and minimum questions

- Fixture: `call-03-corrections`
- Basis: Synthetic call covering explicit corrections and the observed failure mode of treating questions or evaluated software as current facts.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 11/12
- First-pick accuracy: 12/12
- On-time first-pick accuracy: 12/12
- Wrong scorecard writes: 0
- Wrong extractor proposals: 1

## Transcript

1. **ROSS:** Can I confirm your name, firm, and location for my notes?
2. **PROSPECT:** I'm Priya Shah with Redwood CPA Group, based in Portland, Oregon.
3. **ROSS:** How many total returns do you file?
4. **PROSPECT:** About 900 total returns.
5. **ROSS:** And what is the personal and business split?
6. **PROSPECT:** Let me correct the total: it is 940 total returns, made up of 700 personal returns and 240 business returns.
7. **ROSS:** What do you use for tax software?
8. **PROSPECT:** We're evaluating Drake, but we currently use CCH Axcess hosted by Cetrom.
9. **ROSS:** What other software supports the workflow?
10. **PROSPECT:** We also use QuickBooks Online, Adobe Acrobat, and DocuSign.
11. **ROSS:** Our minimum commitment is 100 returns.
12. **PROSPECT:** Is the minimum 50 returns?
13. **ROSS:** No, the minimum is 100 returns.

## Gold versus final scorecard

| Field | Gold | Apple final | First saved | First turn | Eligible turn | Result |
|---|---|---|---|---:|---:|---|
| NAME | Priya Shah | Priya Shah | Priya Shah | 2 | 2 | PASS |
| FIRM | Redwood CPA Group | Redwood CPA Group | Redwood CPA Group | 2 | 2 | PASS |
| LOCATION | Portland, Oregon | Portland, Oregon | Portland, Oregon | 2 | 2 | PASS |
| TIMEZONE | America/Los_Angeles | America/Los_Angeles | America/Los_Angeles | 2 | 2 | PASS |
| TOTAL RETURNS | 940 | 900 | 900 | 4 | 4 | WRONG |
| PERSONAL | 700 | 700 | 700 | 6 | 6 | PASS |
| BUSINESS | 240 | 240 | 240 | 6 | 6 | PASS |
| TAX SOFTWARE | CCH Axcess | CCH Axcess | CCH Axcess | 8 | 8 | PASS |
| ENVIRONMENT | Hosted | Hosted | Hosted | 8 | 8 | PASS |
| HOSTED BY | Cetrom | Cetrom | Cetrom | 8 | 8 | PASS |
| SUPPORTING | QuickBooks Online, Adobe Acrobat, DocuSign | QuickBooks Online, Adobe Acrobat, DocuSign | QuickBooks Online, Adobe Acrobat, DocuSign | 10 | 10 | PASS |
| MIN COMMITMENT | 100 | 100 | 100 | 11 | 11 | PASS |

## Scorecard mutation history

- Turn 2 / NAME: `blank` -> `Priya Shah` / correct / "I'm Priya Shah with Redwood CPA Group, based in Portland, Oregon."
- Turn 2 / FIRM: `blank` -> `Redwood CPA Group` / correct / "I'm Priya Shah with Redwood CPA Group, based in Portland, Oregon."
- Turn 2 / LOCATION: `blank` -> `Portland, Oregon` / correct / "I'm Priya Shah with Redwood CPA Group, based in Portland, Oregon."
- Turn 2 / TIMEZONE: `blank` -> `America/Los_Angeles` / correct / "I'm Priya Shah with Redwood CPA Group, based in Portland, Oregon."
- Turn 4 / TOTAL RETURNS: `blank` -> `900` / correct / "About 900 total returns."
- Turn 6 / PERSONAL: `blank` -> `700` / correct / "Let me correct the total: it is 940 total returns, made up of 700 personal returns and 240 business returns."
- Turn 6 / BUSINESS: `blank` -> `240` / correct / "Let me correct the total: it is 940 total returns, made up of 700 personal returns and 240 business returns."
- Turn 8 / TAX SOFTWARE: `blank` -> `CCH Axcess` / correct / "We're evaluating Drake, but we currently use CCH Axcess hosted by Cetrom."
- Turn 8 / ENVIRONMENT: `blank` -> `Hosted` / correct / "We're evaluating Drake, but we currently use CCH Axcess hosted by Cetrom."
- Turn 8 / HOSTED BY: `blank` -> `Cetrom` / correct / "We're evaluating Drake, but we currently use CCH Axcess hosted by Cetrom"
- Turn 10 / SUPPORTING: `blank` -> `QuickBooks Online, Adobe Acrobat, DocuSign` / correct / "We also use QuickBooks Online, Adobe Acrobat, and DocuSign."
- Turn 11 / MIN COMMITMENT: `blank` -> `100` / correct / "Our minimum commitment is 100 returns."

## Wrong extractor proposals

- Turn 4 / TOTAL RETURNS: `about 900` / "About 900 total returns."

## Diagnostic totals

- Model or pattern proposals returned: 38
- Scorecard mutations: 12
- Rejected trace decisions: 44
- Wrong final fields: TOTAL RETURNS
- Missing final fields: none
- Unexpected final fields: none
