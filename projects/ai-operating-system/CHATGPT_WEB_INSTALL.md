# ChatGPT Web Installation

## Package the skills

From either computer:

```bash
./scripts/package_skills.py
```

The command creates one ZIP per skill under:

```text
dist/chatgpt-skills/
```

It also creates `dist/chatgpt-skills-all.zip` for archival convenience. Upload individual skill ZIPs to make review, versioning, and replacement easier.

## Upload

In ChatGPT web:

1. Open **Plugins** in the sidebar.
2. Open the **Skills** tab.
3. Select **Create**.
4. Select **Upload from your computer**.
5. Choose one generated skill ZIP.
6. Review the scanner result and the included files.
7. Keep access private to you during rollout.
8. Repeat for the required skills.

## Initial upload order

1. `work-auditor`
2. `chat-router`
3. `agent-architect`
4. `workspace-operator`
5. `day-operator`
6. `meeting-lifecycle`
7. `call-capture`
8. `knowledge-curator`
9. `demo-coach`
10. `tax-translator`
11. `pilot-planner`
12. `team-update`

## Invocation

Skills begin explicit-only:

```text
@work-auditor Run the daily business-work audit for the prior 24 hours.
@day-operator Build today's approved morning brief.
@agent-architect Decide where each part of this workflow should run.
```

## Release synchronization limitation

Personal Skills uploaded into ChatGPT are copies of the uploaded release. They are not a live checkout of your GitHub repository. Git automatically synchronizes Mac and Ubuntu, but ChatGPT web requires a deliberate re-upload when you approve a new release.

Use this promotion procedure:

1. merge or approve the repository change;
2. run `python3 scripts/validate_repo.py`;
3. run `./scripts/package_skills.py`;
4. upload the changed ZIP;
5. verify the displayed version; and
6. update `state/web-skill-releases.json` with the promoted commit hash and date.

This manual promotion prevents an overnight agent from silently changing the instructions used in ChatGPT web.
