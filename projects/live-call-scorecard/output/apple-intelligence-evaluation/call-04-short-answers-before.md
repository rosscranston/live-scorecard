# Elena Brooks - short contextual answers and demo-number noise

- Fixture: `call-04-short-answers`
- Basis: Synthetic call covering short answer linkage and the real replay error where three steps and demo timing were treated as prospect numbers.
- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`
- Final accuracy: 9/12
- First-pick accuracy: 9/12
- On-time first-pick accuracy: 9/12
- Wrong scorecard writes: 0
- Wrong extractor proposals: 0

## Transcript

1. **ROSS:** What is your name and practice name?
2. **PROSPECT:** Elena Brooks. Brooks Tax Lab.
3. **ROSS:** Where are you calling in from?
4. **PROSPECT:** Phoenix, Arizona.
5. **ROSS:** How many total returns, personal returns, and business returns do you file?
6. **PROSPECT:** About 800 total. 650 personal. 150 business.
7. **ROSS:** What do you use for tax software?
8. **PROSPECT:** TaxShark cloud.
9. **ROSS:** What other supporting tools do you use?
10. **PROSPECT:** QuickBooks Online, Microsoft 365, and DocuSign.
11. **ROSS:** The demo itself is just three steps. Processing can take 20 minutes, and this sample has 15 documents.
12. **ROSS:** The trial minimum is 100 returns and the price is $40 per return.

## Gold versus final scorecard

| Field | Gold | Apple final | First saved | First turn | Eligible turn | Result |
|---|---|---|---|---:|---:|---|
| NAME | Elena Brooks | Elena Brooks | Elena Brooks | 2 | 2 | PASS |
| FIRM | Brooks Tax Lab | — | — | — | 2 | MISSED |
| LOCATION | Phoenix, Arizona | Phoenix, Arizona | Phoenix, Arizona | 4 | 4 | PASS |
| TIMEZONE | America/Phoenix | America/Phoenix | America/Phoenix | 4 | 4 | PASS |
| TOTAL RETURNS | 800 | — | — | — | 6 | MISSED |
| PERSONAL | 650 | 650 | 650 | 6 | 6 | PASS |
| BUSINESS | 150 | — | — | — | 6 | MISSED |
| TAX SOFTWARE | TaxShark | TaxShark | TaxShark | 8 | 8 | PASS |
| ENVIRONMENT | Cloud | Cloud | Cloud | 8 | 8 | PASS |
| SUPPORTING | QuickBooks Online, Microsoft 365, DocuSign | QuickBooks Online, Microsoft 365, DocuSign | QuickBooks Online, Microsoft 365, DocuSign | 10 | 10 | PASS |
| MIN COMMITMENT | 100 | 100 | 100 | 12 | 12 | PASS |
| OTHER NUMBERS | $40 per return | $40 per return | $40 per return | 12 | 12 | PASS |

## Scorecard mutation history

- Turn 2 / NAME: `blank` -> `Elena Brooks` / correct / "Elena Brooks."
- Turn 4 / LOCATION: `blank` -> `Phoenix, Arizona` / correct / "Phoenix, Arizona."
- Turn 4 / TIMEZONE: `blank` -> `America/Phoenix` / correct / "Phoenix, Arizona."
- Turn 6 / PERSONAL: `blank` -> `650` / correct / "650 personal."
- Turn 8 / TAX SOFTWARE: `blank` -> `TaxShark` / correct / "TaxShark cloud."
- Turn 8 / ENVIRONMENT: `blank` -> `Cloud` / correct / "TaxShark cloud."
- Turn 10 / SUPPORTING: `blank` -> `QuickBooks Online, Microsoft 365, DocuSign` / correct / "QuickBooks Online, Microsoft 365, and DocuSign."
- Turn 12 / MIN COMMITMENT: `blank` -> `100` / correct / "The trial minimum is 100 returns and the price is $40 per return."
- Turn 12 / OTHER NUMBERS: `blank` -> `$40 per return` / correct / "The trial minimum is 100 returns and the price is $40 per return."

## Wrong extractor proposals

None.

## Diagnostic totals

- Model or pattern proposals returned: 19
- Scorecard mutations: 9
- Rejected trace decisions: 56
- Wrong final fields: none
- Missing final fields: FIRM, TOTAL RETURNS, BUSINESS
- Unexpected final fields: none
