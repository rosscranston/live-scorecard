# Requirements Questionnaire

Known decisions have been carried forward and are not repeated here. These are the unresolved questions that materially affect project organization, skill boundaries, permissions, and production behavior.

## A. Audit scope and project organization

1. For recurring audits, should “the previous week” mean the rolling seven full days ending yesterday, Monday–Sunday of the prior calendar week, or another fixed window?
- There should be two options, one that does this on a daily basis for the previous 24 hours, so I can run it on an automation that kicks off at midnight every day on my Hermes computer and other locations. 
- The second should be a larger weekly view and should be the previous 7 days of 168 hours from when it runs, so I can also run this on a weekly automation on Friday at midnight. 
2. Should the organizer include personal/non-Cranston chats in its audit, or classify only business work unless explicitly asked?
- Classify only business work unless asked. If a project looks personal like renting a rental car, but could also be helpful for a conference or work event, include it. 
3. Do you want one shared **Quick Questions & Technical Setup** project, or should one-offs remain outside Projects and only appear in an index?
- I want to onboard future employees faster to Cranston, even if I only have to set something up once personally, I would like it included in an "onboarding" project or skill that can help a future employee quickly identify and execute all required onboarding steps. 
4. After what period should inactive one-off chats become archive candidates: 30, 60, 90 days, or never automatically?
- 30 days
5. May a conversation be moved automatically after you approve the routing policy, or should every move remain individually approved?
- Moved automatically
6. Should the organizer propose standardized chat titles? If yes, which pattern do you prefer: `Project | Outcome | Date`, `Date | Project | Outcome`, or another pattern?
- Yes, rename chats by "project | outcome |date"
7. For a conversation spanning two projects, do you prefer one primary home plus tags/cross-links, or a summary copied into the secondary project?
- 1 home with tags/cross-links, don't duplicate
8. Should superseded chats remain visible in their original project with a “Superseded by” reference, or move to a dedicated Archive project?
- Can you give me an example here of when this would occur so I can answer better? 
9. Is there a maximum number of durable ChatGPT Projects you want visible in the sidebar?
- Not at this time, I may put a limit if the sidebar becomes crowded. 

## B. Skill catalog and versioning

10. Do you prefer fewer broad skills or more narrowly scoped skills when both can be made reliable?
- Broad skills that are comprised of narrow skills, I like modular components that can be rearranged across multiple workflows. 
11. Should a workflow normally need two occurrences before becoming a skill, or may one high-value/high-risk occurrence be enough?
- 1 high value workflow can be enough to warrant a skill. I just need to know what skills are available so I use them again. 
12. Which of the 12 proposed skills are essential for the first release, and which may wait?
- 1,2,11,12 are critical. Then 3-6 are required built on top of that, 7-9 are good ideas but could wait. 
13. Should skills trigger automatically when descriptions match, or start as explicit-only invocations until you trust them?
- Start with explicit invocations, but also suggest which skills I should be using at the beginning of output if I could have used a skill that I've forgotten. Have the abiltiy to switch over to implicit invocation. 
14. Should business skills be allowed to invoke the shared `cranston-workspace-operator`, or should each skill stop with an action proposal that you manually pass forward?
- Start by requiring an action proposal, and allow me to remove the action proposal for specific skills as they are deemed trustworthy. 
15. Where should the canonical skill repository live: a local Git folder, Google Drive, Notion, another repository, or more than one with a designated source of truth?
- A local Git folder, but I also want my web based version of GPT to be able to see them if possible. The git folder should be synced between my Hermes computer, and my daily driver computer. 
16. Who besides you may edit, approve, or install these skills?
- No one at the moment, eventually I would like this operating system to be usable by a team of other sales professionals on my team, so eventually there will need to be rules for access control and making sure skills proposed by others don't collide with mine, but nothing yet. 
17. What versioning policy do you want: semantic versions such as `1.2.0`, dated versions, or both?
- 1.2.0
18. Should every skill maintain a changelog and decision log, or only high-risk business skills?
- Every skill
19. How often should the skill catalog be reviewed: daily, weekly, after every call, or only when a failure/new pattern appears?
- Daily
20. Do you want instruction-only skills first, or should deterministic scripts be added immediately where they can validate schemas, deduplicate records, or generate manifests?
- Add deterministic scripts immediately like how to prevent writing duplicate notion cards.

## C. ChatGPT web and Codex local environment

21. Which ChatGPT workspace/plan will host the web skills, and do you currently see the Skills/Plugins area with the ability to upload a skill?
- ChatGPT Pro plan, and yes I see the skills area
22. Which operating system and local path should hold Codex user-level skills?
- Codex will be used on my Macbook Pro 2021 M1 Pro Max with OS 26.5.2 and My hermes computer will be using Ubuntu on my Alienware laptop
23. Will Codex run inside one Cranston repository/folder, or across many unrelated folders?
- Please outline a few scenarios to help me better answer this question. 
24. Which local connectors or MCP servers are already configured for Notion, Attio, Circleback, Gmail, Google Calendar, Slack, and Google Drive?
- None, they all need to be configured. 
25. Should local Codex ever handle raw client tax documents, or should those workflows remain in approved cloud systems only?
- Remain in approved cloud systems only
26. When a web connector exists but no local connector exists, should the skill create an import-ready action queue, hand off to ChatGPT web, or stop and ask you to choose?
- Stop and ask me to choose, explain to me what is going on, as I may be able to find a local connector. 
27. Do you want a single shared settings file for system IDs, database names, folder paths, and naming rules, with secrets kept elsewhere?
- Yes

## D. Approval and action policy

28. For each action below, choose the default level: read automatically, draft automatically, write after approval, or autonomous after a trial period:
   - Search/read Circleback calls.read automatically
   - Create or update Notion records.autonomous after a trial period
   - Create or update Attio records.autonomous after a trial period
   - Draft email.draft automatically
   - Send email.write after approval
   - Create or update Calendar events.write after approval
   - Post to Slack.write after approval
   - Move or rename ChatGPT conversations.autonomous after a trial period
   - Archive or delete any record.write after approval
29. During initial rollout, should approval be one action at a time, one system at a time, one meeting at a time, or one daily batch? What do you suggest? 
30. What evidence should appear beside an approval button or proposal: source quote, source link, before/after value, reason, confidence, or all of these? All of these. 
31. Should the system ever make a write when a target record is ambiguous, or must ambiguity always enter an exception queue?
- Ambiguity should trigger an exception if below a confidence threshold. Confidence can increase over time once the exception is resolved, for future similar events. 
32. May a skill correct obvious spelling mistakes automatically, or should it preserve source wording and suggest the correction separately?
- Correct spelling automatically. 
33. Which actions are permanently prohibited from autonomous execution even after the workflow proves reliable?
- I don't know, make a suggestion for me to approve. 

## E. Business judgment and knowledge maintenance

34. When two calls conflict, what should win: the most recent call, an explicit written policy, a named owner’s statement, or a manual decision?
- A manual decision for now, likely the most recent call in the future as the product will evolve, but also differnet prospects may be given differnet answers based on their situation and liklinesss to buy, context will be a big thing to understand why something was said. 
35. For exact quotes, should the library store every useful quote or only the strongest canonical wording for each question/step?
- Every useful quote for now, and roll them up into the master canolical quote. 
36. How close must two entries be before they count as duplicates: exact text, same normalized term/question, or same business meaning?
- Same normalized term/meaning. There are multiple cards in the FAQ for "how much does it cost" these should likely all be in the same card. 
37. When a newer answer improves an FAQ, should it replace the prior answer, become the new default while preserving history, or remain as an alternative by scenario?
- Preserve the answer history, and include the new answer in the same notion card. 
38. Should low-confidence tax/accounting definitions be researched from authoritative sources before entering the Terms database, or added as “Needs verification” drafts?
- Yes the definitions should be researched from authoritative sources first
39. Who is the source of truth for product capabilities, security claims, supported integrations, pricing, and roadmap dates?
- I don't know, this is something that needs to be coordinated with Sean and Max and a source of truth created. 
40. Should the demo coach proactively warn you before using an unverified claim, or only flag it in post-answer feedback?
- Flag it in post answer feedback
41. For security questions, should the skill continue the current practice of answering succinctly and not volunteering AI-specific security details unless asked?
- yes
42. What types of sales or tax statements require escalation to engineering, product, legal, security, or a CPA before use?
- make a suggestion for me to approve
43. Should the knowledge curator preserve all historical direct quotes, even when they are no longer recommended, in a hidden/audit section?
- yes, in a dropdown

## F. Daily workflow and communication

44. What exact time should the morning brief run, and how far before the first meeting must it be ready?
- 6am, it should be ready by 8am at the latest
45. Where should the final morning brief live by default: ChatGPT Project, Notion Daily Journal, Slack DM/channel, email, or a combination with one source of truth?
- notion daily journal, much of this was determined yesterday, use those findings
46. What exact time or trigger should start the end-of-day review?
- 6pm, if there are any calls after that it can be included in the next day. I want the review completed in time for me to read through it before I end my workday. 
47. Should the end-of-day workflow update the living FAQ, Terms, and Meeting Agenda automatically from that day’s completed calls, or merely propose changes for approval?
- update automatically
48. What are the mandatory sections of a morning brief beyond meetings, prior notes, research, and topics needed to reach the next step?
- All the secitons are discussed her https://chatgpt.com/c/6a7fba3f-38f0-83e8-9e45-a885d2ea8226
49. What are the mandatory sections of the end-of-day report beyond completed work, learning, outcomes, blockers, and tomorrow’s priorities?
- I don't know yet, similar to https://chatgpt.com/c/6a7fba3f-38f0-83e8-9e45-a885d2ea8226 we should have a conversation about what is the most helpful to include. 
50. Which Slack channel or audience should receive the team-visibility update, and should it be a draft or posted after approval?
- Draft it in my notebook slack channel "ross-notebook" we can create this if it doesn't already exist. 

## G. Quality, testing, and rollout

51. Which three conversations from the audited week should serve as the first acceptance-test set?
- Explain what this means? Do I need to pick the best three client calls? 
52. What would make you say a skill is “working correctly” after the first week: time saved, fewer missed topics, cleaner CRM, stronger demos, fewer duplicate records, or specific measurable thresholds?
- Time saved, and stronger sales calls, faster integration of learnings from calls into call materials, and being able to surface and learn those faster, recording is not the same as me personally knowing the information I need to say on a call. I need a system that helps me act better in the moment. 
53. How many successful approved runs should occur before a low-risk write can become autonomous?
- make a suggestion
54. Should failed or corrected outputs be retained as training examples in the skill’s test suite?
- They should be retained as examples of what not to do, and the corrections as examples of what to do. There should be a way the system collects feedback on every output and continuously improves the skills with my feedback. 
55. Do you want a weekly scorecard for skill usage, failures, overrides, time saved, and newly discovered rules?
- yes
56. What is the preferred fallback when a skill is uncertain: ask one targeted question, produce a best-effort draft with warnings, or stop without output?
- Ask me a targeted question
57. Should the final ZIP include installation scripts for Codex, or only portable folders plus manual installation instructions?
- Yes, include instructions for Codex to install it. 
58. Do you want the first release optimized only for your use, or structured from the beginning for teammates to install and use safely?
- Structure for teammates to use, we will be a very fast growing organization. 

