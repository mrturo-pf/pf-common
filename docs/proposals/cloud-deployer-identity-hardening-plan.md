# Plan: Cloud deployer identity hardening

Date: 2026-10-11
Status: in progress
Level: L
Scope: Implement the approved separation of GitHub deployer, Cloud Run runtime, migration, backup, and human administration identities for the PF ecosystem.
Related artifacts: [brief](cloud-deployer-identity-hardening-brief.md) · [recommendation](cloud-deployer-identity-hardening-recommendation.md) · [investigation](../investigations/cloud-deployer-identity-hardening.md)
Approved: 2026-10-11 by owner (conversation)
Superseded-by: none

> This plan is the living implementation record. It does not authorize an
> unreviewed IAM mutation, key revocation, secret deletion, or production cutover.
> Each mutation slice requires a named owner, precondition evidence, rollback
> path, and explicit execution confirmation.

## 1. Gates and current state

- [x] Source workflow inventory completed.
- [x] GitHub secret-name inventory completed without reading values.
- [x] Owner-confirmed GCP project inventory completed read-only.
- [x] Runtime identities and current relevant project-level bindings recorded.
- [x] WIF absence confirmed in the target project.
- [x] Brief approved.
- [x] Recommendation approved.
- [x] Target project confirmed as `coreassistant-474022`.
- [x] GitHub environment inventory collected read-only.
- [x] Main branch protection checked; affected repositories currently report no branch protection.
- [x] GCP WIF pool/provider inventory collected read-only; none exists.
- [x] Candidate predefined GCP role permission baseline collected read-only.
- [x] Resource-level Artifact Registry and Secret Manager bindings validated through the approved Cloud Shell path; Artifact Registry has no resource bindings in the returned output.
- [x] Mutation owners assigned by responsibility; named identities remain an operational follow-up.
- [x] Rollback window approved as 7 days after production cutover; expiry timestamp remains pending the change window.
- [x] Organization/folder policy inventory completed through the approved Cloud Shell path; no organization/folder ancestor was returned.
- [x] Authorized GCP administrator confirms WIF/OIDC creation for the approved PF repositories.
- [x] WIF pool and provider created and verified.
- [x] Provider condition tightened to approved branch/environment claims and verified with Cloud Shell output.
- [x] Service-specific deployer accounts created with only `roles/iam.workloadIdentityUser` bindings.
- [x] Minimum deployer permission script prepared for review; no permissions have been granted yet.
- [x] Minimum service-specific deployer permissions granted and validated.
- [x] Shared workflow and caller WIF inputs prepared locally with temporary key fallback.
- [ ] WIF workflow changes committed, released through `pf-common@main`, and validated in controlled CI.
- [ ] Non-production or controlled validation path selected.
- [ ] WIF provider and deployer identities created.
- [ ] Service-specific deployer permissions validated.
- [ ] Runtime over-permission removed and service health validated.
- [ ] Production workflows cut over to WIF.
- [ ] Legacy keys disabled/revoked after rollback window.
- [ ] Cleanup and closure evidence recorded.

## 2. Implementation slices

### Slice 0 — Freeze evidence and assign owners

Preserve the sanitized investigation and approved recommendation. Confirm the
organization's WIF policy, GitHub environment protections, target project, and
named owners for IAM, GitHub workflow, service validation, and closure. Do not
mutate resources.

**Current evidence (2026-10-11):** the target project is confirmed; GitHub
reported `GCP` environments for `pf-rates` and `pf-payroll`, `GCP` for
`pf-common`, and `production` for `pf-db`, `pf-rates`, and `pf-payroll`. The
inspected `main` branches reported no branch protection. The target project has
no WIF pools/providers. Project-level org-policy inventory completed through the
approved Cloud Shell path and returned no policies; organization/folder policy
approval remains unconfirmed.

**Exit criteria:** owners, change window, rollback window, and WIF feasibility
are recorded in this plan.

### Slice 1 — Define final identity and resource matrix

Finalize the exact deployer identities, runtime identities, migration identity,
backup identity, and human operator path. Map each identity to exact resources:
Artifact Registry repository, Cloud Run service, service-account impersonation,
Secret Manager secrets, database, and any Cloud SQL dependency.

**Exit criteria:** matrix has no project-wide runtime deploy grants unless an
approved exception explains scope, owner, expiry, and compensating control.

### Slice 2 — Provision WIF and service deployers

Create or reconcile a global WIF pool/provider and service-specific deployer
identities. Restrict the provider to the exact GitHub organization, repository,
branch/environment, and workflow claims. Grant only the required workload
identity impersonation and resource-scoped deployment permissions.

**Preconditions:** Slice 0 and Slice 1 approved; mutation owner present; provider
configuration reviewed; rollback path tested.

**Exit criteria:** a controlled workflow authenticates without a private key and
cannot impersonate another service or run from an untrusted context.

### Slice 3 — Update shared and caller workflows

In `pf-common`, update the reusable authentication action and deployment workflow
to use explicit WIF inputs. Fail closed if deployer and runtime identities are
equal. In `pf-rates` and `pf-payroll`, add service-specific WIF configuration and
OIDC permissions. Preserve production approval and migration-before-traffic.

**Exit criteria:** pull requests cannot deploy production; approved main workflows
can publish and deploy using WIF; no workflow logs secrets or tokens.

### Slice 4 — Validate runtime least privilege

Remove deployment permissions from `pf-rates` and `pf-payroll` runtime identities
only after Slice 2 and Slice 3 pass. Reduce Secret Manager access to approved
secret-level grants and retain Cloud SQL access only where an actual runtime path
requires it. Validate cold start, health, required secret reads, outbound calls,
and normal application behavior.

**Exit criteria:** both services remain healthy while runtime identities cannot
publish images, administer Cloud Run, or impersonate unrelated identities.

### Slice 5 — Cut over production and retain rollback

Run the approved production workflows through the existing manual approval gates.
Validate image publication, Cloud Run revision identity, runtime secret access,
health, and rollback for each service. Keep legacy key access only for the
approved rollback window and record its deadline.

**Exit criteria:** production services run with WIF deployers and distinct runtime
identities; deployment and rollback evidence is attached to this plan.

### Slice 6 — Retire keys and close

After the rollback window and owner confirmation, disable/revoke old user-managed
keys, remove obsolete `GCP_SA_KEY` secrets, delete stale deployer grants, and
review WIF/IAM policy for drift. Record cleanup timestamps, actors, resource IDs,
and final validation without recording secret values.

**Exit criteria:** no obsolete key or runtime deploy grant remains without an
approved exception; register, index, workflow docs, and service AGENTS files are
synchronized.

## 3. Cross-repository file plan

| Repository | Expected changes |
| --- | --- |
| `pf-common` | WIF auth action, reusable deploy workflow, deployer/runtime guard, shared validation and docs |
| `pf-rates` | Caller workflow OIDC permissions/configuration, deployer secret removal, runtime validation |
| `pf-payroll` | Caller workflow OIDC permissions/configuration, deployer secret removal, runtime validation |
| `pf-db` | Migration identity documentation and validation; no schema migration expected |
| `pf-base` | Register/index updates, ecosystem coordination, final release evidence |

No repository may introduce private keys, WIF tokens, or secret values into Git.

## 4. Validation checklist

- [ ] `gcloud iam workload-identity-pools` and provider configuration reviewed;
- [ ] provider attribute condition tested with allowed and denied GitHub contexts;
- [ ] deployer identity cannot read secret payloads or administer unrelated services;
- [ ] runtime identity cannot deploy, publish, or impersonate unrelated accounts;
- [ ] `pf-rates` deployment and health validation pass;
- [ ] `pf-payroll` deployment and health validation pass;
- [ ] `pf-db` migration identity remains separate and migration ordering passes;
- [ ] production approval and rollback checks pass;
- [ ] old key inventory and revocation evidence recorded;
- [ ] no sensitive values appear in logs, artifacts, Git, or proposal docs.

## 5. Change log

| Date | Status | Change | Evidence |
| --- | --- | --- | --- |
| 2026-10-11 | in progress | Resource-level IAM inventory completed. Service-specific DB secret bindings, shared secret access, absent Artifact Registry resource bindings, and the `pf-rates` service-account self-binding recorded. | Sanitized Cloud Shell evidence received; no mutations |
| 2026-10-11 | in progress | Owner approved role-based responsibility assignments and a seven-day rollback window. Exact operator identities, WIF organization policy, and change timestamp remain pending. | Conversation approval; no mutations |
| 2026-10-11 | in progress | Organization/folder policy inventory completed. Only the project was returned as an ancestor; project, folder, and organization policy outputs were empty. | Sanitized Cloud Shell archive received; no mutations |
| 2026-10-11 | in progress | Owner authorized creation of the restricted PF GitHub OIDC pool/provider. Creation is staged behind an interactive idempotent Cloud Shell command; no service-account grants or workflow changes included. | Conversation authorization; local syntax and ignore checks passed |
| 2026-10-11 | in progress | WIF pool/provider created and verified as ACTIVE, restricted to the two PF repositories. Provider lacks branch/environment restriction; no service-account grants were created. | Sanitized Cloud Shell evidence received; security gate retained |
| 2026-10-11 | in progress | Provider condition verified with valid CEL literals: approved repositories, `refs/heads/main`, and `GCP` environment. Ready for impersonation bindings; no deployer permissions granted. | Cloud Shell verification; no further mutations |
| 2026-10-11 | in progress | Service-specific WIF deployer accounts created with repository-scoped `roles/iam.workloadIdentityUser` only. No deploy/runtime permissions or workflow changes. | Sanitized Cloud Shell archive received; no broader grants |
| 2026-10-11 | in progress | Prepared the minimum deployer-permission mutation entry point: `run.developer` project grant, repository-scoped Artifact Registry writer, and runtime-account-scoped Service Account User. | Local syntax and ignore checks passed; no mutation |
| 2026-10-11 | in progress | Minimum deployer grants applied: project `run.developer`, repository Artifact Registry writer, and matching runtime Service Account User. Legacy runtime grants unchanged. | Sanitized Cloud Shell archive received; no secret/runtime/key mutation |
| 2026-10-11 | in progress | Prepared shared auth/reusable workflow and rates/payroll callers for WIF with `id-token: write`; JSON-key fallback retained pending controlled CI validation. | Local workflow diff; no push or deployment |

## 6. Slice 0 decision request

The following decisions are required before Slice 0 can close. Proposed defaults are
recommendations only; they become active only after owner confirmation.

| Decision | Required value | Proposed default | Why it is required |
| --- | --- | --- | --- |
| IAM mutation owner | Named person or approved team | GCP IAM administrator — approved by owner | IAM mutations need one accountable executor and reviewer |
| GitHub workflow owner | Named person or approved team | `pf-common` maintainer — approved by owner | Owns reusable auth action and caller workflow changes |
| `pf-rates` validation owner | Named person or approved team | `pf-rates` owner — approved by owner | Confirms image publication, runtime identity, secrets, and health |
| `pf-payroll` validation owner | Named person or approved team | `pf-payroll` owner — approved by owner | Confirms image publication, runtime identity, secrets, and health |
| `pf-db` migration owner | Named person or approved team | `pf-db` owner — approved by owner | Confirms migration identity and migration-before-traffic ordering |
| WIF policy owner | Named person or approved team | GCP/org administrator — approved by owner | Confirms organization policy and VPC Service Controls access path |
| GitHub environment owner | Named person or approved team | GitHub repository administrator — approved by owner | Confirms `GCP`/`production` protection and OIDC claim boundaries |
| Rollback window | Exact duration and expiry timestamp | 7 days after production cutover — approved by owner; expiry timestamp pending cutover date | Determines when legacy keys can be disabled/revoked |
| Change window | Date/time and timezone | Next approved maintenance window — exact timestamp pending | Required for coordinated workflow/IAM changes |
| WIF access path | Approved terminal, Cloud Shell, or administrator evidence | Cloud Shell or approved VPC path — approved by owner | Direct access was blocked; approved Cloud Shell evidence is now available |
| Production approval | Explicit approver for each service | Existing `production` reviewers — approved by owner | Preserves the existing manual deployment gate |

### Slice 0 exit criteria

Slice 0 closes only when:

- every row above has a named owner or an explicitly approved team;
- the rollback window and change window are recorded;
- the WIF organization-policy result is available through an approved path;
- GitHub environment protection and OIDC claim boundaries are confirmed;
- the next mutation slice has a reviewed command set, preconditions, and rollback;
- no owner is inferred from repository ownership alone.

## 7. Release record

- Commits: pending
- Workflow runs: pending implementation
- IAM mutation owner: assigned by role; named operator pending
- GitHub environment owner: assigned by role; named administrator pending
- Rollback window: 7 days after cutover; expiry timestamp pending
- Key cleanup evidence: pending
