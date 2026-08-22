# AI Operating System

Version **1.0.0** — approved baseline plus deployable Mac, Ubuntu/Hermes, GitHub, Codex, and ChatGPT packaging.

This repository is the canonical, private Git source for the AI workflows defined with Ross Gates. It is designed to:

- audit recent business AI work every night;
- organize conversations and durable knowledge;
- improve reusable skills from explicit feedback;
- create a Notion morning operating brief;
- process end-of-day sales learning;
- keep business logic separate from service-specific writes; and
- make the same approved skill files available to Codex on macOS and Hermes on Ubuntu.

## Start here

1. Read [`START_HERE.md`](START_HERE.md).
2. Follow [`INSTALLATION_GUIDE.md`](INSTALLATION_GUIDE.md).
3. Create a **private** GitHub repository from the Mac.
4. Install a machine-specific deploy key and auto-sync on each computer.
5. Install local skills into `~/.agents/skills`.
6. Configure Hermes and its scheduled jobs on Ubuntu.
7. Upload the packaged skill ZIP files to ChatGPT web.
8. Configure connectors one at a time and test in read-only or draft mode.

## Important limitation

Git automatically synchronizes the repository between the Mac and Ubuntu machines. It does **not** automatically update Personal Skills already uploaded to ChatGPT web. The repository builds upload-ready ZIP files, but you must upload a new ZIP in ChatGPT when you choose to promote a new version. This is deliberate: web skill promotion remains an approval boundary.

## Repository map

```text
skills/                    Portable Agent Skills
config/                    Shared non-secret policy and IDs
schemas/                   Service-neutral JSON schemas
scripts/                   Installers, validators, sync, safety, packaging
adapters/                  Connector contracts and implementation guidance
hermes/                    Hermes configuration and scheduled-job prompts
chatgpt/                   ChatGPT web installation and project instructions
codex/                     Codex configuration and usage guidance
tests/                     Cross-skill tests and fixtures
state/                     Sanitized local operating state templates
proposals/                 Approval-required production changes
decisions/                 Human approvals and architecture decisions
dist/                      Generated upload bundles; not committed by default
```

## Security baseline

Never place the following in this repository:

- client tax returns or raw tax documents;
- raw transcripts containing client-sensitive data;
- Social Security numbers, EINs, bank details, or credentials;
- OAuth tokens, API keys, session cookies, browser profiles, or private SSH keys;
- unredacted email exports; or
- local secret configuration files.

Run `./scripts/doctor.sh` and `./scripts/check_sensitive_content.py --all-files` before the first push.

## Invocation policy

All skills start explicit-only. Use `$skill-name` in Codex, `/skill-name` in Hermes, or `@skill-name` in ChatGPT. The nightly system may suggest a relevant skill, but it must not silently enable implicit invocation.
