# Source precedence

Use precedence by fact type, not one global source order.

## Prospect and qualification facts

1. Exact statement in the complete Circleback transcript
2. Exact statement in the relevant complete Gmail thread
3. Ross's explicit manual correction or post-call note in Notion
4. Calendar intake fields or event description
5. Circleback AI notes or summaries
6. Inference from surrounding context

## Scheduling facts

1. Google Calendar event and iCalUID
2. Circleback meeting metadata
3. Gmail invitation or scheduling thread

## Destination identity

Preserve the existing destination owner, stable IDs, and verified company links unless stronger explicit correction evidence exists.

## Conflicts

When high-quality sources conflict, retain both source references, mark the affected field `Needs confirmation`, and do not silently select the more convenient value. Ross's explicit correction wins and should become a regression case.
