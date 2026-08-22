# Team Rollout

The repository is structured for future sales teammates, but version 1.0.0 assumes Ross is the only approver and administrator.

## Before adding teammates

- Move the repository into the company GitHub organization if it is not already there.
- Protect `main` and require pull requests.
- Add CODEOWNERS for `skills/workspace-operator`, `adapters/`, `config/approval-policy.yaml`, `SECURITY_AND_DATA_HANDLING.md`, and `.github/workflows/`.
- Replace write-enabled deploy keys with a GitHub App or managed authentication if the organization needs finer-grained control.
- Define Product, Engineering, Security, Pricing, Legal, and CPA knowledge owners.
- Create environment-specific connector scopes and service accounts.
- Create sanitized onboarding fixtures; never train new employees with real client tax data in Git.

## Role model

| Role | May read | May propose | May approve | May administer connectors |
|---|---:|---:|---:|---:|
| Sales user | Skills and approved knowledge | Feedback and low-risk improvements | No | No |
| Skill maintainer | All sanitized repository content | Skill/test/config changes | Low-risk only if delegated | No |
| Business owner | All | All | Business rules and claims | No |
| Security/admin | All | Security and access changes | Security/access changes | Yes |

## Collision prevention

- One change branch per proposal.
- Every skill has semantic version, changelog, and decision log.
- New skill names must pass the catalog uniqueness validator.
- Cross-skill behavior belongs in shared references/config rather than copied instructions.
- Merge conflicts in judgment-bearing files require human resolution.
