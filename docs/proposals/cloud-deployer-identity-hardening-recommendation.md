# Recommendation: Cloud deployer identity hardening

Date: 2026-10-11
Status: approved
Level: L
Scope: Reusable identity separation and least-privilege deployment model for PF GitHub Actions, Cloud Run, database migrations, and administration.
Related artifacts: [brief](cloud-deployer-identity-hardening-brief.md) · [investigation](../investigations/cloud-deployer-identity-hardening.md) · [register](../../../docs/proposals/ECOSYSTEM-IMPROVEMENT-REGISTER.md)
Approved: 2026-10-11 by owner (conversation)
Superseded-by: none

## 1. Executive recommendation

Adopt a two-layer identity model for each deployable service:

1. a GitHub Actions deployer identity authenticated through GitHub OIDC and
   Google Workload Identity Federation (WIF);
2. a separate Cloud Run runtime identity with only the permissions required while
   the service is running.

Keep database migration, backup/restore, and human administration identities
separate from both layers. Create one WIF trust path and deployer identity per
service unless an owner approves a shared deployer with equivalent resource-level
isolation. Do not use runtime service accounts as CI deployers.

The current `pf-rates` and `pf-payroll` runtime accounts are separate, which is a
useful base. Their project-level deployment roles and user-managed keys should be
removed only after WIF deployers, runtime grants, rollback, and consumer checks
are validated. The existing `github-actions-deployer` account must be classified
as legacy, retained temporarily, or replaced; do not assume its GitHub secret
mapping without owner evidence.

## 2. Rejected alternatives

### Keep long-lived JSON keys as the permanent model

Rejected. Keys are bearer credentials with open-ended validity in the observed
runtime accounts, are difficult to attribute and rotate, and create a larger
blast radius if copied from GitHub secrets.

### Let runtime accounts deploy themselves

Rejected. A runtime compromise would gain image publication, Cloud Run mutation,
service-account impersonation, and potentially broader secret access.

### Use one project-wide deployer for all services

Rejected as the default. It couples release blast radius and makes service-level
attribution and revocation harder. It is acceptable only as a temporary fallback
with resource-scoped grants, explicit owner approval, and a sunset date.

### Grant Secret Manager accessor to deployers

Rejected when deployment only references secret names. The Cloud Run runtime
identity should read payloads; the deployer should receive only the metadata or
resource permissions required to configure the reference.

### Create a new always-on broker or deployment service

Rejected. GitHub OIDC/WIF and existing GCP IAM capabilities provide the cheaper
viable path without new runtime infrastructure.

## 3. Target identity topology

| Identity | Consumer | Purpose | Authentication | Runtime use |
| --- | --- | --- | --- | --- |
| `pf-rates-deployer` | GitHub Actions `pf-rates` | Build/publish image and update `pf-rates` Cloud Run service | GitHub OIDC → WIF | Never attached to Cloud Run |
| `pf-payroll-deployer` | GitHub Actions `pf-payroll` | Build/publish image and update `pf-payroll` Cloud Run service | GitHub OIDC → WIF | Never attached to Cloud Run |
| `pf-rates` runtime | Cloud Run `pf-rates` | Read runtime secrets and call approved dependencies | Cloud Run service identity | Only `pf-rates` |
| `pf-payroll` runtime | Cloud Run `pf-payroll` | Read runtime secrets and call approved dependencies | Cloud Run service identity | Only `pf-payroll` |
| `pf-db-migrator` | `pf-db` migration job/workflow | Apply Alembic migrations and approved seeds | Dedicated controlled identity | Never used by application runtime |
| `pf-db-backup` | Backup/restore operator | Approved backup and restore operations | Dedicated controlled identity | Never used by application runtime |
| human operator | Approved administrators | Emergency/IAM administration | Human MFA and approved elevation | Never injected into services |

The exact account names are design labels, not authorization to create resources.
Existing accounts must be reconciled with this topology before mutation.

## 4. Permission matrix

The following is the minimum target to validate against actual commands and
provider permissions. Prefer repository-, service-, secret-, and service-account-
level bindings over project-wide grants.

| Identity | Target permissions | Explicit exclusions |
| --- | --- | --- |
| service deployer | Artifact Registry writer on its repository; Cloud Run deploy/update permission on its service; `iam.serviceAccountUser` only on its matching runtime identity; read-only metadata needed to validate deployment | Secret payload access; Cloud SQL client; database access; IAM policy administration; service runtime attachment to another service |
| `pf-rates` runtime | Secret accessor only for approved rates secrets; required outbound/runtime permissions; Cloud SQL client only if a verified Cloud SQL path exists | Cloud Run admin; Artifact Registry writer/admin; service-account impersonation; database migration; payroll secrets |
| `pf-payroll` runtime | Secret accessor only for approved payroll and explicitly required `pf-rates` API key; required outbound/runtime permissions; Cloud SQL client only if verified | Cloud Run admin; Artifact Registry writer/admin; service-account impersonation; database migration; rates database ownership |
| `pf-db` migrator | Exact database migration credential and any narrowly required deployment/job permissions | Cloud Run runtime; service API secrets; GitHub deployer role; broad project IAM |
| `pf-db` backup | Approved backup/read/restore permissions and catalog access | Application writes; CI deployment; runtime secret access; broad IAM |
| human operator | Break-glass/admin permissions through approved MFA/elevation and audit | Permanent application injection; unattended GitHub secret use |

The existing project bindings show `roles/run.admin`,
`roles/artifactregistry.writer`, and `roles/iam.serviceAccountUser` on both
runtime accounts. Those bindings are target-removal candidates, subject to a
command-backed permission audit and staged deploy validation. The existing
`roles/secretmanager.secretAccessor` grants remain runtime concerns, but must be
reduced to secret-level bindings where feasible.

## 5. WIF design

Create a global WIF pool and GitHub OIDC provider only after confirming the
organization permits it. Restrict the provider attribute condition to the exact
GitHub organization, repository, branch or environment, and workflow context
required by each deployer. Do not trust arbitrary repository claims.

Recommended trust boundaries:

- `pf-rates` deployer may impersonate only the `pf-rates-deployer` account;
- `pf-payroll` deployer may impersonate only the `pf-payroll-deployer` account;
- production deployment remains gated by the existing GitHub environment approval;
- pull requests must not receive production deployment impersonation;
- tokens are short-lived and no private key is stored in GitHub.

The provider configuration, attribute mapping, audience, repository condition,
branch/environment condition, and service-account `roles/iam.workloadIdentityUser`
binding must be reviewed as one atomic security contract.

## 6. Workflow and repository changes

The reusable `pf-common` workflow should:

- replace `credentials_json` authentication with WIF inputs;
- request only the GitHub OIDC permission required for deployment;
- accept an explicit deployer identity/provider configuration rather than infer
  one from `repo_name`;
- keep the runtime service account explicit and separate;
- avoid reading secret payloads during deploy preflight;
- fail closed when deployer and runtime identities are equal;
- preserve manual production approval and migration-before-traffic ordering.

The `pf-rates` and `pf-payroll` callers should provide service-specific WIF
configuration and remove `GCP_SA_KEY` only after the replacement path passes
staged validation. `pf-db` should document its migration identity separately and
must not inherit a Cloud Run deployer identity.

## 7. Rollout and rollback

1. Confirm organization policy, target project, GitHub environment protection,
   and owner for IAM changes.
2. Create WIF resources and service-specific deployer identities without removing
   current access.
3. Grant only the minimum resource-scoped deployer permissions.
4. Update a non-production or controlled validation workflow to use WIF.
5. Validate image publication, Cloud Run update, runtime secret access, health,
   and rollback for each service.
6. Switch production workflows to WIF while preserving the approval gate.
7. Remove deploy permissions from runtime accounts and verify service operation.
8. Revoke or disable old user-managed keys only after successful cutover and an
   owner-approved rollback window.
9. Remove legacy `GCP_SA_KEY` secrets and stale deployer grants with evidence.

Rollback before key retirement: restore the previous workflow authentication and
known-good deployer binding, without reattaching deploy permissions to runtime
accounts. Rollback after key retirement requires the WIF path or a newly approved,
short-lived emergency credential; do not restore an untracked private key.

## 8. Validation matrix

| Area | Validation | Acceptance |
| --- | --- | --- |
| WIF | Provider condition and impersonation test from each allowed repository/environment | Allowed workflow authenticates; PR/untrusted context does not |
| Deployer | Dry-run or controlled deploy with resource-level grants | Image publish and Cloud Run update work without runtime admin grants |
| Runtime | Cloud Run revision identity and Secret Manager access test | Service starts and reads only approved secrets |
| Separation | Compare deployer and runtime identities in workflow and Cloud Run metadata | They are distinct for every service |
| Database | Migration workflow identity and database role audit | Migration identity is separate from runtime and deployer identities |
| Keys | Key inventory before/after cutover | Legacy keys are disabled/revoked only after owner-approved rollback window |
| Audit | IAM policy and GitHub environment metadata | Owner, scope, timestamps, and cleanup evidence recorded |

## 9. Cost and operational impact

- **Infrastructure:** no always-on infrastructure; WIF uses existing IAM and GitHub
  OIDC capabilities. Expected incremental infrastructure cost: zero.
- **Engineering/operations:** moderate one-time workflow/IAM migration effort,
  plus recurring review of provider conditions, grants, and key inventory.
- **Security operations:** lower key rotation and incident-response burden, with
  improved attribution and smaller blast radius.

The cheapest viable alternative is WIF using existing provider capabilities. A
permanent JSON-key model is cheaper only in initial engineering effort and is
rejected because of its higher credential and blast-radius risk.

## 10. Decision gate

Implementation requires explicit approval of:

- WIF enablement and GitHub trust conditions;
- service-specific deployer identities;
- runtime permission reductions;
- migration and backup identity boundaries;
- staged key retirement and rollback window;
- owners for IAM mutations, GitHub environment changes, and closure evidence.

Until those approvals exist, this recommendation authorizes no IAM mutation,
workflow authentication change, key revocation, secret deletion, or deployment.
