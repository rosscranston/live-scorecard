# Verification results

Verified on the Hermes Mac on **2026-08-22** after copying into this migration folder.

## Passed

- Bundle guardrail scan: no credential/private-key/database filename, known secret token pattern, or GitHub-bound file over 95 MB was found.
- Raw private state is ignored by Git. Estimated compressed size before encryption: 56,657,920 bytes, below GitHub's 100 MB single-file limit.
- Live Call Scorecard: 98 tests passed, 1 on-device Apple Intelligence evaluation intentionally skipped.
- Private Call Notepad: 16 tests passed.
- Tax Terms: 16 tests passed.
- AI Operating System: repository validation passed for 13 skills and 34 JSON files; 14 unit tests passed; its own sensitive-content scan passed across 230 files.
- DreamBig workbook and board deck: ZIP/package integrity checks passed.
- All three copied Mac app `Info.plist` files passed `plutil` validation.
- Restore/encryption/verification shell scripts passed `zsh -n` syntax validation.

## Expected limitations

- Private Call Notepad has an ad-hoc signature that verifies locally.
- Live Scorecard and Tax Terms retain a local Apple development-team signature whose certificate chain is not trusted in this sandbox. Their copied bundles are intact, but rebuilding from source on the M5 Mac is recommended.
- The encrypted private-state archive is not yet present because its passphrase should be entered by the user locally and never sent through a Codex task. Run `./scripts/encrypt-private-state.sh` before the first Git commit.

