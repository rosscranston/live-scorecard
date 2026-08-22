# Executive findings: Anthropic’s notebook channels and what Cranston should do

## Recommendation

Cranston should run a six-week pilot with one public internal notebook channel per participating owner, a weekly posting rhythm, explicit norms for disagreement and uncertainty, and a separate `#decisions` or durable Markdown/Notion record for final decisions. At seven people, the closest useful adaptation is not “copy Anthropic at scale”; it is “make the company’s thinking inspectable while preserving focus, privacy, and decision clarity.”

## The pattern in one sentence

A notebook channel is a person-centered, internally public Slack stream where an owner shares what they are thinking, trying, learning, and questioning; coworkers can follow selectively and reply in context.

## What Anthropic appears to do

The best public evidence points to five design choices:

1. **A personal channel, not one executive announcement channel.** Public accounts describe notebook channels associated with individuals and describe them as an internal Twitter-like feed.
2. **Writing as an operating rhythm.** Ami Vora described weekly goals, a look back at performance against the prior week, product-direction thinking, and areas where teams need clarity.
3. **Public access and selective following.** People can join or follow channels outside their immediate function, including research and leadership channels.
4. **Dissent in the same visible space.** Amol Avasare described employees challenging leadership publicly and said this is encouraged because it builds trust.
5. **Searchable context for humans and agents.** Anthropic’s own guidance says agents depend on written, searchable context in Slack, docs, code, and meeting notes; its guidance recommends defaulting new communication channels to public within the organization and putting decisions into searchable artifacts.

The exact internal eligibility rule is not public. One account says every level of leadership and function participates; another transcript-based account says “everyone has” notebook channels but also includes wording that not everyone has one. The defensible conclusion is that Anthropic uses personal notebook channels broadly, including leadership, but the public record does not establish the precise enrollment policy or channel-creation workflow.

## Why it can work

Notebook channels attack four common startup problems:

- **Context trapped in the founder’s head.** Writing exposes priorities, reasoning, and uncertainty without requiring another meeting.
- **Cross-functional blind spots.** Public streams let people discover relevant work outside their function and contribute when they have useful context.
- **Founder-as-bottleneck behavior.** A visible reasoning trail lets people act on direction without repeatedly asking the founder for a verbal update.
- **Low-quality disagreement.** A public thread makes disagreement concrete, attributable, and available for others to learn from; the norm must be “challenge the idea, explain the evidence, and close the loop.”

Research on enterprise social media supports the mechanism, not the Anthropic case specifically: visibility can increase knowledge transfer, knowledge provision, and agility, while visibility and high usage can also create information overload, social overload, strain, and exhaustion. The same design can therefore create either leverage or noise depending on norms and notification discipline.

## What Cranston should copy

- Internal visibility by default for ordinary work.
- A short weekly accountability loop: plan, result, learning, next move.
- Leaders going first and admitting misses or uncertainty.
- Public, respectful challenge as a normal contribution.
- Written artifacts that can later be searched by humans or AI.
- A clear separation between “thinking aloud,” “request for input,” and “decision.”

## What Cranston should not copy literally

- Do not require constant stream-of-consciousness posting.
- Do not make public notebooks the performance-review system.
- Do not put customer-confidential information, personnel matters, credentials, security vulnerabilities, or legally sensitive material in public channels.
- Do not make Slack the only system of record for commitments, product requirements, customer facts, or security decisions.
- Do not connect an AI agent to all Slack content until access boundaries, retention, human review, and confidential-data rules are explicit.

## Proposed Cranston design

| Surface | Purpose | Posting rule |
|---|---|---|
| `#notebooks-index` | Explains the pattern and links to each notebook | Founder/ops maintains the index |
| `#notebook-[name]` | Personal public stream for an owner’s thinking and updates | One substantive post per week; more only when useful |
| `#decisions` or durable decision log | Final decisions, owner, date, rationale, reversibility | Record decisions after the discussion, not every brainstorm |
| Existing project/customer channels | Work execution and detailed collaboration | Keep operational work in the relevant project/channel |
| DMs/private channels | Sensitive or genuinely need-to-know matters | Move generalizable, non-sensitive conclusions back to a public artifact |

For a seven-person company, give every person the option to have a notebook, but make a weekly cadence mandatory only for people who own company-level or cross-functional outcomes. This preserves the “everyone can think in public” spirit without turning writing into a compliance ritual.

## The weekly post Cranston should use

```markdown
*Week of YYYY-MM-DD — [short title]*

*Last week:* What I expected to happen; what actually happened; what I learned.

*This week:* The 1–3 outcomes I am prioritizing and how I will know they moved.

*Thinking / uncertainty:* The idea, concern, or tradeoff I am working through.

*Ask:* The specific input, disagreement, introduction, or decision I want from the team.

*Decision status:* Thinking aloud / seeking input / decision made.
```

## Success criteria for the pilot

Treat the pilot as an operating experiment. By week six, Cranston should be able to answer:

- Are important priorities and reasoning easier to discover without another meeting?
- Do people make fewer repetitive “what’s going on?” pings?
- Do at least two people outside the owner’s immediate area contribute useful context?
- Do leaders close the loop when they change direction or miss a goal?
- Do people feel safer challenging an idea, not more exposed for doing so?
- Is the information value greater than the notification and reading cost?

If the answer is no, reduce cadence, consolidate channels, or move the pattern to a weekly company-wide “thinking” thread rather than treating Anthropic’s format as sacred.

## Source boundaries

The primary notebook-specific accounts are [Ami Vora’s reported description](https://www.implicator.ai/anthropic-makes-leaders-write-in-public-the-ones-who-resist-tell-you-everything-2/), [Amol Avasare’s podcast transcript and summary](https://www.teahose.com/podcast/Lenny%27s/Anthropic%E2%80%99s%20%241B%20to%20%2419B%20growth%20run_%20how%20Claude%20became%20the%20fastest-growing%20AI%20product%20in%20history%20_%20Amol%20Avasare), and [the associated podcast page](https://www.lennysnewsletter.com/p/anthropics-1b-to-19b-growth-run). Anthropic’s broader public-by-default and agent-context guidance is in [Lessons from Anthropic on building effective human-agent teams](https://claude.com/blog/building-effective-human-agent-teams). Slack implementation details are based on [Slack’s channel guidance](https://slack.com/help/articles/217626408-Create-guidelines-for-channel-names), [channel creation documentation](https://slack.com/help/articles/201402297-Create-a-channel), [threads](https://slack.com/intl/en-gb/help/articles/115000769927-Use-threads-to-organise-discussions), [canvases](https://slack.com/help/articles/203950418-Use-a-canvas-in-Slack), and [posting permissions](https://slack.com/help/articles/360004635551-Manage-channel-posting-permissions-).

