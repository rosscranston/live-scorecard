# Decision Register

## DR-001 — Canonical repository

- **Date:** 2026-08-15
- **Decision:** Use one private GitHub repository as the canonical source for skills, rules, tests, decisions, and sanitized state.
- **Reason:** The same approved files must be available on the Mac and Ubuntu/Hermes computer.
- **Constraint:** Secrets and client tax documents are excluded.

## DR-002 — Sync model

- **Date:** 2026-08-15
- **Decision:** Use machine-specific repository deploy keys and a conservative five-minute auto-sync loop.
- **Reason:** Unattended Hermes workflows need pull/push access without storing a broad personal token.
- **Constraint:** No force push or automatic conflict resolution.

## DR-003 — ChatGPT web promotion

- **Date:** 2026-08-15
- **Decision:** Build upload-ready skill ZIPs from Git, but require manual ChatGPT web upload for each promoted version.
- **Reason:** Personal Skills are not a live Git checkout and promotion should remain an approval boundary.

## DR-004 — Explicit invocation

- **Date:** 2026-08-15
- **Decision:** All skills begin explicit-only and may suggest relevant skills.
- **Reason:** Ross wants to learn the catalog and build trust before implicit invocation.

## DR-005 — Production behavior changes

- **Date:** 2026-08-15
- **Decision:** Nightly jobs may update tests and documentation automatically but only propose changes to production rules and permissions.
- **Reason:** The operating system should learn overnight without silently changing business judgment.

## DR-006 — Local client data

- **Date:** 2026-08-15
- **Decision:** Raw client tax documents stay in approved cloud systems and are prohibited from the Git repository and local AI OS state.

## DR-007 — GPU scope

- **Date:** 2026-08-15
- **Decision:** Do not install or change NVIDIA/CUDA/local model software as part of this release.
- **Reason:** The RTX 4070 is optional and unrelated to the shared skill/Git/Hermes operating layer unless a separate local-model architecture is approved.
