# Primary-owner GitHub write boundary

- Date: 2026-08-16
- Approved by: Ross Gates
- Source excerpts: "For now set a rule to not alter any repos where I am not the primary owner" and correction: "everything should be done under the rosscranston github account"
- Source: Current interactive setup task
- Before: GitHub writes were limited by action risk but not repository ownership.
- After: GitHub repositories whose owner login is not `rosscranston` are read-only. The initially supplied `rossclo` login is explicitly rejected by the regression test.
- Reason: Prevent accidental changes to repositories owned by employers, collaborators, organizations, or third parties.
- Confidence: High
- Risk: Low; this narrows permissions.
- Duplicate check: No existing repository-ownership boundary found.
- Verification: Repository tests assert the configured owner and prohibited non-owner write mode.
- Rollback: Remove the ownership entries and test only after Ross explicitly changes the rule.
- Idempotency key: `github-write-scope-primary-owner-rosscranston-2026-08-16`
