# Start Here

This guide is the shortest safe path from the downloaded package to a synchronized two-computer installation.

## What you need

- Your MacBook Pro M1 with administrator access.
- The Ubuntu user account that will run Hermes on the Alienware computer.
- A GitHub account able to create a private repository.
- Your ChatGPT Pro account and access to the Skills upload interface.
- A model/provider configuration for Hermes. The included guide uses the official `hermes setup --portal` path, but you may choose another supported provider.

## Installation order

### 1. Establish the canonical repository on the Mac

Unzip the package, open Terminal in the extracted folder, and run:

```bash
./scripts/bootstrap-macos.sh
./scripts/create-private-github-repo.sh OWNER/ai-operating-system
./scripts/setup-repo-deploy-key.sh OWNER/ai-operating-system macbook-pro
./scripts/install-local-skills.sh
./scripts/install-auto-sync-macos.sh
```

Replace `OWNER` with your GitHub username or organization. The repository creation script pauses before creating or pushing anything and requires you to confirm the private repository name.

### 2. Clone and configure the Ubuntu/Hermes computer

On Ubuntu:

```bash
./scripts/bootstrap-ubuntu.sh
# Follow GITHUB_SYNC_GUIDE.md to clone using the Ubuntu deploy key.
./scripts/install-local-skills.sh
./scripts/configure-hermes.py --apply
./scripts/install-hermes-cron.sh
./scripts/install-auto-sync-ubuntu.sh
```

The deploy key setup is intentionally a two-part procedure because the Ubuntu machine needs repository access before it can run repository scripts. Follow the exact sequence in [`GITHUB_SYNC_GUIDE.md`](GITHUB_SYNC_GUIDE.md).

### 3. Upload the skills to ChatGPT web

Run:

```bash
./scripts/package_skills.py
```

Then follow [`CHATGPT_WEB_INSTALL.md`](CHATGPT_WEB_INSTALL.md). Start by uploading the critical foundation skills:

1. `work-auditor`
2. `chat-router`
3. `agent-architect`
4. `workspace-operator`
5. `day-operator`
6. `meeting-lifecycle`
7. `call-capture`
8. `knowledge-curator`

The remaining coaching and enablement skills are included and may be uploaded immediately, but they are not dependencies for the first automated run.

### 4. Configure connectors

No local connectors were assumed. Follow [`CONNECTOR_SETUP.md`](CONNECTOR_SETUP.md) one service at a time. Keep writes behind approval until each adapter passes its acceptance tests.

### 5. Validate

Run on both machines:

```bash
./scripts/doctor.sh
python3 scripts/validate_repo.py
./scripts/ai-os-sync.sh --dry-run
```

On Ubuntu also run:

```bash
hermes doctor
hermes cron list
hermes cron status
```

## What automatic sync means

Every five minutes, each machine:

1. checks for forbidden or protected local changes;
2. fetches the private GitHub repository;
3. rebases clean local commits on the remote branch;
4. pushes only when the repository is conflict-free; and
5. writes a local log.

It never force-pushes, automatically resolves a merge conflict, pushes secrets, or approves a protected production change.
