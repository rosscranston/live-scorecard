# Apple Intelligence scorecard evaluation

## Outcome

Five transcript fixtures were scored incrementally through the production `FactExtractionService` and `FactReducer`. Each substantive speaker turn was evaluated in chronological order. The evaluator retained every proposed value, first visible value, later mutation, and ending scorecard.

The frozen final run completed on August 21, 2026 in 780.480 seconds.

| Measure | Sequential baseline | Final frozen run |
|---|---:|---:|
| Correct ending fields | 62 / 74 | 74 / 74 |
| Correct first saved values | 64 / 74 | 74 / 74 |
| Correct on first eligible turn | 63 / 74 | 74 / 74 |
| Wrong visible scorecard writes | 5 | 0 |
| Wrong extractor proposals | 11 | 0 |

The baseline is sequential: each call's `before` report reflects the rules available when that call was reached. Improvements from an earlier call were retained for later baselines.

## Calls

| Call | Main stress case | Before final | Final | First/on-time final | Wrong final writes |
|---|---|---:|---:|---:|---:|
| 01 Maya Chen | Straightforward full discovery | 16 / 19 | 19 / 19 | 19 / 19 | 0 |
| 02 Daniel Ortiz | Old-firm and seller software distractors | 13 / 16 | 16 / 16 | 16 / 16 | 0 |
| 03 Priya Shah | Explicit correction and minimum question | 11 / 12 | 12 / 12 | 12 / 12 | 0 |
| 04 Elena Brooks | Terse answers and demo-number noise | 9 / 12 | 12 / 12 | 12 / 12 | 0 |
| 05 Harbor Ledger | New practice versus Deloitte workload | 13 / 15 | 15 / 15 | 15 / 15 | 0 |

## Improvement after each call

### Call 1

- Question-only turns no longer trigger a model rewrite.
- The first explicit total wins over a later breakdown number in the same sentence.
- Environment is canonicalized to exactly `Desktop`, `Cloud`, or `Hosted`.
- Supporting-software conjunctions and duplicates are removed.
- Explicit prices such as `$40 per return` are recognized without treating demo numbers as commercial facts.

### Call 2

- The closest complete question wins over older questions when interpreting a short answer.
- Direct person and firm identity statements have deterministic extraction paths.
- Current-use cues distinguish active software from old, evaluated, and seller-mentioned products.
- Short location answers and explicit portal/practice-management statements are deterministic.
- Stable fields require explicit correction before replacement.
- `QuickBooks` is not added as a second product when the evidence only says `QuickBooks Online`.

### Call 3

- Return counts stated before `total returns` are recognized.
- `Let me correct the total` is treated as explicit correction language by the replacement policy.
- Questions such as `Is the minimum 50 returns?` remain non-evidence.

### Call 4

- A two-part identity answer such as `Elena Brooks. Brooks Tax Lab.` is linked to the name-and-practice question.
- Short labeled return fragments such as `About 800 total. 650 personal. 150 business.` populate all three fields on the answer turn.
- Seller demo counts remain excluded unless they use explicit commercial labels and units.

### Call 5

- Prior-employer workload such as `worked on 250 returns` is not accepted as the current firm's annual return volume.
- A breakdown after `75 total returns:` cannot replace the total with `60 personal`.
- Portal and practice-management name capture cannot cross a sentence boundary.
- Environment suffixes are removed from raw primary-software proposals, so `Drake desktop` becomes software `Drake` plus environment `Desktop`.

## Artifacts

- Gold transcripts and scorecard timelines: `Tests/Fixtures/AccuracyEvaluation/calls.json`
- Evaluation harness: `Tests/LiveScorecardTests/AppleIntelligenceAccuracyEvaluationTests.swift`
- Individual reports: `call-01-straightforward-final.md` through `call-05-new-practice-final.md`

Run a strict future regression with:

```bash
RUN_APPLE_INTELLIGENCE_EVAL=1 EVAL_REQUIRE_PERFECT=1 EVAL_RUN_LABEL=regression swift test --filter AppleIntelligenceAccuracyEvaluationTests/testRunSelectedAccuracyFixtures
```

## Limits

These five calls are controlled evaluations, not a statistically representative accuracy claim. They are synthetic calls grounded in the structure, terminology, and observed errors of locally stored demo-call transcripts. The local Circleback replay did not have reliable speaker diarization, so it was used as design evidence rather than unquestioned gold data. Apple Intelligence is generative and can vary between runs; deterministic evidence rules and replacement guards carry the high-certainty fields specifically to reduce that variance.
