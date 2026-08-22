# Cranston implementation playbook

## Design objective

Create an internal “thinking layer” that helps seven people see priorities, reasoning, uncertainty, and lessons without requiring every update to become a meeting. The operating model is deliberately small: public where safe, structured where useful, private where necessary, and durable outside Slack when a decision or record matters.

## Recommended operating model

### Information architecture

```text
Slack stream layer
├── #notebooks-index       How the pattern works + links to each notebook
├── #notebook-[name]       Personal thinking, goals, learning, questions
├── #company               Announcements and high-signal company-wide notices
├── #project-[name]        Execution, artifacts, and working discussion
└── #decisions             Final decisions and links to durable records

Durable record layer
├── Product/customer docs  Requirements, customer evidence, playbooks
├── Decision log           Decision, owner, date, rationale, review trigger
└── Sensitive systems      Personnel, legal, security, credentials, finance
```

The exact channel names should follow Cranston’s existing Slack taxonomy if one exists. The names above are a target model, not a request to rename current channels.

### Who gets a notebook

At seven people, the practical options are:

| Option | Strength | Failure mode | Recommendation |
|---|---|---|---|
| One shared `#notebooks` channel | Fastest and easiest to read | Loses personal followability; posts compete in one feed | Use only as a two-week experiment if channel sprawl is a major fear |
| One channel per person | Closest to Anthropic’s personal-feed pattern; clear ownership | Seven channels can become noisy if cadence is too high | **Recommended** |
| Only founder/functional leads | Less noise; easy to launch | Preserves hierarchy and makes thinking feel executive-only | Use if trust or confidentiality is not ready for all-seven participation |
| Notion/Markdown only | Durable and searchable | Less ambient, lower conversational energy | Use for final decisions and durable knowledge, not the only thinking stream |

Give every person the option to have a public notebook. Require a weekly post only for owners of cross-functional outcomes. Encourage everyone else to post when they have a useful idea, experiment, learning, or constructive disagreement.

## Channel setup

### `#notebooks-index` topic

> Personal public streams for goals, thinking, learning, and constructive disagreement. Follow selectively. Decisions belong in `#decisions` or the linked durable record. Do not post confidential customer, personnel, legal, security, or credential information.

### `#notebooks-index` first message

```markdown
*Cranston notebooks*

These channels are a lightweight way to make useful thinking visible. They are not performance-review dossiers, mandatory status reports, or a place to publish sensitive information.

Use your notebook to share:
• what you are trying to accomplish
• what you learned from customers, product work, or experiments
• an idea or tradeoff you are working through
• a specific ask for input
• a missed goal and what changes next

Reply in the thread when you have context, evidence, a question, or a respectful disagreement. If the thread produces a decision, summarize it in #decisions and link back here.

Suggested cadence: one substantive post per week for cross-functional owners; otherwise post when useful.
```

### `#notebook-[name]` topic

> [Name]’s public internal notebook: goals, learning, current thinking, questions, and requests for input. Thinking aloud is welcome; final decisions are recorded in `#decisions` or the linked durable doc.

### Channel canvas or pinned charter

Add a small canvas tab or pin the notebook template. Slack supports canvases as formatted content attached to a channel tab; the template should explain the purpose, posting cadence, privacy boundary, and reply norms. See [Slack’s canvas documentation](https://slack.com/help/articles/203950418-Use-a-canvas-in-Slack).

## Posting protocol

### Post types

Put one label at the top of each post:

- `THINKING` — an unfinished view or hypothesis.
- `ASK` — specific input, evidence, introduction, or decision needed.
- `UPDATE` — what changed, shipped, was learned, or is blocked.
- `DECISION` — a decision already made; link to the durable record.
- `LESSON` — a reusable insight or mistake worth preserving.

### Reply protocol

- Reply in a thread to keep the main feed readable.
- Disagree with the claim, evidence, or tradeoff—not the person.
- Say what evidence would change your mind.
- Use a reaction for lightweight acknowledgement; do not turn every post into a meeting request.
- If a thread changes a decision, the owner posts a short close-the-loop summary.

### Privacy boundary

Public by default means “visible to Cranston teammates who are authorized to be in the workspace,” not “public on the internet.” Keep these out of public notebooks:

- customer confidential information, personally identifiable information, or unredacted meeting transcripts
- employee performance, compensation, health, or interpersonal matters
- credentials, API keys, security vulnerabilities, incident details, or sensitive architecture
- legal advice, litigation, financing discussions, or information subject to a confidentiality agreement
- unapproved claims about Cranston’s product, security, or customers that could be mistaken for an external commitment

When in doubt, ask in private, then move the generalizable conclusion to a safe public artifact.

## Six-week pilot

### Week 0: baseline and consent

Owner: founder/CEO, with one operations/admin partner if available.

- Explain the purpose and the “not a performance-review system” boundary.
- Ask each person what they want visible, what they consider sensitive, and how they prefer to receive notifications.
- Capture a baseline: recurring status pings, meetings held mainly for alignment, repeated questions, and a one-question psychological-safety pulse.
- Create the index, notebooks, and decision log link.

### Week 1: leaders go first

- Founder and any functional owners publish the first weekly post.
- Each post should include one real uncertainty or tradeoff, not only polished wins.
- The founder responds constructively to the first disagreement or correction.
- Do not ask everyone to read every channel; show how to follow selectively.

### Weeks 2–3: normalize contribution

- Invite non-owners to post ideas and lessons when useful.
- Link notebook posts to current project channels instead of duplicating work.
- Move final decisions and commitments into the durable decision log.
- Review whether the main feed is too long or whether channel names are hard to find.

### Weeks 4–5: add retrieval only if needed

- Try Slack search and saved items first.
- If the team wants an AI summary, begin with a narrow, read-only, human-reviewed use case such as “summarize this week’s notebook posts for the team.”
- Before adding an agent, define which channels it can read, whether it can write, who reviews outputs, how long data is retained, and how confidential content is excluded.

### Week 6: decide, adapt, or stop

- Run the scorecard in [`04-templates-and-pilot-scorecard.md`](./04-templates-and-pilot-scorecard.md).
- Keep, modify, consolidate, or stop based on information value minus reading cost.
- Record the decision in `#decisions` so the experiment itself becomes an example of the pattern.

## Slack implementation steps

1. Confirm the workspace is the correct Cranston workspace and identify the owner/admin who can create channels.
2. Create public channels using a consistent prefix such as `notebook-`; Slack recommends predictable names and channel topics/descriptions. See [Slack’s naming guidance](https://slack.com/help/articles/217626408-Create-guidelines-for-channel-names) and [channel creation](https://slack.com/help/articles/201402297-Create-a-channel).
3. Add a clear topic and purpose to every notebook.
4. Pin the charter/template or attach it as a canvas tab.
5. Set notifications to mention-only by default; each member can follow or mute selectively. Slack documents notification customization and catch-up tools [here](https://slack.com/help/articles/360058495594-Focus-on-what-matters-to-you).
6. Use threads for discussion. Surface a reply to the main channel only when the wider team benefits; Slack documents this thread behavior [here](https://slack.com/intl/en-gb/help/articles/115000769927-Use-threads-to-organise-discussions).
7. Do not restrict posting in notebooks. Restrict posting only in announcement channels where the goal is signal, not dialogue. Slack’s posting-permission documentation is [here](https://slack.com/help/articles/360004635551-Manage-channel-posting-permissions-).
8. Defer bots and custom API work. If the pattern sticks, Slack supports creating channels through [`conversations.create`](https://api.slack.com/methods/conversations.create), setting topics through [`conversations.setTopic`](https://api.slack.com/methods/conversations.setTopic), setting purposes through [`conversations.setPurpose`](https://api.slack.com/methods/conversations.setPurpose), and pinning through the [pins API](https://api.slack.com/methods/pins.list).

## Operating-model canvas

| Component | Cranston target state |
|---|---|
| Value proposition | Faster alignment and better decisions with less founder-dependent context transfer |
| Value chain | Think → share → challenge → decide → record → retrieve |
| Organization | Seven people with clear owners; notebooks follow people, project channels follow work |
| Governance | Public by default for ordinary work; one owner per notebook and one owner per decision |
| Information | Slack for the stream; decision log/Markdown/Notion for durable records; private systems for sensitive material |
| Suppliers/partners | Slack and any approved AI/search integrations, subject to access and retention review |
| Location | Async-first; synchronous discussion only when the written thread cannot resolve the issue efficiently |

## RACI for the pilot

| Activity | Founder/CEO | Notebook owner | Decision owner | Team | Slack/admin owner |
|---|---|---|---|---|---|
| Approve pilot purpose and boundaries | A/R | C | C | C | I |
| Maintain each notebook | I | A/R | I | C | I |
| Respond to material disagreement | C | C | A/R | C | I |
| Record a final decision | C | R | A | C | I |
| Maintain channel/index hygiene | A | C | I | I | R |
| Review pilot metrics and decide next state | A/R | C | C | C | C |

## Decision rules

- A notebook post is not automatically a company commitment.
- A `DECISION` post must link to the durable record or be copied into the decision log.
- A customer claim is not approved merely because it appeared in Slack.
- A disagreement is not resolved by silence; the owner should state the conclusion, the evidence, and whether the original view changed.
- If a channel creates more reading cost than useful context, reduce cadence before adding tooling.
