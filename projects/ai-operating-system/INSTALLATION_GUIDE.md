# Installation Guide

This is the complete installation procedure for:

- **Work computer:** Apple-silicon MacBook Pro M1.
- **Hermes computer:** Ubuntu on an Alienware laptop with an NVIDIA RTX 4070.
- **Canonical sync:** one private GitHub repository.
- **Local consumers:** Codex on macOS and Hermes on Ubuntu.
- **Web consumer:** ChatGPT Personal Skills, uploaded from generated ZIP packages.

The NVIDIA GPU is not required for this operating system when Hermes uses a hosted model provider. This installer does not modify NVIDIA drivers, CUDA, or local model runtimes. Add those only as a separate project after choosing a local-model architecture.

---

## Part 0 — Read the boundaries

Before installation, read:

- [`SECURITY_AND_DATA_HANDLING.md`](SECURITY_AND_DATA_HANDLING.md)
- [`GITHUB_SYNC_GUIDE.md`](GITHUB_SYNC_GUIDE.md)
- [`APPROVAL_POLICY.md`](APPROVAL_POLICY.md)

The private Git repository stores workflows, rules, tests, sanitized examples, and approved configuration. It must not store client documents, credentials, private SSH keys, or unredacted customer data.

---

## Part 1 — MacBook Pro setup

### 1. Extract the package

In Finder, unzip the downloaded archive into a durable location such as:

```text
~/AI/ai-operating-system
```

Avoid Desktop, Downloads, iCloud Drive, Dropbox, and Google Drive. GitHub is the sync mechanism; a second file-sync layer can corrupt `.git` state or create duplicate files.

Open Terminal and enter:

```bash
cd ~/AI/ai-operating-system
```

### 2. Inspect before executing

```bash
less SECURITY_AND_DATA_HANDLING.md
less scripts/bootstrap-macos.sh
python3 scripts/check_sensitive_content.py --all-files
```

### 3. Install prerequisites

```bash
./scripts/bootstrap-macos.sh
```

The script checks for Apple Command Line Tools, Homebrew, Git, Python, `gh`, and Codex. It shows each external installer command before asking permission to run it.

To install Codex manually using the current official standalone installer:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
codex
```

Choose **Sign in with ChatGPT** when Codex prompts you.

### 4. Authenticate GitHub interactively

```bash
gh auth login
```

Choose GitHub.com, HTTPS for interactive administration, and browser authentication. Then verify:

```bash
gh auth status
```

The background sync will not rely on your interactive `gh` session. It will use a repository-scoped SSH deploy key installed later.

### 5. Initialize and create the private repository

From the repository root:

```bash
./scripts/create-private-github-repo.sh YOUR_GITHUB_OWNER/ai-operating-system
```

This script:

- initializes Git if needed;
- runs validation and the sensitive-content scan;
- creates the first commit;
- creates a **private** GitHub repository; and
- pushes the approved baseline to `main`.

Review the displayed owner and repository name before confirming.

### 6. Install the Mac deploy key

```bash
./scripts/setup-repo-deploy-key.sh YOUR_GITHUB_OWNER/ai-operating-system macbook-pro
```

This creates a machine-specific Ed25519 SSH key in `~/.ssh/ai-os-macbook-pro`, uploads only the public key to that one repository with write access, and changes the Git remote to SSH.

The private key stays on the Mac and must never enter the repository.

### 7. Install Codex user skills

```bash
./scripts/install-local-skills.sh
```

This creates symlinks from every repository skill to:

```text
~/.agents/skills/<skill-name>
```

Codex reads user-level skills from `~/.agents/skills`. If a new skill does not appear immediately, restart Codex.

Verify:

```bash
find ~/.agents/skills -maxdepth 2 -name SKILL.md -print
codex
```

Inside Codex, run `/skills` or type `$work-auditor`.

### 8. Install automatic Git sync on macOS

```bash
./scripts/install-auto-sync-macos.sh
```

This installs a per-user LaunchAgent that runs every five minutes and at login. Logs live at:

```text
~/Library/Logs/ai-operating-system-sync.log
```

Verify:

```bash
launchctl print gui/$(id -u)/com.ai-operating-system.sync
./scripts/ai-os-sync.sh --dry-run
```

---

## Part 2 — Ubuntu / Hermes setup

### 1. Install base prerequisites

On Ubuntu, open Terminal:

```bash
sudo apt update
sudo apt install -y git curl xz-utils ca-certificates openssh-client python3 python3-venv jq
```

Install GitHub CLI using the current official GitHub instructions if `gh` is not already present. You only need `gh` temporarily to register the Ubuntu deploy key; normal sync uses SSH and Git.

### 2. Create the Ubuntu repository deploy key before cloning

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "ai-os-ubuntu-hermes" -N "" -f ~/.ssh/ai-os-ubuntu-hermes
cat ~/.ssh/ai-os-ubuntu-hermes.pub
```

On the Mac, register that public key:

```bash
gh repo deploy-key add /path/to/copied/ubuntu-public-key   --repo YOUR_GITHUB_OWNER/ai-operating-system   --title "ai-os-ubuntu-hermes"   --allow-write
```

Alternatively, add it in GitHub repository **Settings → Deploy keys → Add deploy key**, selecting **Allow write access**.

Create an SSH host alias on Ubuntu:

```bash
cat >> ~/.ssh/config <<'EOF'
Host github-ai-os
  HostName github.com
  User git
  IdentityFile ~/.ssh/ai-os-ubuntu-hermes
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
# GitHub's published Ed25519 host key and fingerprint:
# SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
GITHUB_HOST_KEY='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
grep -Fqx "$GITHUB_HOST_KEY" ~/.ssh/known_hosts 2>/dev/null || printf '%s\n' "$GITHUB_HOST_KEY" >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
```

Test and clone:

```bash
ssh -T git@github-ai-os
mkdir -p ~/AI
cd ~/AI
git clone git@github-ai-os:YOUR_GITHUB_OWNER/ai-operating-system.git
cd ai-operating-system
```

### 3. Run the Ubuntu bootstrap

```bash
./scripts/bootstrap-ubuntu.sh
```

The script verifies dependencies and offers the official Hermes installer:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

Reload the shell if needed:

```bash
source ~/.bashrc
```

### 4. Configure a Hermes provider

Recommended lowest-friction setup:

```bash
hermes setup --portal
```

This opens an OAuth flow. For a remote/headless machine, use the SSH port-forwarding flow documented by Hermes or complete setup from a local browser connected to the machine.

Verify:

```bash
hermes doctor
hermes
```

### 5. Install the shared skills and Hermes config

```bash
./scripts/install-local-skills.sh
python3 scripts/configure-hermes.py --apply
```

The configuration script:

- backs up `~/.hermes/config.yaml`;
- adds this repository’s `skills/` directory to Hermes `skills.external_dirs`;
- enables skill-write approval; and
- leaves secrets and provider settings untouched.

Review:

```bash
python3 scripts/configure-hermes.py --check
hermes skills list
```

### 6. Install the Hermes gateway as a user service

```bash
hermes gateway install
systemctl --user status hermes-gateway.service --no-pager || true
```

To keep the user service available after logout on Ubuntu:

```bash
sudo loginctl enable-linger "$USER"
```

Use a dedicated, non-root user. Do not run the operating system under `/root` unless you intentionally accept root-level file and command access.

### 7. Install the approved Hermes schedules

```bash
./scripts/install-hermes-cron.sh
```

The installer creates or updates these jobs in America/Los_Angeles time:

| Job | Schedule | Skill |
|---|---:|---|
| Daily work audit | 12:00 AM every day | `work-auditor` daily, 24 hours |
| Weekly work audit | 12:00 AM Friday | `work-auditor` weekly, 168 hours |
| Morning brief | 6:00 AM every day | `day-operator` brief |
| End-of-day review | 6:00 PM every day | `day-operator` review |

The jobs run with the repository as their absolute `--workdir`, so Hermes loads the repository context and can write only permitted artifacts.

Verify:

```bash
hermes cron list
hermes cron status
```

Run a dry acceptance test manually before trusting unattended execution:

```bash
hermes cron list
# Use the displayed job ID:
hermes cron run JOB_ID
```

### 8. Install Ubuntu automatic Git sync

```bash
./scripts/install-auto-sync-ubuntu.sh
```

This installs a systemd **user** timer, not a root system service.

Verify:

```bash
systemctl --user status ai-operating-system-sync.timer --no-pager
systemctl --user list-timers --all | grep ai-operating-system
journalctl --user -u ai-operating-system-sync.service -n 100 --no-pager
```

---

## Part 3 — ChatGPT web installation

Generate upload packages:

```bash
./scripts/package_skills.py
```

Open ChatGPT web and follow [`CHATGPT_WEB_INSTALL.md`](CHATGPT_WEB_INSTALL.md).

GitHub does not automatically replace an uploaded ChatGPT Personal Skill. Treat web upload as release promotion:

1. review the pull request or approved commit;
2. run validation;
3. generate the ZIP;
4. upload it to ChatGPT; and
5. record the promoted version in `state/web-skill-releases.json`.

---

## Part 4 — Connector rollout

Follow [`CONNECTOR_SETUP.md`](CONNECTOR_SETUP.md). The recommended sequence is:

1. Notion read-only, then approved writes.
2. Google Calendar read-only.
3. Gmail read and automatic drafts; sends stay approval-required.
4. Attio read-only, then approved writes.
5. Circleback read-only.
6. Slack draft first; posting stays approval-required.

No adapter may claim an action succeeded until it reads the target back and verifies the intended state.

---

## Part 5 — First-week acceptance plan

Day 1:

- Run all jobs manually with writes disabled.
- Review sources, routing, missing connector behavior, and sensitive-data scanner results.

Days 2–3:

- Enable Notion writes only for a test page/database.
- Confirm semantic duplicate checks and read-after-write verification.

Days 4–5:

- Use the real morning brief with all external writes still staged or approval-gated.
- Record Useful, Wrong, Missing, and free-text feedback.

After five consecutive reviewed runs without a material correction, a low-risk operation may be **proposed** for autonomy. Promotion still requires an explicit approval record scoped to the exact skill, service, operation, and risk class.
