# GitHub Sync Guide

## Recommended model

Use one **private** GitHub repository as the canonical source. Each computer has:

- its own working copy;
- its own repository-scoped SSH deploy key;
- the same `main` branch;
- a five-minute per-user sync job; and
- machine-local credentials and logs that are never committed.

## Why deploy keys

A deploy key grants one machine access to one repository. This is narrower than storing a broad personal GitHub token for unattended sync. Write-enabled deploy keys are still powerful and are commonly unencrypted on disk, so treat the computer account and key file as sensitive.

GitHub notes that deploy keys added through `gh` are associated with the current GitHub CLI authentication token and may be removed if that authorization is revoked. After changing GitHub authentication, verify both deploy keys with `gh repo deploy-key list`. For a future multi-repository or larger team deployment, prefer a GitHub App with tightly scoped installation permissions.

## Mac: create the repository

```bash
gh auth login
./scripts/create-private-github-repo.sh OWNER/ai-operating-system
./scripts/setup-repo-deploy-key.sh OWNER/ai-operating-system macbook-pro
```

## Ubuntu: create and register a second key

On Ubuntu:

```bash
ssh-keygen -t ed25519 -C "ai-os-ubuntu-hermes" -N "" -f ~/.ssh/ai-os-ubuntu-hermes
cat ~/.ssh/ai-os-ubuntu-hermes.pub
```

On the Mac, save the displayed public key to a temporary file and run:

```bash
gh repo deploy-key add /tmp/ubuntu-ai-os.pub   --repo OWNER/ai-operating-system   --title ai-os-ubuntu-hermes   --allow-write
rm /tmp/ubuntu-ai-os.pub
```

Only the public key is copied. Never copy `~/.ssh/ai-os-ubuntu-hermes` off the Ubuntu computer.

## Sync algorithm

`scripts/ai-os-sync.sh` uses this sequence:

1. acquire a machine-local lock;
2. verify it is on `main` and has a configured `origin`;
3. run the sensitive-content and repository validators;
4. inspect uncommitted changes;
5. refuse automatic commit when protected paths changed;
6. create a normal commit for allowed sanitized changes;
7. `git fetch origin main`;
8. rebase local commits onto `origin/main` only if clean;
9. stop on any conflict;
10. `git push origin main` without force; and
11. write an audit log.

## Protected paths

Automatic sync does not commit changes to:

- production `SKILL.md` files;
- `config/approval-policy.yaml`;
- `config/shared-settings.yaml` source-ownership or permissions sections;
- connector adapter implementations;
- GitHub workflow permissions;
- security policy and scanner code; or
- approval records.

Use `approve-and-sync.sh` after reviewing and approving a proposal.

## Conflict handling

When a conflict occurs:

1. automatic sync stops;
2. do not run another sync loop repeatedly;
3. open the repository on one computer;
4. inspect `git status` and the conflicting files;
5. resolve deliberately;
6. run validation and tests;
7. commit the resolution; and
8. run `./scripts/ai-os-sync.sh` manually.

The system never chooses “Mac wins” or “Ubuntu wins” automatically because either machine may contain the more recent human judgment.

## Repository settings

Recommended on GitHub:

- visibility: Private;
- default branch: `main`;
- enable vulnerability and secret scanning if available;
- disallow force pushes;
- require a pull request before merging once teammates are added;
- require the Validate workflow; and
- review deploy keys quarterly and whenever a device changes ownership.
