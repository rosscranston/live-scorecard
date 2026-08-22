# Evidence dossier: Anthropic notebook channels

## How to read this dossier

This is a source review, not a claim that Anthropic has published a complete playbook. Each finding is tagged:

- **Confirmed** — directly stated by Anthropic or Slack in an official source.
- **Reported** — attributed to a named Anthropic employee or a transcript/article describing their remarks.
- **General evidence** — research about enterprise social media, transparency, knowledge sharing, or psychological safety; not evidence that Anthropic’s notebooks caused a specific outcome.
- **Cranston inference** — a recommendation derived from the evidence and Cranston’s seven-person scale.

## 1. Notebook-specific evidence

### Ami Vora: weekly goals and thinking in public

**Status: Reported; medium confidence.**

The public account of Ami Vora’s Salesforce event says Anthropic uses open Slack channels called “notebooks,” that employees can subscribe, and that Vora writes weekly goals, reviews how she did against the previous week, shares product-direction thinking, and flags where teams need clarity. The report attributes participation to every level of leadership and function.

Source: [Anthropic Makes Leaders Write in Public](https://www.implicator.ai/anthropic-makes-leaders-write-in-public-the-ones-who-resist-tell-you-everything-2/).

Important limitation: this is a secondary report of a public event, not an Anthropic-authored policy. It supports the existence and broad purpose of the practice, but not the exact channel naming, permissions, cadence enforcement, or compliance rate.

### Amol Avasare: personal internal feeds and public challenge

**Status: Reported; medium-to-high confidence.**

In the Lenny’s Podcast material, Avasare describes notebook channels as personal internal feeds, similar to a Twitter feed, where employees share thoughts and provocative ideas. He describes employees publicly challenging leadership and gives an example of an employee responding to Dario Amodei’s notebook after disagreeing with a comment.

Sources: [Lenny’s Podcast episode page](https://www.lennysnewsletter.com/p/anthropics-1b-to-19b-growth-run), [transcript-based summary with timestamp and quotation](https://www.teahose.com/podcast/Lenny%27s/Anthropic%27s%20%241B%20to%20%2419B%20growth%20run_%20how%20Claude%20became%20the%20fastest-growing%20AI%20product%20in%20history%20_%20Amol%20Avasare), and [Mint’s report of the same discussion](https://www.livemint.com/technology/tech-news/argue-with-dario-anthropics-head-of-growth-says-claude-maker-lets-employees-call-out-its-ceo-publicly-11775451579833.html).

The useful operating insight is not “be confrontational.” It is: make disagreement visible, specific, and close to the reasoning it challenges; then let the leader respond where everyone can learn.

### Scope conflict: leaders, many employees, or everyone?

**Status: Unresolved; low-to-medium confidence on exact scope.**

Public descriptions are inconsistent. Vora’s reported account says every level of leadership and function. Avasare is widely summarized as saying everyone has a notebook, while one published report also quotes wording that not everyone has one. Some secondary accounts assert that every employee, including the CEO, has a personal channel. The public evidence does not establish whether notebooks are universal, role-based, voluntary, or a mix.

**Conclusion:** describe Anthropic as using a broad personal-notebook pattern, including leadership, rather than claiming a verified universal mandate.

### The “AI context” interpretation

**Status: Reported/inferred; medium confidence.**

Some transcript summaries and articles argue that notebook content helps Claude model a leader’s thinking or provide management-style feedback. The strongest official evidence is broader: Anthropic says agents depend on searchable Slack, docs, code, and meeting notes; it recommends public-by-default communication and searchable decision artifacts. That supports the idea that notebook channels can become useful context for AI, but it does not prove that Anthropic’s notebook channels were designed primarily for AI retrieval or that a particular agent was trained on them.

Sources: [Anthropic’s human-agent-team guidance](https://claude.com/blog/building-effective-human-agent-teams), [TeaHose summary of the Avasare episode](https://www.teahose.com/podcast/Lenny%27s/Anthropic%27s%20%241B%20to%20%2419B%20growth%20run_%20how%20Claude%20became%20the%20fastest-growing%20AI%20product%20in%20history%20_%20Amol%20Avasare), and [AINEXT’s transcript-based article](https://ain3xt.com/en/posts/20260503-amol-avasare-anthropic-notebook-channels-career/).

## 2. Anthropic’s broader operating context

### Public-by-default communication and searchable decisions

**Status: Confirmed.**

Anthropic’s official human-agent-team article says its teams share information proactively and openly, recommends choosing clear security boundaries, defaulting new communication channels to public internally, and ensuring decisions land in channels, docs, and meeting notes. It gives the rationale that agents cannot use private or undocumented context and that public searchable context helps both people and agents discover relevant prior work.

Source: [Lessons from Anthropic on building effective human-agent teams](https://claude.com/blog/building-effective-human-agent-teams), especially the section “Lesson 1: Work in public and give agents broad context.”

This is the strongest source for the “why now” argument, but it is about human-agent teams broadly, not a notebook-channel implementation guide.

### Slack as an operating layer

**Status: Confirmed as Anthropic/Slack marketing claims; medium confidence for causal claims.**

Anthropic’s Kate Jensen is quoted in a Salesforce interview describing Slack as the company’s central nervous system and source of truth as it grew globally. Slack’s customer story describes Slack as an operational pillar, references the `#anthropic-times` Claude briefing channel, and says Anthropic considered compartmentalization, admin controls, and eDiscovery when integrating Claude.

Sources: [Salesforce+ interview with Anthropic](https://www.salesforce.com/plus/experience/dreamforce_2025/series/slack_salesforce_starts_here_at_dreamforce_2025/episode/episode-s1e2?bc=OTH) and [Slack’s Anthropic customer story](https://slack.com/customer-stories/anthropic-story).

Do not treat vendor-reported savings, deal-cycle improvements, or “10x” output as an independently verified effect of notebooks. They describe a broader Slack/AI operating environment.

### Public goals as a forcing function

**Status: Confirmed in a different Anthropic practice; useful analogy, not notebook evidence.**

Anthropic’s Frontier Safety Roadmap says publishing goals creates a forcing function for company-wide coordination, and that Anthropic will provide updates on whether goals are achieved and set new goals when appropriate. This is public-facing safety governance, not internal Slack. It nevertheless supports the general design principle that visible goals plus visible follow-up can coordinate work.

Source: [Anthropic’s Frontier Safety Roadmap](https://www.anthropic.com/responsible-scaling-policy/roadmap).

## 3. Slack implementation evidence

### There is no special Notebook feature in the public Slack documentation

**Status: Confirmed by available documentation; high confidence.**

Slack documents ordinary public/private channels, names, topics, descriptions, posting permissions, threads, canvases/tabs, saved messages, and optional workflows. The Anthropic pattern can therefore be implemented with normal Slack primitives.

Key sources:

- [Create a channel](https://slack.com/help/articles/201402297-Create-a-channel) — create a public or private channel.
- [Create guidelines for channel names](https://slack.com/help/articles/217626408-Create-guidelines-for-channel-names) — use predictable names, topics, and descriptions.
- [Use threads to organise discussions](https://slack.com/intl/en-gb/help/articles/115000769927-Use-threads-to-organise-discussions) — keep replies attached to the post and optionally surface a reply back in the channel.
- [Use a canvas in Slack](https://slack.com/help/articles/203950418-Use-a-canvas-in-Slack) — add a channel tab for a charter, recurring template, or overview.
- [Manage channel posting permissions](https://slack.com/help/articles/360004635551-Manage-channel-posting-permissions-) — ordinary channels can allow all members to post; posting can be restricted when appropriate.
- [Focus on what matters](https://slack.com/help/articles/360058495594-Focus-on-what-matters-to-you) — members can customize notifications, use reminders, and use Slack’s catch-up tools.

### Optional API and workflow automation

**Status: Confirmed technical capability; not required for the pilot.**

Slack’s API can create public or private channels through [`conversations.create`](https://api.slack.com/methods/conversations.create), set a topic through [`conversations.setTopic`](https://api.slack.com/methods/conversations.setTopic), set a purpose through [`conversations.setPurpose`](https://api.slack.com/methods/conversations.setPurpose), and pin messages through the [pins API](https://api.slack.com/methods/pins.list) / Slack functions. For seven people, use Slack’s UI first; automate only after the norms work manually.

## 4. General research on the mechanisms

### Visibility can improve knowledge transfer and agility

**Status: General evidence; not Anthropic-specific.**

An open-access study of enterprise social media in China and the United States found that message transparency and network translucence were positively associated with employee agility, with knowledge provision mediating the relationship in both samples. This is directionally consistent with a notebook pattern: people can see what others know and who is working on what.

Source: [Investigating visibility affordance, knowledge transfer and employee agility performance](https://www.sciencedirect.com/science/article/pii/S0166497223001852).

### Visibility can make complex knowledge easier to share

**Status: General evidence; not Anthropic-specific.**

Research on enterprise social-media affordances reports that visibility eases sharing of domain-specific knowledge, while association and editability help with complex knowledge.

Source: [Affordances for sharing domain-specific and complex knowledge on enterprise social media](https://www.sciencedirect.com/science/article/pii/S0268401218300446).

### Transparency can support creativity, but the network can also encourage hiding

**Status: General evidence; not Anthropic-specific.**

A study of 208 enterprise-social-media users found message transparency positively related to knowledge sharing and knowledge sharing positively related to creativity; network translucence was positively related to both knowledge sharing and knowledge hiding. The implication is that visibility alone is not enough: the social meaning of visibility matters.

Source: [Integrating the bright and dark sides of communication visibility](https://rrice.faculty.comm.ucsb.edu/a148.htm).

### Visibility and usage can produce overload and strain

**Status: General evidence; not Anthropic-specific.**

Research links enterprise-social-media visibility and usage to information overload, social overload, work stress, exhaustion, and reduced well-being. This is the principal counterweight to “make everything public.”

Sources: [Investigating the factors of enterprise social media strain](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0264726), [Mitigating perceived overload of communication visibility](https://www.sciencedirect.com/science/article/pii/S1066224323000540), and [How enterprise social media use affects employee well-being](https://www.nature.com/articles/s41598-026-52766-3).

### Psychological safety is enacted by leader behavior

**Status: General evidence; contextual limitation.**

Research consistently treats psychological safety as a condition for voice and learning. A recent qualitative study emphasizes leader openness, accessibility, responsiveness, predictable feedback, and non-punitive reactions; it also cautions that the study is context-specific and not universally generalizable.

Source: [The role of leadership in shaping psychological safety](https://www.nature.com/articles/s41598-026-38706-1).

The Cranston implication is concrete: a founder who says “challenge me” but reacts defensively will train the team to stop posting. Public notebooks magnify the leader’s response pattern.

## 5. Evidence-to-design map

| Evidence | Design implication for Cranston |
|---|---|
| Weekly goals and review | Require a short weekly post, not daily journaling |
| Public disagreement builds trust | Explicitly label disagreement as welcome; require reasons and a close-the-loop response |
| Public searchable context helps agents and humans | Make routine work public, but keep a durable decision log and clear access boundaries |
| Visibility can improve transfer | Let people follow selectively; create an index so discovery is easy |
| Visibility can cause overload | Mention-only notifications by default; keep posts short; use threads |
| Psychological safety depends on reactions | Founder posts first, admits misses, thanks dissenters, and records when a view changes |
| Slack has ordinary channel primitives | Start with UI configuration; defer custom automation |
| Anthropic’s exact scope is unclear | Pilot participation rather than declaring a universal mandate |

