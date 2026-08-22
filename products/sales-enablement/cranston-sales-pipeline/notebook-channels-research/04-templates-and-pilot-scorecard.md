# Templates and pilot scorecard

## Copy-ready weekly notebook template

```markdown
*UPDATE / THINKING / ASK / LESSON — Week of YYYY-MM-DD*

*Last week*
- Intended outcome:
- Actual result:
- What I learned:

*This week*
1. [Outcome] — success looks like [observable signal].
2. [Outcome] — success looks like [observable signal].
3. [Outcome] — success looks like [observable signal].

*Thinking / uncertainty*
[The idea, concern, tradeoff, or hypothesis I am working through.]

*Ask*
[The specific question or input I want. If there is no ask, write “No ask; sharing context.”]

*Decision status*
Thinking aloud / seeking input / decision made

*Close the loop*
[Add later: what changed because of the discussion, or link to the decision record.]
```

## Short-form post for busy weeks

```markdown
*UPDATE — [short title]*

Moved: [one sentence]
Learned: [one sentence]
Unclear: [one sentence]
Ask: [one sentence or “none”]
```

## Constructive disagreement template

```markdown
I disagree with [specific claim/assumption], not with the goal.

My evidence/reasoning:
1. [Evidence]
2. [Evidence]

The tradeoff I see is [tradeoff].

I would change my mind if [condition].

My recommendation: [specific alternative or experiment].
```

## Close-the-loop template

```markdown
*CLOSE THE LOOP — [topic]*

We heard: [best summary of the disagreement/input].
Decision: [what we are doing].
Why: [short rationale].
What changed from my original view: [if anything].
Owner / next step: [person + action + date].
Durable record: [link].
```

## Notebook charter

```markdown
# Cranston notebook charter

Purpose: make useful company thinking visible early enough for teammates to help, learn, and act.

This is:
- a public internal thinking stream
- a place for goals, learning, hypotheses, uncertainty, and asks
- a place where respectful disagreement is welcome

This is not:
- a performance-review dossier
- a guarantee that a thought is a decision
- a place for confidential customer, personnel, legal, security, or credential data
- a replacement for durable product, customer, finance, or security records

Norms:
1. Leaders go first and share misses, not only wins.
2. Challenge ideas with evidence and alternatives.
3. Use threads for detail.
4. Close the loop when the view or decision changes.
5. Protect focus: no expectation of instant replies.
6. If something should be private, keep it private; move only the safe, generalizable lesson back to a public artifact.
```

## Six-week scorecard

Use a baseline in week 0 and a pulse at week 3 and week 6. These are proposed Cranston measures, not Anthropic benchmarks.

### Adoption and quality

| Measure | Definition | Proposed pilot signal |
|---|---|---|
| Owner cadence | Share of required owners posting at least once in each pilot week | ≥80% of required owners in ≥4 of 6 weeks |
| Useful post rate | Posts rated useful by at least one teammate, excluding simple status noise | ≥60% of substantive posts |
| Cross-functional contribution | Useful replies from someone outside the owner’s immediate work area | At least 2 per week by week 4 |
| Close-the-loop rate | Material discussions that end with a conclusion or explicit next step | ≥80% |

### Coordination value

| Measure | How to collect | Decision use |
|---|---|---|
| Repeated status pings | Sample DMs and meetings asking for context; compare with baseline | Keep if decreasing without more reading cost |
| Alignment meetings | Count meetings whose main purpose is status or context transfer | Replace only when the written stream actually carries the context |
| Decision discoverability | Ask: “Could you find why this decision was made?” on 3 sampled decisions | Keep if discoverability improves |
| Time-to-answer | For 3 cross-functional questions, record time until the right person responds | Keep if answers get faster or more complete |

### Trust and load

Rate 1–5 anonymously or in a lightweight form:

1. “I understand what the company is prioritizing and why.”
2. “I can disagree with an idea here without being punished for it.”
3. “Leaders close the loop when their views change.”
4. “The notebook channels provide more value than noise.”
5. “I know what does and does not belong in a public notebook.”

Red flags:

- people stop posting unfinished ideas and only publish polished wins
- a leader corrects or punishes public disagreement
- people feel expected to monitor every notebook in real time
- sensitive information appears in a public channel
- the decision log becomes less reliable because “it is all in Slack”
- posts are optimized for visibility rather than useful work

## Pilot review questions

At week 6, discuss:

- What did we learn earlier because someone posted it publicly?
- Which post or thread changed a decision or prevented duplicated work?
- What did we read that did not deserve to be public?
- Did the pattern reduce founder bottlenecks or merely create another inbox?
- Which norms made disagreement safer? Which leader reactions made it harder?
- Should every person keep a notebook, or should the cadence be limited to owners?
- What belongs in Slack, and what must move into Markdown, Notion, a CRM, or a security system?
- Is an AI summary useful enough to justify the access and retention risk?

## Recommended pilot decision tree

```text
Is information value clearly higher than reading cost?
├── No → Reduce cadence or consolidate into one shared weekly thinking thread.
└── Yes
    ├── Are people comfortable disagreeing and admitting misses?
    │   ├── No → Fix leader response and psychological-safety norms before expanding.
    │   └── Yes
    │       ├── Are durable decisions still being recorded elsewhere?
    │       │   ├── No → Add decision-log discipline before adding AI.
    │       │   └── Yes → Consider narrow, read-only AI summaries with human review.
```

