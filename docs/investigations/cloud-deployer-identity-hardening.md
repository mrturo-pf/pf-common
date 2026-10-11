# Investigation: Cloud deployer identity hardening

Date: 2026-10-11
Status: investigating
Level: L
Scope: Separation of CI deployer, Cloud Run runtime, migration, and administration identities; least-privilege deployment access; and Workload Identity Federation readiness.
Owner: `pf-common`
Related artifacts: [register](../../../docs/proposals/ECOSYSTEM-IMPROVEMENT-REGISTER.md) · [index](../../../docs/proposals/INDEX.md) · [source plan](../../../pf-payroll/docs/proposals/pf-svc-income-renaming-plan.md)
Superseded-by: none

## 1. Investigation question

How should the PF ecosystem separate GitHub Actions deployment access, Cloud Run
runtime identities, database migration access, and human administration access,
while replacing long-lived deployment keys with Workload Identity Federation where
supported?

This investigation is independent from the `pf-svc-income` rename. The rename may
consume the resulting deployment model, but it must not define or duplicate the
reusable identity policy.

## 2. Scope

### In scope

- GitHub Actions authentication and permissions for `pf-rates`, `pf-payroll`, and
  `pf-db`;
- deployer, runtime, migration, backup, and human operator identity separation;
- project-level versus resource-level IAM grants;
- Secret Manager access used by deployment and runtime;
- Workload Identity Federation feasibility and migration sequencing;
- rollback, validation, and key-revocation requirements.

### Out of scope

- Applying IAM mutations or deleting service-account keys;
- rotating or revoking credentials before consumer and rollback analysis;
- changing Cloud Run application behavior;
- redesigning database grants owned by `pf-db` (tracked separately by IMP-002/
  IMP-003); this investigation only covers how deployment identities obtain or
  inject those resources;
- production deployment approval.

## 3. Repositories and source-of-truth files inspected

- `modules/pf-common/.github/workflows/deploy-reusable.yml` — shared Cloud Run
  deployment workflow;
- `modules/pf-common/.github/workflows/gcp-setup-reusable.yml` — one-time GCP
  resource and IAM setup workflow;
- `modules/pf-common/.github/actions/gcp-auth/action.yml` — current GCP auth
  adapter;
- `modules/pf-rates/.github/workflows/deploy.yml` and `gcp-setup.yml` — rates
  caller and setup workflow;
- `modules/pf-payroll/.github/workflows/deploy.yml` and `gcp-setup.yml` — payroll
  caller and setup workflow;
- `modules/pf-db/.github/workflows/deploy.yml` — migration workflow and database
  credential path;
- root `AGENTS.md` and affected module `AGENTS.md` files — ownership, release,
  credential, and approval rules.

## 4. Evidence required before design approval

The following must be obtained as sanitized metadata only:

- GitHub repository/environment secret names and whether `GCP_SA_KEY` is still
  configured; never export secret values;
- workflow permissions, branch/environment protection, and deployment run history;
- GCP service accounts, key counts, key creation dates, disabled status, and
  workload identity pool/provider metadata;
- IAM bindings for deployer, runtime, migration, and operator identities at
  project, service, Artifact Registry, and Secret Manager scopes;
- Cloud Run service identity and deployer identity for `pf-rates` and `pf-payroll`;
- whether runtime identities can mutate deployment resources or IAM;
- whether `pf-db` migration access is represented by a GitHub secret, provider
  credential, or a separately managed identity;
- rollback and revocation readiness.

Never collect service-account private keys, connection strings, secret payloads,
access tokens, raw GitHub secret values, or production data.

## 5. Source evidence observed

### 5.1 Long-lived key authentication is the current documented path

Both service deployment workflows document `GCP_SA_KEY` and `GCP_PROJECT_ID` as
required GitHub Secrets. The shared `gcp-auth` action receives
`credentials_json: ${{ secrets.GCP_SA_KEY }}` and authenticates with the JSON key.
The setup workflow also requires the same secret and documents creating a service-
account JSON key for GitHub.

No inspected workflow declares `id-token: write`, references a workload identity
provider, or invokes `google-github-actions/auth` with Workload Identity Federation
inputs. This is source evidence only; live GitHub and GCP configuration still needs
confirmation.

### 5.2 Deployer and runtime identities are coupled by naming and setup

The setup documentation creates a service account named `pf-rates` or
`pf-payroll` and describes it as a GitHub Actions deployer. The reusable workflow
sets the Cloud Run runtime service account to the same service-name convention:

```text
<repo_name>@<project>.iam.gserviceaccount.com
```

The live inventory below confirms that separate service accounts also exist for
`github-actions-deployer`, `pf-rates`, and `pf-payroll`. Therefore the source
convention alone is not proof that CI and runtime currently share an identity.
The unresolved question is which account is behind each `GCP_SA_KEY` and why the
runtime accounts retain deployer permissions and user-managed keys.

### 5.3 Documented permissions are broader than a least-privilege deployer model

The service setup comments grant the service account these project-level roles:

- `roles/run.admin`;
- `roles/artifactregistry.writer`;
- `roles/cloudsql.client`;
- `roles/secretmanager.secretAccessor`;
- `roles/iam.serviceAccountUser`.

The same identity is documented for setup and deployment. The exact live bindings,
resource scopes, inherited roles, and runtime permissions remain unverified.
The target design should separate deployment administration from runtime access and
replace project-wide grants with resource-scoped permissions where feasible.

### 5.4 Database migration access is a separate identity boundary

The `pf-db` deployment workflow receives `DATABASE_URL` directly as a GitHub secret
for Alembic and seed operations. It does not use the Cloud Run deployer workflow.
The actual provider/database role behind that connection string, its rotation path,
and its relationship to the migration/operator identity must be verified without
reading the secret value.

### 5.5 Sanitized GitHub metadata received (2026-10-11)

Read-only GitHub metadata confirms:

- `pf-rates` and `pf-payroll` both currently expose an Actions secret named
  `GCP_SA_KEY`; secret values were not read;
- `pf-db` exposes `DATABASE_URL` for its migration workflow and does not expose
  `GCP_SA_KEY` in the repository-level secret listing;
- Actions are enabled for all three repositories, allowed actions are `all`, and
  SHA pinning is not required at the repository setting level;
- `GH_PAT` is also configured in all three repositories; its value and scopes
  were not inspected.

This confirms that the long-lived-key path is not merely historical documentation
for the two Cloud Run services. It does not prove key age, key count, IAM role
bindings, environment-level secrets, or WIF availability; those remain open live
GCP/GitHub checks.

### 5.6 Sanitized GCP metadata received (2026-10-11)

Read-only inventory was performed against the owner-confirmed project. The
following metadata was collected; no key material or secret payloads were read:

- project is `ACTIVE`;
- service accounts include `github-actions-deployer`, `pf-rates`, and
  `pf-payroll`;
- `pf-rates` and `pf-payroll` each have one user-managed key with an open-ended
  `validBeforeTime` (`9999-12-31T23:59:59Z`); key identifiers and timestamps were
  recorded only as local command output, not in versioned artifacts;
- Cloud Run services `pf-rates` and `pf-payroll` use their corresponding
  service-specific runtime accounts;
- no global Workload Identity Federation pools or providers exist;
- project-level bindings grant `roles/run.admin`,
  `roles/artifactregistry.writer`, and `roles/iam.serviceAccountUser` to both
  `pf-rates` and `pf-payroll`;
- project-level `roles/secretmanager.secretAccessor` is granted to both runtime
  accounts, and `roles/cloudsql.client` is granted to `pf-payroll`;
- `github-actions-deployer` has project-level `roles/artifactregistry.repoAdmin`
  and `roles/iam.serviceAccountUser`, but it was not observed in the runtime
  service identities;
- the live project therefore has separate runtime identities, but their grants
  are materially broader than runtime-only access and their long-lived keys
  remain an active hardening finding.

The inventory did not inspect secret values, GitHub secret values, private keys,
access tokens, or production rows. The mapping between each GitHub `GCP_SA_KEY`
secret and its service account still requires non-secret deployment metadata or
owner confirmation.

### 5.7 Cloud Shell evidence received (2026-10-11T181516Z)

The approved read-only Cloud Shell execution completed against the confirmed
project and produced sanitized metadata only:

- project state is `ACTIVE`;
- the project-level org-policy query returned an empty list;
- WIF pool inventory returned an empty list;
- WIF provider inventory was empty;
- relevant project IAM bindings match the local read-only inventory: runtime
  accounts have `roles/run.admin`, `roles/artifactregistry.writer`,
  `roles/iam.serviceAccountUser`, and `roles/secretmanager.secretAccessor`;
- `pf-payroll` also has `roles/cloudsql.client`;
- the deployer account has Artifact Registry repository administration and
  service-account user permissions;
- the execution summary reports no mutations, secrets, or raw business data.

This closes the VPC Service Controls access-path blocker for the project-level
inventory. An empty project-level org-policy result is not proof that an
organization or folder policy permits WIF; organization policy ownership and
approval remain required before creating a pool/provider.

### 5.8 Permission baseline and resource-scope check (2026-10-11)

The read-only role metadata confirms these predefined role sizes:

- `roles/run.developer`: 89 permissions;
- `roles/run.admin`: 97 permissions;
- `roles/artifactregistry.writer`: 44 permissions;
- `roles/artifactregistry.repoAdmin`: 53 permissions;
- `roles/secretmanager.viewer`: 11 permissions;
- `roles/secretmanager.secretAccessor`: 3 permissions;
- `roles/iam.serviceAccountUser`: 5 permissions;
- `roles/cloudsql.client`: 2 permissions.

This supports replacing `roles/run.admin` with the narrower Cloud Run Developer
candidate for deployers, subject to command-level validation. Artifact Registry
Writer and service-account impersonation remain candidates, but must be scoped to
the service repository and matching runtime identity. Resource-level IAM reads for
Artifact Registry repositories and Secret Manager secrets were blocked by VPC
Service Controls in the local session and require the approved Cloud Shell path or
an administrator-provided sanitized export.

### 5.9 Resource-level IAM evidence received (2026-10-11T182653Z)

The second approved Cloud Shell inventory confirms:

- Cloud Run services use the expected dedicated runtime identities;
- Artifact Registry repository policy output contains no resource-level bindings
  for `pf-rates` or `pf-payroll`, so current writer/admin access is inherited
  from project-level bindings;
- `PF_RATES_DATABASE_URL` is accessible only by `pf-rates` at the inspected
  Secret Manager resource policy;
- `PF_PAYROLL_DATABASE_URL` is accessible only by `pf-payroll`;
- the shared `PF_DATABASE_URL` remains accessible by both runtime identities;
- `PF_RATES_API_KEY` is accessible by both `pf-rates` and `pf-payroll`, while
  `PF_PAYROLL_API_KEY` is accessible only by `pf-payroll`;
- the `pf-rates` service account has a self-binding for
  `roles/iam.serviceAccountUser`; `pf-payroll` and the deployer account have no
  service-account-level bindings in this output;
- repository metadata was returned without secret payloads, and all execution
  errors were empty except the expected repository policy result represented as
  no resource-level bindings.

The target design should migrate consumers to service-specific database secrets
where compatible, document the approved cross-service use of `PF_RATES_API_KEY`,
remove unnecessary shared-secret access, and review the `pf-rates` self-binding.
These are recommendations for the approved implementation plan; no binding was
changed by the inventory.

### 5.10 Organization and folder policy evidence received (2026-10-11T184739Z)

The approved Cloud Shell archive completed the ancestor and policy inventory:

- project state is `ACTIVE`;
- the ancestor response contains only the project itself; no organization or
  folder ancestor was returned in the approved context;
- project-level org-policy inventory is empty;
- organization-level and folder-level policy outputs are empty because no such
  ancestor was returned for this project context;
- no mutation, secret value, private key, or business data was recorded.

This closes the technical policy-inventory access path for the confirmed project,
but it does not constitute organizational approval to create WIF resources. The
WIF decision still requires an authorized GCP administrator to confirm that the
project is allowed to use GitHub OIDC/WIF and that any external organization
policy is satisfied.

### 5.11 WIF pool and provider creation evidence received (2026-10-11T185755Z)

The approved creation step produced an `ACTIVE` global pool and an `ACTIVE`
GitHub OIDC provider restricted to the `mrturo-pf/pf-rates` and
`mrturo-pf/pf-payroll` repositories. No service-account grants, workflow changes,
key revocations, or secret changes were performed.

The provider maps subject, repository, repository owner, ref, and environment,
but its current attribute condition restricts only the organization and repository
names. It does not yet restrict the branch or GitHub environment. Therefore the
provider must not receive `roles/iam.workloadIdentityUser` bindings until the
condition is tightened to the approved production deployment context and tested
with allowed and denied tokens.

### 5.12 WIF provider condition verification received (2026-10-11)

Cloud Shell verification confirms the provider condition contains valid CEL string
literals and restricts federation to:

- repository owner `mrturo-pf`;
- repositories `mrturo-pf/pf-rates` and `mrturo-pf/pf-payroll`;
- ref `refs/heads/main`;
- GitHub environment `GCP`.

The provider is ready for service-account impersonation bindings. No deployer
permissions, runtime permission changes, workflow changes, or key revocations
have been performed.

### 5.13 WIF deployer identity evidence received (2026-10-11T191107Z)

The approved Cloud Shell execution created two service-specific deployer accounts:

- `pf-rates-deployer`;
- `pf-payroll-deployer`.

Each account received only one binding:

```text
roles/iam.workloadIdentityUser
```

The principal is restricted to the matching GitHub repository, and the provider
condition is restricted to the approved organization, repositories, `main` ref,
and `GCP` environment. No deploy permissions, runtime permissions, workflow
changes, key revocations, or secret changes were performed.

This completes the WIF authentication-to-deployer identity boundary. The next
security gate is to grant and validate the minimum deployment permissions without
attaching runtime permissions or using runtime identities as deployers.

### 5.14 WIF deployer permission evidence received (2026-10-11T192419Z)

The approved Cloud Shell execution granted the new deployer identities:

- project-level `roles/run.developer` for `pf-rates-deployer` and
  `pf-payroll-deployer`;
- repository-level `roles/artifactregistry.writer` on the matching Artifact
  Registry repository;
- service-account-level `roles/iam.serviceAccountUser` on the matching runtime
  identity.

The before/after project policy confirms no Secret Manager, Cloud SQL, database,
key, or runtime identity mutation. Legacy project-level grants on the old runtime
accounts remain unchanged and are now the next least-privilege cleanup target.
The `pf-rates` runtime self-binding also remains unchanged pending its dedicated
validation.

### 5.15 WIF workflow migration prepared (2026-10-11)

The shared GCP auth action and reusable deployment workflow were updated locally
to accept explicit WIF provider and deployer inputs, while retaining JSON-key
fallback for the controlled migration window. The `pf-rates` and `pf-payroll`
caller workflows now request `id-token: write` and pass their service-specific
WIF provider and deployer identities.

This change is not yet released. It must pass workflow validation and a controlled
CI deployment before the temporary `GCP_SA_KEY` fallback is removed.

## 6. Facts, inferences, and assumptions



| Classification | Statement |
| --- | --- |
| Fact | Resource-level Secret Manager bindings exist for service-specific database secrets. |
| Fact | Shared `PF_DATABASE_URL` remains accessible by both runtime identities. |
| Fact | `PF_RATES_API_KEY` is shared by `pf-rates` and `pf-payroll` at resource level. |
| Fact | Artifact Registry resource-level bindings were not present in the inspected output. |
| Fact | The `pf-rates` runtime service account has a self-binding for `roles/iam.serviceAccountUser`. |
| Inference | Project-level Artifact Registry grants are the current deployment access path. |
| Inference | Shared database/API-key secret access should be reduced where service paths permit. |
| Assumption to verify | Each GitHub `GCP_SA_KEY` maps to the intended deployer account and no environment-level secret overrides it. |
| Assumption to verify | No external organization policy constrains or replaces the observed project-level bindings. |

## 7. Risks and compatibility questions

- Removing a key before WIF or a replacement deployer is validated can block releases.
- Splitting runtime and deployer identities can expose missing `iam.serviceAccountUser`
  or Secret Manager grants that are currently hidden by broad access.
- Resource-scoped IAM differs between Cloud Run, Artifact Registry, Secret Manager,
  and the database provider; one project-level role cannot be copied blindly.
- `pf-payroll` deploys with access to `PF_RATES_API_KEY`, while `pf-rates` has its
  own service-specific secrets; the target must preserve only approved cross-service
  secret consumption.
- Any change must preserve the manual production approval gate and migration-before-
  traffic ordering.

## 8. Decisions required

- [x] Confirm the current live service accounts, key inventory, and IAM bindings
      for the owner-confirmed project; GitHub secret-to-account mapping remains open.
- [ ] Confirm whether GitHub Actions OIDC/WIF can be enabled for the repositories.
- [ ] Choose one deployer identity model: shared tightly scoped deployer or one
      deployer per service, with explicit trade-offs and blast-radius analysis.
- [x] Confirm separate Cloud Run runtime identities for each service.
- [ ] Define the migration identity and its relationship to `pf-db` and Neon/Cloud
      database credentials.
- [ ] Define resource-scoped deployer grants and runtime grants.
- [ ] Define WIF rollout, rollback, key revocation, and validation gates.
- [ ] Assign owners for IAM mutations, GitHub environment changes, and cleanup.

## 9. Conclusion

Proceed with IMP-005 as an active Level L investigation. The versioned workflows
show a documented long-lived JSON-key path, coupled service naming for CI/runtime
identities, and broad project-level role guidance. These findings justify the
security priority but do not authorize IAM mutation or credential revocation.
The next gate is to confirm GitHub-to-service-account mapping and organization
WIF policy, then draft an approved recommendation for resource-scoped grants,
key retirement, and staged rollout.
